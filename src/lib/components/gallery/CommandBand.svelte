<script lang="ts">
	import MagnifyingGlass from 'phosphor-svelte/lib/MagnifyingGlass';
	import { Input } from '$lib/components/ui/input';
	import { Button } from '$lib/components/ui/button';
	import * as Select from '$lib/components/ui/select';
	import type { GalleryState, SortOrder } from '$lib/gallery/gallery-state.svelte';

	let { gallery }: { gallery: GalleryState } = $props();

	const sortLabels: Record<SortOrder, string> = {
		recent: 'Recently opened',
		name: 'Name'
	};
</script>

<div class="flex min-h-14 shrink-0 items-center gap-3 border-b border-border px-4 py-2 md:h-14 md:py-0">
	<div class="relative min-w-0 flex-1 md:max-w-xl">
		<MagnifyingGlass
			size={16}
			class="pointer-events-none absolute start-3 top-1/2 -translate-y-1/2 text-muted-foreground"
		/>
		<Input
			id="gallery-search"
			type="search"
			placeholder="Search shaders…"
			class="h-9 bg-surface pe-9 ps-9"
			bind:value={gallery.search}
			aria-label="Search shaders by name, path, or tag"
		/>
		<kbd
			class="pointer-events-none absolute end-2.5 top-1/2 -translate-y-1/2 rounded-sm border border-border bg-background px-1.5 py-px font-mono text-[0.6875rem] text-muted-foreground"
		>
			/
		</kbd>
	</div>

	<div class="ms-auto flex items-center gap-2">
		<Select.Select type="single" bind:value={gallery.sort}>
			<Select.SelectTrigger class="hidden h-9 w-44 sm:flex" aria-label="Sort order">
				{sortLabels[gallery.sort]}
			</Select.SelectTrigger>
			<Select.SelectContent>
				<Select.SelectItem value="recent">Recently opened</Select.SelectItem>
				<Select.SelectItem value="name">Name</Select.SelectItem>
			</Select.SelectContent>
		</Select.Select>

		<Button
			variant="secondary"
			class="hidden h-9 gap-2 md:flex"
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
