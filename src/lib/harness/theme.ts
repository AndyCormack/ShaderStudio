import { Color } from 'three';

/**
 * Resolve a CSS custom property (e.g. "--background") to a three `Color`.
 * Reads the token through a probe element, then rasterises the computed value
 * on a 1×1 canvas to sRGB bytes — Chromium serialises OKLCH tokens as
 * `oklch(...)`, which three's `Color` can't parse (it would fall back to white),
 * but canvas 2D fill handles any CSS colour. Keeps app.css the single source of
 * truth for the palette instead of duplicating hex values here.
 */
export function cssColor(varName: string, fallback = '#13121c'): Color {
	if (typeof document === 'undefined') return new Color(fallback);
	const probe = document.createElement('span');
	probe.style.cssText = `color: var(${varName}, ${fallback}); display: none`;
	document.body.appendChild(probe);
	const computed = getComputedStyle(probe).color || fallback;
	probe.remove();

	const canvas = document.createElement('canvas');
	canvas.width = canvas.height = 1;
	const ctx = canvas.getContext('2d');
	if (!ctx) return new Color(fallback);
	ctx.fillStyle = computed;
	ctx.fillRect(0, 0, 1, 1);
	const [r, g, b] = ctx.getImageData(0, 0, 1, 1).data;
	return new Color().setStyle(`rgb(${r}, ${g}, ${b})`);
}
