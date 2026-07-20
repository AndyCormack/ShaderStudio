/**
 * Maps viewport keys to a shader slug + the DOM element the preview should
 * fill. The shared-context renderer (D7) walks this every frame to scissor
 * each live preview into place. Keys are arbitrary (atlas tiles use the
 * slug; the detail strip uses a fixed key whose slug changes with the
 * selection). Deliberately non-reactive — the render loop polls it.
 */
export interface PreviewTarget {
	slug: string;
	el: HTMLElement;
	/** Frozen targets render a static frame — time never advances. */
	frozen: boolean;
}

export class PreviewRegistry {
	#targets = new Map<string, PreviewTarget>();

	register(key: string, slug: string, el: HTMLElement, opts?: { frozen?: boolean }): () => void {
		const target = { slug, el, frozen: opts?.frozen ?? false };
		this.#targets.set(key, target);
		return () => {
			if (this.#targets.get(key) === target) this.#targets.delete(key);
		};
	}

	has(key: string): boolean {
		return this.#targets.has(key);
	}

	targets(): IterableIterator<[string, PreviewTarget]> {
		return this.#targets.entries();
	}
}
