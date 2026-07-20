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

		for (const [key, { slug, el, frozen }] of registry.targets()) {
			const rect = el.getBoundingClientRect();
			// Cull viewports scrolled out of the atlas area.
			if (
				rect.bottom <= canvasRect.top ||
				rect.top >= canvasRect.bottom ||
				rect.right <= canvasRect.left ||
				rect.left >= canvasRect.right
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

			const width = rect.width;
			const height = rect.height;
			if (width < 1 || height < 1) continue;
			const x = rect.left - canvasRect.left;
			const y = canvasRect.bottom - rect.bottom;

			// Clip the scissor to the canvas so partially scrolled tiles crop
			// instead of drawing outside the atlas viewport; the viewport keeps
			// the full tile size so the image isn't squashed.
			const sx = Math.max(x, 0);
			const sy = Math.max(y, 0);
			const sw = Math.min(x + width, canvasRect.width) - sx;
			const sh = Math.min(y + height, canvasRect.height) - sy;
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
