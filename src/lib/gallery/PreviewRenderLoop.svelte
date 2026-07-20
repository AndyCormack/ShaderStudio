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
		const dpr = renderer.getPixelRatio();
		const canvasW = Math.round(canvasRect.width * dpr);
		const canvasH = Math.round(canvasRect.height * dpr);

		// Sweep scenes whose tiles unmounted (filtering, section switches).
		for (const slug of [...cache.keys()]) {
			if (!registry.has(slug)) {
				cache.get(slug)!.dispose();
				cache.delete(slug);
			}
		}

		renderer.setScissorTest(false);
		renderer.setViewport(0, 0, canvasW, canvasH);
		renderer.setClearColor(0x000000, 0);
		renderer.clear();
		renderer.setScissorTest(true);

		for (const [slug, el] of registry.tiles()) {
			const rect = el.getBoundingClientRect();
			// Cull tiles scrolled out of the atlas viewport.
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

			let ps = cache.get(slug);
			if (!ps) {
				ps = createPreviewScene(entry);
				cache.set(slug, ps);
			}

			const width = Math.round(rect.width * dpr);
			const height = Math.round(rect.height * dpr);
			if (width === 0 || height === 0) continue;
			const x = Math.round((rect.left - canvasRect.left) * dpr);
			const y = Math.round((canvasRect.bottom - rect.bottom) * dpr);

			// Clip the scissor to the canvas so partially scrolled tiles crop
			// instead of drawing outside the atlas viewport; the viewport keeps
			// the full tile size so the image isn't squashed.
			const sx = Math.max(x, 0);
			const sy = Math.max(y, 0);
			const sw = Math.min(x + width, canvasW) - sx;
			const sh = Math.min(y + height, canvasH) - sy;
			if (sw <= 0 || sh <= 0) continue;

			ps.tick(delta);
			ps.setSize(width, height);

			renderer.setViewport(x, y, width, height);
			renderer.setScissor(sx, sy, sw, sh);
			renderer.setClearColor(viewportBlack, 1);
			renderer.clear();
			renderer.render(ps.scene, ps.camera);
		}
		renderer.setScissorTest(false);
	});
</script>
