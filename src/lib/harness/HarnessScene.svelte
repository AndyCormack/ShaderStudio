<script lang="ts">
	import { T, useTask, useThrelte } from '@threlte/core';
	import { OrbitControls } from '@threlte/extras';
	import type { RawShaderMaterial } from 'three';
	import type { MeshPrimitive, ShaderEntry } from '$lib/shaders/types';
	import type { SceneComponent } from './scenes';

	let {
		entry,
		material,
		primitive,
		sceneComponent
	}: {
		entry: ShaderEntry;
		material: RawShaderMaterial;
		primitive: MeshPrimitive;
		sceneComponent?: SceneComponent;
	} = $props();

	const { size } = useThrelte();

	useTask((delta) => {
		material.uniforms.u_time.value += delta;
		material.uniforms.u_resolution.value.set(size.current.width, size.current.height);
	});

	const CustomScene = $derived(sceneComponent);
</script>

{#if entry.meta.harness === 'quad'}
	<T.Mesh frustumCulled={false} {material}>
		<T.PlaneGeometry args={[2, 2]} />
	</T.Mesh>
{:else}
	<T.PerspectiveCamera makeDefault position={[0, 1.2, 3.2]} oncreate={(c) => c.lookAt(0, 0, 0)}>
		<OrbitControls enableDamping />
	</T.PerspectiveCamera>
	{#if CustomScene}
		<CustomScene {material} />
	{:else if primitive === 'sphere'}
		<T.Mesh {material}><T.SphereGeometry args={[1, 96, 96]} /></T.Mesh>
	{:else if primitive === 'box'}
		<T.Mesh {material}><T.BoxGeometry args={[1.4, 1.4, 1.4, 32, 32, 32]} /></T.Mesh>
	{:else if primitive === 'torus'}
		<T.Mesh {material}><T.TorusGeometry args={[1, 0.4, 64, 128]} /></T.Mesh>
	{:else if primitive === 'torusknot'}
		<T.Mesh {material}><T.TorusKnotGeometry args={[0.9, 0.3, 192, 48]} /></T.Mesh>
	{:else if primitive === 'plane'}
		<T.Mesh {material}><T.PlaneGeometry args={[2.4, 2.4, 64, 64]} /></T.Mesh>
	{/if}
{/if}
