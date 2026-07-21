import { Color } from 'three';
import type { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';
import type { BloomControls } from '$lib/shaders/types';

// Bloom spread/energy grows relative to the image as resolution drops, so a
// strength tuned for the full studio render washes out small preview tiles.
// Scale strength toward a reference render height so the glow reads the same
// at every size (D21).
const REF_HEIGHT = 1600;
const MIN_FACTOR = 0.3;

const scratchTint = new Color();

export function bloomStrengthFor(strength: number, renderHeightPx: number): number {
	const factor = Math.min(1, Math.max(MIN_FACTOR, renderHeightPx / REF_HEIGHT));
	return strength * factor;
}

/** Push live bloom values into the pass: resolution-scaled strength, and a
 *  colour tint so bloom glows in-colour rather than washing to white. */
export function applyBloom(pass: UnrealBloomPass, bloom: BloomControls, renderHeightPx: number) {
	pass.strength = bloomStrengthFor(bloom.strength, renderHeightPx);
	pass.radius = bloom.radius;
	pass.threshold = bloom.threshold;
	// bloomTintColors are Vector3s (multiplied into the bloom); fill them from
	// the tint's linear rgb so the glow takes the colour.
	scratchTint.set(bloom.color);
	for (let i = 0; i < pass.bloomTintColors.length; i++) {
		pass.bloomTintColors[i].set(scratchTint.r, scratchTint.g, scratchTint.b);
	}
}
