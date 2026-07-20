<script lang="ts">
	import * as Command from '$lib/components/ui/command';
	import type { GalleryState } from '$lib/gallery/gallery-state.svelte';

	// ⌘K overlay — the fastest route into the collection. Selecting a shader
	// opens it in the studio; tags and views adjust the atlas filters.
	let { gallery }: { gallery: GalleryState } = $props();
</script>

<Command.CommandDialog bind:open={gallery.paletteOpen} title="Command search" description="Search shaders, tags, and views">
	<Command.CommandInput placeholder="Search shaders, tags, views…" />
	<Command.CommandList>
		<Command.CommandEmpty>No results.</Command.CommandEmpty>
		<Command.CommandGroup heading="Shaders">
			{#each gallery.entries as entry (entry.slug)}
				<Command.CommandItem
					value={`${entry.meta.name} ${entry.slug} ${(entry.meta.tags ?? []).join(' ')}`}
					onSelect={() => {
						gallery.paletteOpen = false;
						gallery.open(entry);
					}}
				>
					<span>{entry.meta.name}</span>
					<span class="ms-2 font-mono text-xs text-muted-foreground">shaders/{entry.slug}/</span>
					<Command.CommandShortcut>{entry.meta.harness}</Command.CommandShortcut>
				</Command.CommandItem>
			{/each}
		</Command.CommandGroup>
		{#if gallery.tagCounts.length > 0}
			<Command.CommandSeparator />
			<Command.CommandGroup heading="Tags">
				{#each gallery.tagCounts as [tag, count] (tag)}
					<Command.CommandItem
						value={`tag ${tag}`}
						onSelect={() => {
							gallery.tag = tag;
							gallery.section = 'gallery';
							gallery.paletteOpen = false;
						}}
					>
						<span class="font-mono">{tag}</span>
						<Command.CommandShortcut>{count}</Command.CommandShortcut>
					</Command.CommandItem>
				{/each}
			</Command.CommandGroup>
		{/if}
		<Command.CommandSeparator />
		<Command.CommandGroup heading="Views">
			<Command.CommandItem value="view gallery" onSelect={() => { gallery.clearFilters(); gallery.paletteOpen = false; }}>
				Gallery — all shaders
			</Command.CommandItem>
			<Command.CommandItem value="view favorites" onSelect={() => { gallery.section = 'favorites'; gallery.tag = null; gallery.paletteOpen = false; }}>
				Favorites
			</Command.CommandItem>
			<Command.CommandItem value="view recent" onSelect={() => { gallery.section = 'recent'; gallery.tag = null; gallery.paletteOpen = false; }}>
				Recent
			</Command.CommandItem>
		</Command.CommandGroup>
	</Command.CommandList>
</Command.CommandDialog>
