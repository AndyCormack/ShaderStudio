<script lang="ts">
	import Star from 'phosphor-svelte/lib/Star';
	import ArrowUpRight from 'phosphor-svelte/lib/ArrowUpRight';
	import { Badge } from '$lib/components/ui/badge';
	import { Button } from '$lib/components/ui/button';
	import type { GalleryState } from '$lib/gallery/gallery-state.svelte';
	import type { PreviewRegistry } from '$lib/gallery/preview-registry';

	let { gallery, registry }: { gallery: GalleryState; registry: PreviewRegistry } = $props();

	const entry = $derived(gallery.selected);
	const favorite = $derived(entry !== undefined && gallery.isFavorite(entry.slug));

	/** First real paragraph of the entry's notes.md, if it ships one. */
	const description = $derived.by(() => {
		if (!entry?.notes) return undefined;
		for (const block of entry.notes.split(/\r?\n\r?\n/)) {
			const text = block
				.split(/\r?\n/)
				.filter((line) => !line.trimStart().startsWith('#'))
				.join(' ')
				.trim();
			if (text) return text;
		}
		return undefined;
	});

	const details = $derived(
		entry
			? ([
					['Harness', entry.meta.harness],
					entry.meta.harness === 'mesh'
						? ['Primitive', entry.meta.primitive ?? 'sphere']
						: undefined,
					['Vertex', entry.vertex ? 'custom' : 'default'],
					['Scene', entry.meta.scene ? 'custom' : 'built-in'],
					['Uniforms', String(entry.meta.uniforms?.length ?? 0)]
				].filter(Boolean) as [string, string][])
			: []
	);
</script>

{#if entry}
	<div
		class="flex shrink-0 flex-col gap-4 border-t border-border bg-surface px-4 py-3.5 lg:flex-row lg:items-center lg:gap-6"
	>
		<div class="flex min-w-0 items-center gap-3.5 lg:w-96 lg:shrink-0">
			<div
				class="relative size-16 shrink-0 overflow-hidden rounded-lg border border-border"
				{@attach (el) => registry.register('detail', entry.slug, el, { frozen: true })}
			>
				<div
					class="pointer-events-none absolute inset-0 z-30 rounded-[5px] shadow-[0_0_0_24px_var(--color-surface)]"
				></div>
			</div>
			<div class="min-w-0">
				<div class="flex items-center gap-2">
					<h2 class="truncate text-[1.0625rem] font-[650] leading-tight tracking-[-0.01em]">
						{entry.meta.name}
					</h2>
					<Badge
						variant="outline"
						class="shrink-0 text-[0.6875rem] capitalize text-muted-foreground"
					>
						{entry.meta.harness}
					</Badge>
					<button
						type="button"
						class={favorite
							? 'text-favorite'
							: 'text-muted-foreground transition-colors duration-150 hover:text-foreground'}
						aria-label={favorite ? 'Remove from favorites' : 'Add to favorites'}
						aria-pressed={favorite}
						onclick={() => gallery.toggleFavorite(entry.slug)}
					>
						<Star size={16} weight={favorite ? 'fill' : 'regular'} />
					</button>
				</div>
				<p class="mt-0.5 truncate font-mono text-xs text-muted-foreground">shaders/{entry.slug}/</p>
				{#if entry.meta.tags?.length}
					<div class="mt-1.5 flex flex-wrap gap-1">
						{#each entry.meta.tags as tag (tag)}
							<button
								type="button"
								class="rounded-[4px] bg-surface-raised px-1.5 py-0.5 font-mono text-[0.6875rem] text-muted-foreground transition-colors duration-150 hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
								onclick={() => {
									gallery.tag = tag;
									gallery.section = 'gallery';
								}}
							>
								{tag}
							</button>
						{/each}
					</div>
				{/if}
			</div>
		</div>

		{#if description}
			<div class="hidden min-w-0 max-w-[42ch] lg:block">
				<p class="mb-1 text-[0.6875rem] font-[550] text-muted-foreground">Description</p>
				<p class="line-clamp-3 text-xs leading-relaxed text-muted-foreground">{description}</p>
			</div>
		{/if}

		<div class="hidden xl:block">
			<p class="mb-1 text-[0.6875rem] font-[550] text-muted-foreground">Details</p>
			<dl class="grid grid-cols-[auto_auto] gap-x-4 gap-y-0.5 text-xs">
				{#each details as [term, value] (term)}
					<dt class="text-muted-foreground">{term}</dt>
					<dd class="capitalize text-foreground">{value}</dd>
				{/each}
			</dl>
		</div>

		<div class="flex shrink-0 items-center gap-2 lg:ms-auto">
			<Button class="h-10 gap-1.5 px-5" onclick={() => gallery.open(entry)}>
				Open shader
				<ArrowUpRight size={15} aria-hidden="true" />
			</Button>
		</div>
	</div>
{/if}
