import {
	BoxGeometry,
	Mesh,
	PerspectiveCamera,
	PlaneGeometry,
	Scene,
	SphereGeometry,
	TorusGeometry,
	TorusKnotGeometry,
	type BufferGeometry
} from 'three';
import { createEntryMaterial } from '$lib/harness/material';
import type { MeshPrimitive, ShaderEntry } from '$lib/shaders/types';

/**
 * A per-tile scene for the shared-context preview renderer (D7). Built
 * imperatively (not as Threlte components) because a dozen previews render
 * as scissored viewports inside one Canvas, not as mounted scene graphs.
 * Entries with a custom Scene.svelte (D8) fall back to their default
 * primitive here — the full scene runs in the studio.
 */
export interface PreviewScene {
	scene: Scene;
	camera: PerspectiveCamera;
	entry: ShaderEntry;
	tick(delta: number): void;
	/** Keeps u_resolution and the camera in step with the tile's pixel size. */
	setSize(width: number, height: number): void;
	getTime(): number;
	setTime(value: number): void;
	dispose(): void;
}

/** Preview-density geometry — cheaper than the studio's, same silhouettes. */
function previewGeometry(primitive: MeshPrimitive): BufferGeometry {
	switch (primitive) {
		case 'box':
			return new BoxGeometry(1.4, 1.4, 1.4, 16, 16, 16);
		case 'torus':
			return new TorusGeometry(1, 0.4, 32, 64);
		case 'torusknot':
			return new TorusKnotGeometry(0.9, 0.3, 96, 24);
		case 'plane':
			return new PlaneGeometry(2.4, 2.4, 32, 32);
		case 'sphere':
			return new SphereGeometry(1, 48, 48);
	}
}

export function createPreviewScene(entry: ShaderEntry): PreviewScene {
	const scene = new Scene();
	const camera = new PerspectiveCamera(50, 1, 0.1, 100);
	const material = createEntryMaterial(entry);

	let geometry: BufferGeometry;
	let mesh: Mesh;
	if (entry.meta.harness === 'quad') {
		// The quad vertex shader emits clip-space positions directly; the
		// camera is only a render-call formality.
		geometry = new PlaneGeometry(2, 2);
		mesh = new Mesh(geometry, material);
		mesh.frustumCulled = false;
	} else {
		geometry = previewGeometry(entry.meta.primitive ?? 'sphere');
		mesh = new Mesh(geometry, material);
		camera.position.set(0, 1.2, 3.2);
		camera.lookAt(0, 0, 0);
	}
	scene.add(mesh);

	return {
		scene,
		camera,
		entry,
		tick(delta: number) {
			material.uniforms.u_time.value += delta;
			if (entry.meta.harness === 'mesh') {
				mesh.rotation.y += delta * 0.25;
			}
		},
		setSize(width: number, height: number) {
			material.uniforms.u_resolution.value.set(width, height);
			const aspect = width / height;
			if (camera.aspect !== aspect) {
				camera.aspect = aspect;
				camera.updateProjectionMatrix();
			}
		},
		getTime() {
			return material.uniforms.u_time.value as number;
		},
		setTime(value: number) {
			material.uniforms.u_time.value = value;
		},
		dispose() {
			geometry.dispose();
			material.dispose();
		}
	};
}
