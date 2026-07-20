/** "9.6 KB" — file sizes as shown on tiles and the detail strip. */
export function formatSize(bytes: number): string {
	if (bytes <= 0) return '—';
	if (bytes < 1024) return `${bytes} B`;
	const kb = bytes / 1024;
	if (kb < 1024) return `${kb < 10 ? kb.toFixed(1) : Math.round(kb)} KB`;
	return `${(kb / 1024).toFixed(1)} MB`;
}

const UNITS: { ms: number; short: string; long: string }[] = [
	{ ms: 365 * 24 * 3_600_000, short: 'y', long: 'year' },
	{ ms: 30 * 24 * 3_600_000, short: 'mo', long: 'month' },
	{ ms: 7 * 24 * 3_600_000, short: 'w', long: 'week' },
	{ ms: 24 * 3_600_000, short: 'd', long: 'day' },
	{ ms: 3_600_000, short: 'h', long: 'hour' },
	{ ms: 60_000, short: 'm', long: 'minute' }
];

/** "2h ago" (tiles) or "2 hours ago" (detail strip); "just now" under a minute. */
export function formatAgo(epochMs: number, style: 'short' | 'long' = 'short'): string {
	if (epochMs <= 0) return '—';
	const elapsed = Date.now() - epochMs;
	for (const { ms, short, long } of UNITS) {
		if (elapsed >= ms) {
			const n = Math.floor(elapsed / ms);
			return style === 'short' ? `${n}${short} ago` : `${n} ${long}${n === 1 ? '' : 's'} ago`;
		}
	}
	return 'just now';
}
