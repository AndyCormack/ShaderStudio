<script lang="ts">
	import { useTask, useThrelte } from '@threlte/core';
	import { Color } from 'three';
	import { getEntry } from '$lib/shaders/catalog';
	import { createPreviewScene, type PreviewScene } from './preview-scenes';
	import type { PreviewRegistry } from './preview-registry';

	let { registry }: { registry: PreviewRegistry } = $props();

	const { renderer, autoRender } = useThrelte();

	// Tiles sit on Viewport Black so preview color isn't contaminated by the
	// brand surface (DESIGN.md).
	const viewportBlack = new Color('#020202');

	const cache = new Map<string, PreviewScene>();

	$effect(() => {
		const before = autoRender.current;
		autoRender.set(false);
		renderer.autoClear = false;
		return () => {
			autoRender.set(before);
			for (const ps of cache.values()) ps.dispose();
			cache.clear();
		};
	});

	useTask((delta) => {
		const canvasRect = renderer.domElement.getBoundingClientRect();
		if (canvasRect.width === 0 || canvasRect.height === 0) return;
		// NB: setViewport/setScissor take CSS pixels — Three multiplies by the
		// pixel ratio internally. Only u_resolution wants device pixels.
		const dpr = renderer.getPixelRatio();

		// Sweep scenes whose viewports unmounted (filtering, section switches).
		for (const key of [...cache.keys()]) {
			if (!registry.has(key)) {
				cache.get(key)!.dispose();
				cache.delete(key);
			}
		}

		renderer.setScissorTest(false);
		renderer.setViewport(0, 0, canvasRect.width, canvasRect.height);
		renderer.setClearColor(0x000000, 0);
		renderer.clear();
		renderer.setScissorTest(true);

		// The canvas spans the whole window (the detail strip is outside the
		// atlas scroll area), so canvas bounds no longer cull scrolled tiles.
		// Each viewport clips to its nearest [data-preview-clip] ancestor —
		// the atlas scroll container — falling back to the canvas itself.
		const clipRects = new Map<Element, DOMRect>();

		for (const [key, { slug, el, frozen }] of registry.targets()) {
			const rect = el.getBoundingClientRect();
			const clipEl = el.closest('[data-preview-clip]');
			let clipRect = canvasRect;
			if (clipEl) {
				let r = clipRects.get(clipEl);
				if (!r) {
					r = clipEl.getBoundingClientRect();
					clipRects.set(clipEl, r);
				}
				clipRect = r;
			}
			// Cull viewports scrolled out of their clip area.
			if (
				rect.bottom <= clipRect.top ||
				rect.top >= clipRect.bottom ||
				rect.right <= clipRect.left ||
				rect.left >= clipRect.right
			) {
				continue;
			}
			const entry = getEntry(slug);
			if (!entry) continue;

			// A key can switch shaders in place (the detail-strip thumb).
			let ps = cache.get(key);
			if (ps && ps.entry.slug !== slug) {
				ps.dispose();
				ps = undefined;
			}
			if (!ps) {
				ps = createPreviewScene(entry);
				if (frozen) {
					// Freeze at the frame the live tile is showing right now, so
					// the thumbnail matches what was on screen at selection.
					ps.setTime(cache.get(slug)?.getTime() ?? 2);
				}
				cache.set(key, ps);
			}

			// Round to whole CSS pixels, then inset by a few: fractional rects get
			// floored/scaled inside Three at non-integer pixel ratios, and the
			// square scissor corners otherwise poke past the card's ~8px rounded
			// border (the shared canvas is a page-root layer, so the card's own
			// overflow-clip can't contain it). The inset keeps the square inside
			// the corner arc; the edge feather hides the sacrificed pixels.
			const inset = 4;
			const width = Math.round(rect.width) - inset * 2;
			const height = Math.round(rect.height) - inset * 2;
			if (width < 1 || height < 1) continue;
			const x = Math.round(rect.left - canvasRect.left) + inset;
			const y = Math.round(canvasRect.bottom - rect.bottom) + inset;

			// Clip the scissor to the clip area (in canvas space) so partially
			// scrolled tiles crop at the atlas edge instead of drawing over the
			// command band or detail strip; the viewport keeps the full tile
			// size so the image isn't squashed.
			const cx0 = Math.max(Math.round(clipRect.left - canvasRect.left), 0);
			const cx1 = Math.min(Math.round(clipRect.right - canvasRect.left), canvasRect.width);
			const cy0 = Math.max(Math.round(canvasRect.bottom - clipRect.bottom), 0);
			const cy1 = Math.min(Math.round(canvasRect.bottom - clipRect.top), canvasRect.height);
			const sx = Math.max(x, cx0);
			const sy = Math.max(y, cy0);
			const sw = Math.min(x + width, cx1) - sx;
			const sh = Math.min(y + height, cy1) - sy;
			if (sw <= 0 || sh <= 0) continue;

			if (!frozen) ps.tick(delta);
			ps.setSize(Math.round(width * dpr), Math.round(height * dpr));

			renderer.setViewport(x, y, width, height);
			renderer.setScissor(sx, sy, sw, sh);
			renderer.setClearColor(viewportBlack, 1);
			renderer.clear();
			renderer.render(ps.scene, ps.camera);
		}
		renderer.setScissorTest(false);
	});
</script>
