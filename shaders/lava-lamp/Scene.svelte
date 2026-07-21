<script lang="ts">
	import { T, useTask } from '@threlte/core';
	import type { RawShaderMaterial } from 'three';

	let { material }: { material: RawShaderMaterial } = $props();

	let orbit = $state(0);
	useTask((delta) => {
		orbit += delta;
	});
</script>

<!-- Core blob plus orbiting droplets, all sharing the entry's material -->
<T.Mesh {material}>
	<T.SphereGeometry args={[1, 96, 96]} />
</T.Mesh>

{#each [0, 1, 2] as i (i)}
	<T.Mesh
		{material}
		position={[
			Math.cos(orbit * (0.6 + i * 0.25) + i * 2.1) * 1.9,
			Math.sin(orbit * (0.8 + i * 0.2) + i) * 0.6,
			Math.sin(orbit * (0.6 + i * 0.25) + i * 2.1) * 1.9
		]}
	>
		<T.SphereGeometry args={[0.18 + i * 0.05, 32, 32]} />
	</T.Mesh>
{/each}
