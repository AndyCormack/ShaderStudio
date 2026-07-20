/**
 * Maps shader slugs to their tile's preview element. The shared-context
 * renderer (D7) walks this every frame to scissor each live preview into
 * place; tiles register on mount via an attachment and unregister on unmount.
 * Deliberately non-reactive — the render loop polls it imperatively.
 */
export class PreviewRegistry {
	#tiles = new Map<string, HTMLElement>();

	register(slug: string, el: HTMLElement): () => void {
		this.#tiles.set(slug, el);
		return () => {
			if (this.#tiles.get(slug) === el) this.#tiles.delete(slug);
		};
	}

	has(slug: string): boolean {
		return this.#tiles.has(slug);
	}

	tiles(): IterableIterator<[string, HTMLElement]> {
		return this.#tiles.entries();
	}
}
