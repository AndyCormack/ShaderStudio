<script lang="ts">
	import MagnifyingGlass from 'phosphor-svelte/lib/MagnifyingGlass';
	import Check from 'phosphor-svelte/lib/Check';
	import { Input } from '$lib/components/ui/input';
	import { Button } from '$lib/components/ui/button';
	import * as Select from '$lib/components/ui/select';
	import type { GalleryState, HarnessFilter, SortOrder } from '$lib/gallery/gallery-state.svelte';
	import { cn } from '$lib/utils';

	let { gallery }: { gallery: GalleryState } = $props();

	const harnessChips: { id: HarnessFilter; label: string }[] = [
		{ id: 'all', label: 'All' },
		{ id: 'quad', label: 'Quad' },
		{ id: 'mesh', label: 'Mesh' }
	];

	const sortLabels: Record<SortOrder, string> = {
		recent: 'Recently opened',
		name: 'Name'
	};
</script>

<div class="flex min-h-14 shrink-0 flex-wrap items-center gap-x-3 gap-y-2 border-b border-border px-4 py-2 md:h-14 md:flex-nowrap md:py-0">
	<div class="relative min-w-0 basis-full sm:basis-auto sm:min-w-28 sm:flex-1 sm:max-w-72">
		<MagnifyingGlass
			size={16}
			class="pointer-events-none absolute start-2.5 top-1/2 -translate-y-1/2 text-muted-foreground"
		/>
		<Input
			id="gallery-search"
			type="search"
			placeholder="Search shaders…"
			class="h-9 ps-8"
			bind:value={gallery.search}
			aria-label="Search shaders by name, path, or tag"
		/>
	</div>

	<div class="flex items-center gap-1" role="group" aria-label="Filter by harness">
		{#each harnessChips as chip (chip.id)}
			{@const active = gallery.harness === chip.id}
			<button
				type="button"
				class={cn(
					'flex h-9 items-center gap-1.5 rounded-lg px-2.5 text-[0.8125rem] font-[550] transition-colors duration-150',
					active
						? 'bg-selected text-foreground'
						: 'bg-surface-raised text-muted-foreground hover:text-foreground'
				)}
				aria-pressed={active}
				onclick={() => (gallery.harness = chip.id)}
			>
				{#if active}<Check size={14} aria-hidden="true" />{/if}
				{chip.label}
			</button>
		{/each}
	</div>

	<div class="ms-auto hidden items-center gap-2 md:flex">
		<Select.Select type="single" bind:value={gallery.sort}>
			<Select.SelectTrigger class="h-9 w-44" aria-label="Sort order">
				{sortLabels[gallery.sort]}
			</Select.SelectTrigger>
			<Select.SelectContent>
				<Select.SelectItem value="recent">Recently opened</Select.SelectItem>
				<Select.SelectItem value="name">Name</Select.SelectItem>
			</Select.SelectContent>
		</Select.Select>

		<Button
			variant="secondary"
			class="h-9 gap-2"
			onclick={() => (gallery.paletteOpen = true)}
			aria-label="Open command search"
		>
			Search everywhere
			<kbd
				class="rounded-sm bg-background px-1.5 py-0.5 font-mono text-[0.6875rem] text-muted-foreground"
			>
				Ctrl K
			</kbd>
		</Button>
	</div>
</div>
