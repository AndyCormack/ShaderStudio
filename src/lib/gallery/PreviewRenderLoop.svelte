<script lang="ts">
	import { useTask, useThrelte } from '@threlte/core';
	import { Mesh, OrthographicCamera, PlaneGeometry, Scene, ShaderMaterial, Vector2 } from 'three';
	import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
	import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
	import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
	import { OutputPass } from 'three/addons/postprocessing/OutputPass.js';
	import { getEntry } from '$lib/shaders/catalog';
	import { cssColor } from '$lib/harness/theme';
	import { applyBloom } from '$lib/harness/bloom';
	import { createPreviewScene, type PreviewScene } from './preview-scenes';
	import { resolveBloom } from '$lib/shaders/types';
	import type { PreviewRegistry } from './preview-registry';

	let { registry }: { registry: PreviewRegistry } = $props();

	const { renderer, autoRender } = useThrelte();

	// Mesh tiles sit on the raised Shadow Plum surface, matching the studio (D22).
	const surround = cssColor('--surface');

	const cache = new Map<string, PreviewScene>();

	// Per-tile bloom rigs (D21 — post-fx now renders in previews too). Keyed per
	// tile so differently-sized tiles don't thrash render-target reallocation.
	type BloomRig = { composer: EffectComposer; renderPass: RenderPass; bloomPass: UnrealBloomPass };
	const bloomRigs = new Map<string, BloomRig>();

	// One shared quad blits a rig's composited (bloomed) texture into a tile's
	// scissored region of the shared canvas — the composite itself renders
	// offscreen unscissored, so bloom blur isn't clipped to the tile rect.
	const blitCamera = new OrthographicCamera(-1, 1, 1, -1, 0, 1);
	// RAW passthrough copy. The composer ends in an OutputPass, so its readBuffer
	// already holds display-ready (tone-mapped + sRGB-encoded) pixels — exactly
	// what the studio writes to screen. Blitting through a colour-managed material
	// (MeshBasicMaterial) would sRGB-encode a SECOND time, lifting the dark
	// surround to grey; this shader copies the texel verbatim instead.
	const blitMaterial = new ShaderMaterial({
		uniforms: { map: { value: null } },
		vertexShader: 'varying vec2 vUv; void main() { vUv = uv; gl_Position = vec4(position.xy, 0.0, 1.0); }',
		fragmentShader: 'uniform sampler2D map; varying vec2 vUv; void main() { gl_FragColor = texture2D(map, vUv); }',
		depthTest: false,
		depthWrite: false
	});
	const blitScene = new Scene();
	blitScene.add(new Mesh(new PlaneGeometry(2, 2), blitMaterial));

	function bloomRigFor(key: string, ps: PreviewScene): BloomRig {
		let rig = bloomRigs.get(key);
		if (!rig) {
			const composer = new EffectComposer(renderer);
			composer.renderToScreen = false; // result stays in readBuffer for the blit
			const renderPass = new RenderPass(ps.scene, ps.camera);
			const bloomPass = new UnrealBloomPass(new Vector2(1, 1), 0.7, 0.6, 0.55);
			composer.addPass(renderPass);
			composer.addPass(bloomPass);
			// Final tone-map + sRGB conversion, matching the studio's pipeline so the
			// readBuffer holds display-ready pixels for a raw blit (see blitMaterial).
			composer.addPass(new OutputPass());
			rig = { composer, renderPass, bloomPass };
			bloomRigs.set(key, rig);
		}
		rig.renderPass.scene = ps.scene;
		rig.renderPass.camera = ps.camera;
		return rig;
	}

	function disposeRig(key: string) {
		const rig = bloomRigs.get(key);
		if (rig) {
			rig.composer.dispose();
			bloomRigs.delete(key);
		}
	}

	$effect(() => {
		const before = autoRender.current;
		autoRender.set(false);
		renderer.autoClear = false;
		return () => {
			autoRender.set(before);
			for (const ps of cache.values()) ps.dispose();
			cache.clear();
			for (const key of [...bloomRigs.keys()]) disposeRig(key);
			blitMaterial.dispose();
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
				disposeRig(key);
			}
		}

		renderer.setScissorTest(false);
		renderer.setViewport(0, 0, canvasRect.width, canvasRect.height);
		renderer.setClearColor(0x000000, 0);
		renderer.setRenderTarget(null);
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
				disposeRig(key);
				ps = undefined;
			}
			if (!ps) {
				ps = createPreviewScene(entry);
				// Match the studio: render the surround as the scene background so the
				// composer's RenderPass writes it colour-managed (a raw setClearColor
				// into the linear render target would get sRGB-encoded twice — once on
				// clear, once by OutputPass — lifting the dark plum to grey).
				ps.scene.background = surround;
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

			const bloomCfg = entry.meta.postfx?.bloom;
			if (bloomCfg) {
				// Composite the tile (scene + bloom) offscreen, unscissored…
				const rig = bloomRigFor(key, ps);
				const dh = Math.round(height * dpr);
				rig.composer.setSize(Math.round(width * dpr), dh);
				applyBloom(rig.bloomPass, resolveBloom(bloomCfg), dh);
				renderer.setScissorTest(false);
				renderer.setRenderTarget(null);
				renderer.setClearColor(surround, 1);
				rig.composer.render(delta);

				// …then blit the result into the tile's scissored region.
				blitMaterial.uniforms.map.value = rig.composer.readBuffer.texture;
				renderer.setRenderTarget(null);
				renderer.setViewport(x, y, width, height);
				renderer.setScissor(sx, sy, sw, sh);
				renderer.setScissorTest(true);
				renderer.render(blitScene, blitCamera);
			} else {
				renderer.setViewport(x, y, width, height);
				renderer.setScissor(sx, sy, sw, sh);
				renderer.setScissorTest(true);
				renderer.setClearColor(surround, 1);
				renderer.clear();
				renderer.render(ps.scene, ps.camera);
			}
		}
		renderer.setScissorTest(false);
	});
</script>
