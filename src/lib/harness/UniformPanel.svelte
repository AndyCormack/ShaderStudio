<script lang="ts">
	import ArrowCounterClockwise from 'phosphor-svelte/lib/ArrowCounterClockwise';
	import SlidersHorizontal from 'phosphor-svelte/lib/SlidersHorizontal';
	import { Color, type RawShaderMaterial } from 'three';
	import { Button } from '$lib/components/ui/button';
	import { Input } from '$lib/components/ui/input';
	import { InputGroup, InputGroupAddon, InputGroupInput } from '$lib/components/ui/input-group';
	import { Slider } from '$lib/components/ui/slider';
	import * as Select from '$lib/components/ui/select';
	import * as Tooltip from '$lib/components/ui/tooltip';
	import type { BloomControls, ShaderEntry, UniformDef } from '$lib/shaders/types';
	import { uniformLabel } from './uniform-label';

	type FloatDef = Extract<UniformDef, { type: 'float' }>;
	type ColorDef = Extract<UniformDef, { type: 'color' }>;
	type SelectDef = Extract<UniformDef, { type: 'select' }>;

	let {
		entry,
		material,
		bloom,
		onhide
	}: {
		entry: ShaderEntry;
		material: RawShaderMaterial;
		bloom?: BloomControls;
		onhide: () => void;
	} = $props();

	// Live post-fx (bloom) controls, when the entry declares a post-fx stack (D21).
	type BloomFloat = { key: 'strength' | 'radius' | 'threshold'; label: string; min: number; max: number; step: number };
	const bloomFloats: BloomFloat[] = [
		{ key: 'strength', label: 'Bloom Strength', min: 0, max: 3, step: 0.05 },
		{ key: 'radius', label: 'Bloom Radius', min: 0, max: 1, step: 0.01 },
		{ key: 'threshold', label: 'Bloom Threshold', min: 0, max: 2, step: 0.05 }
	];

	function commitBloomFloat(control: BloomFloat, input: HTMLInputElement) {
		if (!bloom) return;
		const parsed = Number.parseFloat(input.value);
		if (Number.isFinite(parsed)) {
			bloom[control.key] = Math.min(control.max, Math.max(control.min, parsed));
		}
		input.value = formatFloat(bloom[control.key]);
	}

	function commitBloomHex(input: HTMLInputElement) {
		if (!bloom) return;
		const normalized = normalizeHex(input.value);
		if (normalized) bloom.color = normalized;
		input.value = bloom.color;
	}

	const defs = $derived(entry.meta.uniforms ?? []);
	let values = $state<Record<string, number | string>>({});
	let initedFor = '';

	$effect(() => {
		if (entry.slug === initedFor) return;
		initedFor = entry.slug;
		values = {};
	});

	// Write-through: push UI values into the live material's uniforms. Runs
	// again when the material is recreated (shader HMR, entry reload), so
	// tweaked values are re-applied rather than lost.
	$effect(() => {
		for (const definition of defs) {
			const uniform = material.uniforms[definition.name];
			const value = values[definition.name] ?? definition.default;
			if (!uniform) continue;
			if (definition.type === 'color') (uniform.value as Color).set(value as string);
			else uniform.value = value;
		}
	});

	function reset() {
		values = {};
	}

	function floatValue(definition: FloatDef): number {
		return (values[definition.name] as number | undefined) ?? definition.default;
	}

	function colorValue(definition: ColorDef): string {
		return (values[definition.name] as string | undefined) ?? definition.default;
	}

	function selectValue(definition: SelectDef): number {
		return (values[definition.name] as number | undefined) ?? definition.default;
	}

	function selectLabel(definition: SelectDef): string {
		const value = selectValue(definition);
		return definition.options.find((o) => o.value === value)?.label ?? String(value);
	}

	// Trims slider float artifacts (0.1 + 0.05 → 0.15000000000000002) while
	// keeping typed precision beyond the step (D18: clamp, don't snap).
	function formatFloat(value: number): string {
		return String(Number(value.toFixed(4)));
	}

	function commitFloat(definition: FloatDef, input: HTMLInputElement) {
		const parsed = Number.parseFloat(input.value);
		if (Number.isFinite(parsed)) {
			values[definition.name] = Math.min(definition.max, Math.max(definition.min, parsed));
		}
		input.value = formatFloat(floatValue(definition));
	}

	/** `abc123` / `#abc` → `#abc123` / `#aabbcc`; undefined when not a hex color. */
	function normalizeHex(text: string): string | undefined {
		let hex = text.trim().toLowerCase();
		if (!hex.startsWith('#')) hex = `#${hex}`;
		if (/^#[0-9a-f]{3}$/.test(hex)) hex = `#${[...hex.slice(1)].map((c) => c + c).join('')}`;
		return /^#[0-9a-f]{6}$/.test(hex) ? hex : undefined;
	}

	function commitHex(definition: ColorDef, input: HTMLInputElement) {
		const normalized = normalizeHex(input.value);
		if (normalized) values[definition.name] = normalized;
		input.value = colorValue(definition);
	}

	function onCommitKeydown(
		event: KeyboardEvent,
		commit: (input: HTMLInputElement) => void,
		revert: () => string
	) {
		const input = event.currentTarget as HTMLInputElement;
		if (event.key === 'Enter') commit(input);
		else if (event.key === 'Escape') {
			event.stopPropagation();
			input.value = revert();
			input.blur();
		}
	}
</script>

<aside class="flex h-full min-h-0 flex-col bg-surface text-foreground" aria-label="Uniform panel">
	<header class="flex min-h-13 items-center justify-between gap-3 border-b border-border px-3 py-2">
		<h2 class="text-sm font-[650] leading-tight">Uniforms</h2>
		<Tooltip.Provider delayDuration={300}>
			<div class="flex items-center gap-0.5">
				<Tooltip.Root>
					<Tooltip.Trigger>
						{#snippet child({ props })}
							<Button
								{...props}
								variant="ghost"
								size="icon-sm"
								class="text-muted-foreground hover:text-foreground"
								onclick={reset}
								disabled={defs.length === 0}
								aria-label="Reset uniforms"
							>
								<ArrowCounterClockwise size={15} />
							</Button>
						{/snippet}
					</Tooltip.Trigger>
					<Tooltip.Content side="bottom">Reset uniforms</Tooltip.Content>
				</Tooltip.Root>
				<Tooltip.Root>
					<Tooltip.Trigger>
						{#snippet child({ props })}
							<Button
								{...props}
								variant="ghost"
								size="icon-sm"
								class="text-muted-foreground hover:text-foreground"
								onclick={onhide}
								aria-label="Hide controls"
								aria-controls="uniform-panel-region"
								aria-expanded="true"
							>
								<SlidersHorizontal size={15} />
							</Button>
						{/snippet}
					</Tooltip.Trigger>
					<Tooltip.Content side="bottom">Hide controls</Tooltip.Content>
				</Tooltip.Root>
			</div>
		</Tooltip.Provider>
	</header>

	{#if defs.length || bloom}
		<div class="min-h-0 flex-1 overflow-y-auto p-2">
			{#each defs as definition (definition.name)}
				<div
					class="grid grid-cols-[6.75rem_minmax(0,1fr)] items-center gap-x-2.5 rounded-md px-2 py-1.5 transition-colors hover:bg-surface-raised/50"
				>
					<div class="min-w-0" title={definition.name}>
						<p id={`uniform-label-${definition.name}`} class="truncate text-xs font-medium leading-4">
							{uniformLabel(definition.name)}
						</p>
						<code class="block truncate font-mono text-[0.6875rem] leading-4 text-muted-foreground">
							{definition.name}
						</code>
					</div>
					{#if definition.type === 'float'}
						<div class="flex items-center gap-2">
							<Slider
								type="single"
								min={definition.min}
								max={definition.max}
								step={definition.step ?? 0.01}
								bind:value={
									() => floatValue(definition), (next) => (values[definition.name] = next)
								}
								aria-labelledby={`uniform-label-${definition.name}`}
								class="min-w-0 grow"
							/>
							<Input
								class="h-6 w-14 shrink-0 rounded-md border-transparent bg-transparent px-1 text-right font-mono text-xs tabular-nums text-muted-foreground focus-visible:text-foreground dark:bg-transparent"
								value={formatFloat(floatValue(definition))}
								inputmode="decimal"
								aria-label={`${uniformLabel(definition.name)} value`}
								onkeydown={(event) =>
									onCommitKeydown(
										event,
										(input) => commitFloat(definition, input),
										() => formatFloat(floatValue(definition))
									)}
								onblur={(event) => commitFloat(definition, event.currentTarget as HTMLInputElement)}
							/>
						</div>
					{:else if definition.type === 'color'}
						<InputGroup class="h-7 rounded-md">
							<InputGroupAddon>
								<span
									class="relative size-4.5 shrink-0 overflow-hidden rounded-[5px] border border-border"
									style={`background:${colorValue(definition)}`}
								>
									<input
										type="color"
										class="absolute inset-0 size-full cursor-pointer opacity-0"
										value={colorValue(definition)}
										aria-label={`${uniformLabel(definition.name)} color picker`}
										oninput={(event) =>
											(values[definition.name] = (event.currentTarget as HTMLInputElement).value)}
									/>
								</span>
							</InputGroupAddon>
							<InputGroupInput
								class="px-1.5 font-mono text-xs tabular-nums text-muted-foreground focus-visible:text-foreground md:text-xs"
								value={colorValue(definition)}
								spellcheck={false}
								aria-label={`${uniformLabel(definition.name)} hex value`}
								onkeydown={(event) =>
									onCommitKeydown(
										event,
										(input) => commitHex(definition, input),
										() => colorValue(definition)
									)}
								onblur={(event) => commitHex(definition, event.currentTarget as HTMLInputElement)}
							/>
						</InputGroup>
					{:else}
						<Select.Select
							type="single"
							bind:value={
								() => String(selectValue(definition)),
								(next) => (values[definition.name] = Number(next))
							}
						>
							<Select.SelectTrigger
								class="h-7 w-full rounded-md text-xs"
								aria-labelledby={`uniform-label-${definition.name}`}
							>
								{selectLabel(definition)}
							</Select.SelectTrigger>
							<Select.SelectContent>
								{#each definition.options as option (option.value)}
									<Select.SelectItem value={String(option.value)}>{option.label}</Select.SelectItem>
								{/each}
							</Select.SelectContent>
						</Select.Select>
					{/if}
				</div>
			{/each}

			{#if bloom}
				<div class="mt-1 px-2 pb-1 pt-2">
					<p class="text-[0.6875rem] font-[650] uppercase tracking-wide text-muted-foreground">
						Post-FX
					</p>
				</div>
				{#each bloomFloats as control (control.key)}
					<div
						class="grid grid-cols-[6.75rem_minmax(0,1fr)] items-center gap-x-2.5 rounded-md px-2 py-1.5 transition-colors hover:bg-surface-raised/50"
					>
						<div class="min-w-0">
							<p id={`bloom-label-${control.key}`} class="truncate text-xs font-medium leading-4">
								{control.label}
							</p>
							<code class="block truncate font-mono text-[0.6875rem] leading-4 text-muted-foreground">
								bloom.{control.key}
							</code>
						</div>
						<div class="flex items-center gap-2">
							<Slider
								type="single"
								min={control.min}
								max={control.max}
								step={control.step}
								bind:value={
									() => bloom![control.key], (next) => (bloom![control.key] = next)
								}
								aria-labelledby={`bloom-label-${control.key}`}
								class="min-w-0 grow"
							/>
							<Input
								class="h-6 w-14 shrink-0 rounded-md border-transparent bg-transparent px-1 text-right font-mono text-xs tabular-nums text-muted-foreground focus-visible:text-foreground dark:bg-transparent"
								value={formatFloat(bloom![control.key])}
								inputmode="decimal"
								aria-label={`${control.label} value`}
								onkeydown={(event) =>
									onCommitKeydown(
										event,
										(input) => commitBloomFloat(control, input),
										() => formatFloat(bloom![control.key])
									)}
								onblur={(event) => commitBloomFloat(control, event.currentTarget as HTMLInputElement)}
							/>
						</div>
					</div>
				{/each}
				<div
					class="grid grid-cols-[6.75rem_minmax(0,1fr)] items-center gap-x-2.5 rounded-md px-2 py-1.5 transition-colors hover:bg-surface-raised/50"
				>
					<div class="min-w-0">
						<p id="bloom-label-color" class="truncate text-xs font-medium leading-4">Bloom Color</p>
						<code class="block truncate font-mono text-[0.6875rem] leading-4 text-muted-foreground">
							bloom.color
						</code>
					</div>
					<InputGroup class="h-7 rounded-md">
						<InputGroupAddon>
							<span
								class="relative size-4.5 shrink-0 overflow-hidden rounded-[5px] border border-border"
								style={`background:${bloom.color}`}
							>
								<input
									type="color"
									class="absolute inset-0 size-full cursor-pointer opacity-0"
									value={bloom.color}
									aria-label="Bloom Color color picker"
									oninput={(event) =>
										(bloom!.color = (event.currentTarget as HTMLInputElement).value)}
								/>
							</span>
						</InputGroupAddon>
						<InputGroupInput
							class="px-1.5 font-mono text-xs tabular-nums text-muted-foreground focus-visible:text-foreground md:text-xs"
							value={bloom.color}
							spellcheck={false}
							aria-label="Bloom Color hex value"
							onkeydown={(event) =>
								onCommitKeydown(
									event,
									(input) => commitBloomHex(input),
									() => bloom!.color
								)}
							onblur={(event) => commitBloomHex(event.currentTarget as HTMLInputElement)}
						/>
					</InputGroup>
				</div>
			{/if}
		</div>
	{:else}
		<div
			class="flex min-h-32 flex-1 items-center justify-center gap-2.5 p-6 text-[0.8125rem] text-muted-foreground"
		>
			<SlidersHorizontal size={18} />
			<p class="max-w-[22ch] text-center">This shader has no authored uniforms.</p>
		</div>
	{/if}
</aside>
