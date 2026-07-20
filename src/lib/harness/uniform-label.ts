/**
 * Derive a uniform label from a raw GLSL uniform name (D18): strip a 1–2
 * lowercase-letter Hungarian prefix (`u_`, `f_`), split on underscores and
 * camelCase boundaries, title-case each word. `u_colorA` → "Color A".
 * Naive casing by design — no acronym dictionary; the raw name stays visible
 * in the uniform panel.
 */
export function uniformLabel(rawName: string): string {
	const words = rawName
		.replace(/^[a-z]{1,2}_/, '')
		.split('_')
		.flatMap((part) => part.split(/(?<=[a-z0-9])(?=[A-Z])/))
		.filter(Boolean);
	if (words.length === 0) return rawName;
	return words.map((word) => word[0].toUpperCase() + word.slice(1)).join(' ');
}
