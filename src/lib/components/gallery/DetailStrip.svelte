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
	<!-- Full-window band with a subtle top divider; the strip itself is a
	     raised rounded panel inset within it (the mockup's double container).
	     Panel bg/border sampled from the mockup: a dark plum panel with a
	     subtle top→bottom lift and a lighter purple edge. -->
	<div class="shrink-0 border-t border-[#221d2a] bg-[#181320] px-4 py-3.5">
		<div
			class="flex flex-col gap-4 rounded-panel border border-[#332738] bg-gradient-to-b from-[#211d2b] to-[#1b1725] px-5 py-4 lg:flex-row lg:items-start lg:gap-8"
		>
		<div class="flex min-w-0 items-center gap-4 lg:w-96 lg:shrink-0">
			<div
				class="relative size-20 shrink-0 overflow-hidden rounded-lg border border-primary/60"
				{@attach (el) => registry.register('detail', entry.slug, el, { frozen: true })}
			>
				<div
					class="pointer-events-none absolute inset-0 z-30 rounded-[7px] shadow-[0_0_0_24px_var(--color-surface)]"
				></div>
			</div>
			<div class="min-w-0">
				<div class="flex items-center gap-2.5">
					<h2 class="truncate text-[1.125rem] font-[650] leading-tight tracking-[-0.01em]">
						{entry.meta.name}
					</h2>
					<Badge
						variant="outline"
						class="shrink-0 text-[0.6875rem] capitalize text-muted-foreground"
					>
						{entry.meta.harness}
					</Badge>
				</div>
				<p class="mt-1 truncate font-mono text-xs text-muted-foreground">{fragmentPath}</p>
				<div class="mt-2 flex items-center gap-3">
					{#if entry.meta.tags?.length}
						<div class="flex min-w-0 flex-wrap gap-1">
							{#each entry.meta.tags as tag (tag)}
								<button
									type="button"
									class="rounded-[5px] border border-primary/40 bg-primary/5 px-2 py-0.5 text-[0.6875rem] text-muted-foreground transition-colors duration-150 hover:border-primary/70 hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
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
			</div>
		</div>

		{#if description}
			<div class="hidden min-w-0 max-w-[36ch] lg:block">
				<p class="mb-1.5 text-[0.6875rem] font-[550] text-muted-foreground">Description</p>
				<p class="line-clamp-3 text-xs leading-relaxed text-muted-foreground">{description}</p>
			</div>
		{/if}

		<div class="hidden shrink-0 xl:block">
			<p class="mb-1.5 text-[0.6875rem] font-[550] text-muted-foreground">Details</p>
			<dl class="grid grid-cols-[auto_auto] gap-x-6 gap-y-1 text-xs tabular-nums">
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
							class="rounded-[5px] border border-primary/40 bg-primary/5 px-2 py-0.5 text-[0.6875rem] text-muted-foreground transition-colors duration-150 hover:border-primary/70 hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
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
			<p class="mb-1.5 text-[0.6875rem] font-[550] text-muted-foreground">Usage</p>
			<p class="text-xs text-foreground">{usage.lead}</p>
			{#each usage.rest as line (line)}
				<p class="mt-0.5 text-xs text-muted-foreground">{line}</p>
			{/each}
		</div>

		<div class="flex shrink-0 items-center gap-2.5 lg:ms-auto">
			<Button class="h-11 px-7 text-[0.875rem]" onclick={() => gallery.open(entry)}>
				Open shader
			</Button>
			<DropdownMenu.Root>
				<DropdownMenu.Trigger>
					{#snippet child({ props })}
						<Button
							{...props}
							variant="secondary"
							class="size-11 border border-border p-0"
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
	</div>
{/if}
