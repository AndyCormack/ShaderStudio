declare module 'virtual:shader-stats' {
	/** Per-slug filesystem stats gathered by the shader-stats Vite plugin. */
	const stats: Record<string, { glslBytes: number; updatedAt: number }>;
	export default stats;
}
