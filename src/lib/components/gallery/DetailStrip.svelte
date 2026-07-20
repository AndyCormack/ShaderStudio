<script lang="ts">
	import Star from 'phosphor-svelte/lib/Star';
	import DotsThree from 'phosphor-svelte/lib/DotsThree';
	import LinkSimple from 'phosphor-svelte/lib/LinkSimple';
	import Code from 'phosphor-svelte/lib/Code';
	import { Badge } from '$lib/components/ui/badge';
	import { Button } from '$lib/components/ui/button';
	import * as DropdownMenu from '$lib/components/ui/dropdown-menu';
	import { formatAgo, formatSize } from '$lib/gallery/format';
	import type { GalleryState } from '$lib/gallery/gallery-state.svelte';
	import type { PreviewRegistry } from '$lib/gallery/preview-registry';

	let { gallery, registry }: { gallery: GalleryState; registry: PreviewRegistry } = $props();

	const entry = $derived(gallery.selected);
	const favorite = $derived(entry !== undefined && gallery.isFavorite(entry.slug));
	const fragmentPath = $derived(entry ? `shaders/${entry.slug}/fragment.glsl` : '');

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
					['Renderer', entry.glslVersion],
					['Size', formatSize(entry.glslBytes)],
					['Updated', formatAgo(entry.updatedAt, 'long')]
				] as [string, string][])
			: []
	);

	/** How the entry renders in the harness — the honest stand-in for the mockup's scene-usage list. */
	const usage = $derived.by(() => {
		if (!entry) return { lead: '', rest: [] as string[] };
		const uniforms = entry.meta.uniforms?.length ?? 0;
		return {
			lead:
				entry.meta.harness === 'mesh'
					? `Mesh harness · ${entry.meta.primitive ?? 'sphere'}`
					: 'Fullscreen quad harness',
			rest: [
				entry.meta.scene ? 'Custom Threlte scene' : 'Built-in scene',
				...(entry.vertex ? ['Custom vertex shader'] : []),
				uniforms > 0 ? `${uniforms} tunable uniform${uniforms === 1 ? '' : 's'}` : 'No tunable uniforms'
			]
		};
	});
</script>

{#if entry}
	<div
		class="flex shrink-0 flex-col gap-4 border-t border-border bg-surface px-4 py-3.5 lg:flex-row lg:items-center lg:gap-7"
	>
		<div class="flex min-w-0 items-center gap-3.5 lg:w-72 lg:shrink-0">
			<div
				class="relative size-16 shrink-0 overflow-hidden rounded-lg border border-primary/60"
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
				<p class="mt-1 truncate font-mono text-xs text-muted-foreground">{fragmentPath}</p>
			</div>
		</div>

		{#if description}
			<div class="hidden min-w-0 max-w-[36ch] lg:block">
				<p class="mb-1 text-[0.6875rem] font-[550] text-muted-foreground">Description</p>
				<p class="line-clamp-3 text-xs leading-relaxed text-muted-foreground">{description}</p>
			</div>
		{/if}

		<div class="hidden shrink-0 xl:block">
			<p class="mb-1 text-[0.6875rem] font-[550] text-muted-foreground">Details</p>
			<dl class="grid grid-cols-[auto_auto] gap-x-4 gap-y-0.5 text-xs tabular-nums">
				{#each details as [term, value] (term)}
					<dt class="text-muted-foreground">{term}</dt>
					<dd class={term === 'Harness' ? 'capitalize text-foreground' : 'text-foreground'}>
						{value}
					</dd>
				{/each}
			</dl>
		</div>

		{#if entry.meta.tags?.length}
			<div class="hidden max-w-56 xl:block">
				<p class="mb-1.5 text-[0.6875rem] font-[550] text-muted-foreground">Tags</p>
				<div class="flex flex-wrap gap-1">
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
			</div>
		{/if}

		<div class="hidden shrink-0 2xl:block">
			<p class="mb-1 text-[0.6875rem] font-[550] text-muted-foreground">Usage</p>
			<p class="text-xs text-foreground">{usage.lead}</p>
			{#each usage.rest as line (line)}
				<p class="mt-0.5 text-xs text-muted-foreground">{line}</p>
			{/each}
		</div>

		<div class="flex shrink-0 items-center gap-2 lg:ms-auto">
			<Button class="h-10 px-5" onclick={() => gallery.open(entry)}>Open shader</Button>
			<DropdownMenu.Root>
				<DropdownMenu.Trigger>
					{#snippet child({ props })}
						<Button
							{...props}
							variant="secondary"
							class="size-10 p-0"
							aria-label={`More actions for ${entry.meta.name}`}
						>
							<DotsThree size={20} weight="bold" />
						</Button>
					{/snippet}
				</DropdownMenu.Trigger>
				<DropdownMenu.Content align="end" class="w-48">
					<DropdownMenu.Item onclick={() => navigator.clipboard.writeText(fragmentPath)}>
						<LinkSimple size={15} aria-hidden="true" />
						Copy path
					</DropdownMenu.Item>
					<DropdownMenu.Item onclick={() => navigator.clipboard.writeText(entry.fragment)}>
						<Code size={15} aria-hidden="true" />
						Copy GLSL source
					</DropdownMenu.Item>
				</DropdownMenu.Content>
			</DropdownMenu.Root>
		</div>
	</div>
{/if}
