import { browser } from '$app/environment';
import { goto } from '$app/navigation';
import { shaderEntries } from '$lib/shaders/catalog';
import type { ShaderEntry } from '$lib/shaders/types';

const FAVORITES_KEY = 'shader-studio:favorites';
const RECENTS_KEY = 'shader-studio:recents';
const RECENTS_CAP = 12;

export type RailSection = 'gallery' | 'favorites' | 'recent';
export type HarnessFilter = 'all' | 'quad' | 'mesh';
export type SortOrder = 'recent' | 'name';

function readStringArray(key: string): string[] {
	if (!browser) return [];
	try {
		const parsed = JSON.parse(localStorage.getItem(key) ?? '[]');
		return Array.isArray(parsed) ? parsed.filter((v) => typeof v === 'string') : [];
	} catch {
		return [];
	}
}

function writeStringArray(key: string, value: string[]) {
	if (!browser) return;
	localStorage.setItem(key, JSON.stringify(value));
}

/** Records a studio visit without needing a GalleryState instance (used by the studio route). */
export function recordRecent(slug: string) {
	const recents = readStringArray(RECENTS_KEY).filter((s) => s !== slug);
	recents.unshift(slug);
	writeStringArray(RECENTS_KEY, recents.slice(0, RECENTS_CAP));
}

/**
 * Client-side discovery state for the gallery: search, filters, selection,
 * and the localStorage-backed favorites/recents (D13 — collections and
 * presets are deferred to the backlog).
 */
export class GalleryState {
	search = $state('');
	section = $state<RailSection>('gallery');
	tag = $state<string | null>(null);
	harness = $state<HarnessFilter>('all');
	sort = $state<SortOrder>('recent');
	paletteOpen = $state(false);

	favorites = $state<string[]>(readStringArray(FAVORITES_KEY));
	recents = $state<string[]>(readStringArray(RECENTS_KEY));

	#selectedSlug = $state<string | null>(null);

	/** All entries, in catalog (name) order. */
	readonly entries = shaderEntries;

	readonly tagCounts = $derived.by(() => {
		const counts = new Map<string, number>();
		for (const entry of this.entries) {
			for (const tag of entry.meta.tags ?? []) {
				counts.set(tag, (counts.get(tag) ?? 0) + 1);
			}
		}
		return [...counts.entries()].sort((a, b) => a[0].localeCompare(b[0]));
	});

	/** Entries surviving section + tag + harness + search, in atlas order. */
	readonly visible = $derived.by(() => {
		const query = this.search.trim().toLowerCase();
		let list = this.entries.filter((entry) => {
			if (this.section === 'favorites' && !this.favorites.includes(entry.slug)) return false;
			if (this.section === 'recent' && !this.recents.includes(entry.slug)) return false;
			if (this.tag !== null && !(entry.meta.tags ?? []).includes(this.tag)) return false;
			if (this.harness !== 'all' && entry.meta.harness !== this.harness) return false;
			if (query !== '') {
				const haystack = [entry.meta.name, entry.slug, ...(entry.meta.tags ?? [])]
					.join(' ')
					.toLowerCase();
				if (!haystack.includes(query)) return false;
			}
			return true;
		});
		if (this.section === 'recent' || (this.sort === 'recent' && this.recents.length > 0)) {
			const rank = new Map(this.recents.map((slug, i) => [slug, i]));
			list = [...list].sort(
				(a, b) => (rank.get(a.slug) ?? Infinity) - (rank.get(b.slug) ?? Infinity)
			);
		}
		return list;
	});

	/** The selected entry, kept valid as filters change (falls back to the featured tile). */
	readonly selected = $derived.by(() => {
		const explicit = this.visible.find((e) => e.slug === this.#selectedSlug);
		return explicit ?? this.visible[0];
	});

	select(slug: string) {
		this.#selectedSlug = slug;
	}

	/** Moves selection by delta within the visible atlas order (keyboard navigation). */
	moveSelection(delta: number) {
		if (this.visible.length === 0) return;
		const current = this.selected ? this.visible.indexOf(this.selected) : 0;
		const next = Math.min(Math.max(current + delta, 0), this.visible.length - 1);
		this.#selectedSlug = this.visible[next].slug;
	}

	isFavorite(slug: string): boolean {
		return this.favorites.includes(slug);
	}

	toggleFavorite(slug: string) {
		this.favorites = this.favorites.includes(slug)
			? this.favorites.filter((s) => s !== slug)
			: [...this.favorites, slug];
		writeStringArray(FAVORITES_KEY, this.favorites);
	}

	open(entry: ShaderEntry) {
		recordRecent(entry.slug);
		this.recents = readStringArray(RECENTS_KEY);
		goto(`/shader/${entry.slug}`);
	}

	clearFilters() {
		this.search = '';
		this.tag = null;
		this.harness = 'all';
		this.section = 'gallery';
	}
}
