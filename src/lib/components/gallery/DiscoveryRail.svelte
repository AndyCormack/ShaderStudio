<script lang="ts">
	import SquaresFour from 'phosphor-svelte/lib/SquaresFour';
	import Heart from 'phosphor-svelte/lib/Heart';
	import ClockCounterClockwise from 'phosphor-svelte/lib/ClockCounterClockwise';
	import Tag from 'phosphor-svelte/lib/Tag';
	import type { GalleryState, RailSection } from '$lib/gallery/gallery-state.svelte';
	import { cn } from '$lib/utils';

	let { gallery }: { gallery: GalleryState } = $props();

	const sections: { id: RailSection; label: string; icon: typeof SquaresFour }[] = [
		{ id: 'gallery', label: 'Gallery', icon: SquaresFour },
		{ id: 'favorites', label: 'Favorites', icon: Heart },
		{ id: 'recent', label: 'Recent', icon: ClockCounterClockwise }
	];

	const counts = $derived({
		gallery: gallery.entries.length,
		favorites: gallery.entries.filter((e) => gallery.favorites.includes(e.slug)).length,
		recent: gallery.entries.filter((e) => gallery.recents.includes(e.slug)).length
	});

	function itemClass(active: boolean): string {
		return cn(
			'flex h-9 w-full items-center gap-2.5 rounded-lg px-2.5 text-[0.8125rem] font-[550] transition-colors duration-150',
			active
				? 'bg-selected text-foreground'
				: 'text-muted-foreground hover:bg-surface hover:text-foreground'
		);
	}
</script>

<nav class="hidden w-52 shrink-0 flex-col border-r border-border md:flex" aria-label="Discovery">
	<div class="flex h-14 items-center px-4">
		<a href="/" class="text-[0.9375rem] font-semibold tracking-tight">
			shader<span class="text-signature" aria-hidden="true">·</span>studio
		</a>
	</div>

	<div class="flex flex-col gap-0.5 px-2">
		{#each sections as { id, label, icon: Icon } (id)}
			<button
				type="button"
				class={itemClass(gallery.section === id && gallery.tag === null)}
				aria-current={gallery.section === id && gallery.tag === null ? 'true' : undefined}
				onclick={() => {
					gallery.section = id;
					gallery.tag = null;
				}}
			>
				<Icon size={16} weight={gallery.section === id && gallery.tag === null ? 'fill' : 'regular'} />
				<span>{label}</span>
				<span class="ms-auto text-xs tabular-nums text-muted-foreground">{counts[id]}</span>
			</button>
		{/each}
	</div>

	{#if gallery.tagCounts.length > 0}
		<div class="mt-5 flex min-h-0 flex-1 flex-col">
			<p class="px-4.5 pb-1.5 text-xs font-[550] text-muted-foreground">Tags</p>
			<div class="flex flex-col gap-0.5 overflow-y-auto px-2">
				{#each gallery.tagCounts as [tag, count] (tag)}
					<button
						type="button"
						class={itemClass(gallery.tag === tag)}
						aria-current={gallery.tag === tag ? 'true' : undefined}
						onclick={() => {
							gallery.tag = gallery.tag === tag ? null : tag;
							gallery.section = 'gallery';
						}}
					>
						<Tag size={16} weight={gallery.tag === tag ? 'fill' : 'regular'} />
						<span class="truncate font-mono text-[0.8125rem]">{tag}</span>
						<span class="ms-auto text-xs tabular-nums text-muted-foreground">{count}</span>
					</button>
				{/each}
			</div>
		</div>
	{/if}
</nav>
