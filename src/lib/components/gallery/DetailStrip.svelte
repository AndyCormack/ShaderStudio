<script lang="ts">
	import Heart from 'phosphor-svelte/lib/Heart';
	import ArrowUpRight from 'phosphor-svelte/lib/ArrowUpRight';
	import { Badge } from '$lib/components/ui/badge';
	import { Button } from '$lib/components/ui/button';
	import type { GalleryState } from '$lib/gallery/gallery-state.svelte';

	let { gallery }: { gallery: GalleryState } = $props();

	const entry = $derived(gallery.selected);
	const favorite = $derived(entry !== undefined && gallery.isFavorite(entry.slug));
</script>

{#if entry}
	<div
		class="flex shrink-0 flex-col gap-3 border-t border-border bg-surface px-4 py-3 sm:flex-row sm:items-center sm:gap-4"
	>
		<div class="min-w-0">
			<div class="flex items-baseline gap-3">
				<h2 class="truncate text-[1.25rem] font-[650] leading-tight tracking-[-0.015em]">
					{entry.meta.name}
				</h2>
				<span class="hidden shrink-0 font-mono text-[0.8125rem] text-muted-foreground sm:inline">
					shaders/{entry.slug}/
				</span>
			</div>
			<div class="mt-1.5 flex flex-wrap items-center gap-1.5">
				<Badge variant="secondary">{entry.meta.harness} harness</Badge>
				{#if entry.meta.primitive}
					<Badge variant="secondary">{entry.meta.primitive}</Badge>
				{/if}
				{#if entry.meta.scene}
					<Badge variant="secondary">custom scene</Badge>
				{/if}
				{#if entry.vertex}
					<Badge variant="secondary">custom vertex</Badge>
				{/if}
				{#each entry.meta.tags ?? [] as tag (tag)}
					<button
						type="button"
						class="flex h-6 items-center rounded-lg bg-surface-raised px-2 font-mono text-xs text-muted-foreground transition-colors duration-150 hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
						onclick={() => {
							gallery.tag = tag;
							gallery.section = 'gallery';
						}}
					>
						{tag}
					</button>
				{/each}
			</div>
		</div>

		<div class="flex shrink-0 items-center gap-2 sm:ms-auto">
			<Button
				variant="secondary"
				size="icon"
				class="size-9"
				aria-label={favorite ? 'Remove from favorites' : 'Add to favorites'}
				aria-pressed={favorite}
				onclick={() => gallery.toggleFavorite(entry.slug)}
			>
				<Heart size={16} weight={favorite ? 'fill' : 'regular'} class={favorite ? 'text-primary' : ''} />
			</Button>
			<Button class="h-9 gap-1.5" onclick={() => gallery.open(entry)}>
				Open shader
				<ArrowUpRight size={15} aria-hidden="true" />
			</Button>
		</div>
	</div>
{/if}
