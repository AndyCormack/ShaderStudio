<script lang="ts">
	import MagnifyingGlass from 'phosphor-svelte/lib/MagnifyingGlass';
	import Funnel from 'phosphor-svelte/lib/Funnel';
	import { Input } from '$lib/components/ui/input';
	import { Button } from '$lib/components/ui/button';
	import * as Select from '$lib/components/ui/select';
	import * as DropdownMenu from '$lib/components/ui/dropdown-menu';
	import type { GalleryState, HarnessFilter, SortOrder } from '$lib/gallery/gallery-state.svelte';

	let { gallery }: { gallery: GalleryState } = $props();

	const sortLabels: Record<SortOrder, string> = {
		updated: 'Recently updated',
		recent: 'Recently opened',
		name: 'Name'
	};

	const harnessLabels: Record<HarnessFilter, string> = {
		all: 'All harnesses',
		quad: 'Quad',
		mesh: 'Mesh'
	};

	const activeFilters = $derived((gallery.harness !== 'all' ? 1 : 0) + (gallery.tag ? 1 : 0));
</script>

<div
	class="flex min-h-16 shrink-0 items-center gap-3 border-b border-border px-4 py-2.5 md:h-[4.5rem] md:py-0 md:pe-5 md:ps-4"
>
	<div class="relative min-w-0 flex-1">
		<MagnifyingGlass
			size={17}
			class="pointer-events-none absolute start-3.5 top-1/2 -translate-y-1/2 text-muted-foreground"
		/>
		<Input
			id="gallery-search"
			type="search"
			placeholder="Search shaders…"
			class="h-11 bg-surface pe-10 ps-10"
			bind:value={gallery.search}
			aria-label="Search shaders by name, path, or tag"
		/>
		<kbd
			class="pointer-events-none absolute end-3 top-1/2 -translate-y-1/2 rounded-sm border border-border bg-background px-1.5 py-0.5 font-mono text-[0.6875rem] text-muted-foreground"
		>
			/
		</kbd>
	</div>

	<div class="flex items-center gap-2.5">
		<DropdownMenu.Root>
			<DropdownMenu.Trigger>
				{#snippet child({ props })}
					<Button
						{...props}
						variant="secondary"
						class="h-11 gap-2 border border-border px-4"
						aria-label="Filter shaders"
					>
						<Funnel size={16} aria-hidden="true" />
						Filters
						{#if activeFilters > 0}
							<span
								class="flex size-4.5 items-center justify-center rounded-full bg-selected text-[0.625rem] font-[600] tabular-nums text-foreground"
							>
								{activeFilters}
							</span>
						{/if}
					</Button>
				{/snippet}
			</DropdownMenu.Trigger>
			<DropdownMenu.Content align="end" class="w-52">
				<DropdownMenu.Label>Harness</DropdownMenu.Label>
				<DropdownMenu.RadioGroup bind:value={gallery.harness}>
					{#each Object.entries(harnessLabels) as [id, label] (id)}
						<DropdownMenu.RadioItem value={id} closeOnSelect={false}>
							{label}
						</DropdownMenu.RadioItem>
					{/each}
				</DropdownMenu.RadioGroup>
				{#if gallery.tag}
					<DropdownMenu.Separator />
					<DropdownMenu.Label>Tag</DropdownMenu.Label>
					<DropdownMenu.Item onclick={() => (gallery.tag = null)}>
						<span class="min-w-0 truncate font-mono">{gallery.tag}</span>
						<span class="ms-auto text-xs text-muted-foreground">Clear</span>
					</DropdownMenu.Item>
				{/if}
				{#if activeFilters > 0}
					<DropdownMenu.Separator />
					<DropdownMenu.Item onclick={() => gallery.clearFilters()}>
						Clear all filters
					</DropdownMenu.Item>
				{/if}
			</DropdownMenu.Content>
		</DropdownMenu.Root>

		<Select.Select type="single" bind:value={gallery.sort}>
			<Select.SelectTrigger class="hidden !h-11 w-48 sm:flex" aria-label="Sort order">
				{sortLabels[gallery.sort]}
			</Select.SelectTrigger>
			<Select.SelectContent>
				<Select.SelectItem value="updated">Recently updated</Select.SelectItem>
				<Select.SelectItem value="recent">Recently opened</Select.SelectItem>
				<Select.SelectItem value="name">Name</Select.SelectItem>
			</Select.SelectContent>
		</Select.Select>
	</div>
</div>
