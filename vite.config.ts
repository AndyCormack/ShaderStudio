import { readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';
import adapter from '@sveltejs/adapter-auto';
import { sveltekit } from '@sveltejs/kit/vite';
import tailwindcss from '@tailwindcss/vite';
import { defineConfig, type Plugin } from 'vite';
import glsl from 'vite-plugin-glsl';

// Filesystem stats the browser can't derive from glob imports: per-entry GLSL
// source size and the newest mtime across the entry's folder. Feeds the tile
// meta row and detail-strip Details (D19).
function shaderStats(): Plugin {
	const virtualId = 'virtual:shader-stats';
	const resolvedId = '\0' + virtualId;
	return {
		name: 'shader-stats',
		resolveId(id) {
			return id === virtualId ? resolvedId : undefined;
		},
		load(id) {
			if (id !== resolvedId) return undefined;
			const root = join(process.cwd(), 'shaders');
			const stats: Record<string, { glslBytes: number; updatedAt: number }> = {};
			for (const slug of readdirSync(root)) {
				const dir = join(root, slug);
				if (!statSync(dir).isDirectory()) continue;
				let glslBytes = 0;
				let updatedAt = 0;
				for (const file of readdirSync(dir)) {
					const s = statSync(join(dir, file));
					if (!s.isFile()) continue;
					if (file.endsWith('.glsl')) glslBytes += s.size;
					updatedAt = Math.max(updatedAt, s.mtimeMs);
				}
				stats[slug] = { glslBytes, updatedAt: Math.round(updatedAt) };
			}
			return `export default ${JSON.stringify(stats)};`;
		},
		handleHotUpdate({ file, server }) {
			if (!file.includes('/shaders/')) return;
			const mod = server.moduleGraph.getModuleById(resolvedId);
			if (mod) server.moduleGraph.invalidateModule(mod);
		}
	};
}

export default defineConfig({
	// Crawl all app code at startup so deps are discovered and pre-bundled
	// before the first request, instead of on demand (which forces a
	// mid-session "optimized dependencies changed" reload). Covers future
	// deps too — no hand-maintained package list.
	optimizeDeps: {
		entries: ['src/**/*.{svelte,ts}', 'shaders/*/Scene.svelte']
	},
	server: {
		fs: {
			// shaders/ lives outside src/, and custom scenes are lazy-loaded
			// as real module URLs in dev — allow serving them.
			allow: ['shaders']
		}
	},
	plugins: [
		shaderStats(),
		tailwindcss(),
		glsl(),
		sveltekit({
			compilerOptions: {
				// Force runes mode for the project, except for libraries. Can be removed in svelte 6.
				runes: ({ filename }) =>
					filename.split(/[/\\]/).includes('node_modules') ? undefined : true
			},

			// adapter-auto only supports some environments, see https://svelte.dev/docs/kit/adapter-auto for a list.
			// If your environment is not supported, or you settled on a specific environment, switch out the adapter.
			// See https://svelte.dev/docs/kit/adapters for more information about adapters.
			adapter: adapter()
		})
	]
});
