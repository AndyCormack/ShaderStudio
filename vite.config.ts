import adapter from '@sveltejs/adapter-auto';
import { sveltekit } from '@sveltejs/kit/vite';
import tailwindcss from '@tailwindcss/vite';
import { defineConfig } from 'vite';
import glsl from 'vite-plugin-glsl';

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
