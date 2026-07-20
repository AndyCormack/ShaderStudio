<script lang="ts">
	import { T, useTask } from '@threlte/core';
	import { RawShaderMaterial } from 'three';
	import vertexShader from './vertex.glsl';
	import fragmentShader from './fragment.glsl';

	const material = new RawShaderMaterial({
		vertexShader,
		fragmentShader,
		uniforms: {
			u_time: { value: 0 }
		}
	});

	let rotationY = $state(0);

	useTask((delta) => {
		material.uniforms.u_time.value += delta;
		rotationY += delta * 0.5;
	});
</script>

<T.PerspectiveCamera
	makeDefault
	position={[0, 1.5, 4]}
	oncreate={(camera) => camera.lookAt(0, 0, 0)}
/>

<T.Mesh rotation.y={rotationY} {material}>
	<T.TorusKnotGeometry args={[1, 0.35, 128, 32]} />
</T.Mesh>
