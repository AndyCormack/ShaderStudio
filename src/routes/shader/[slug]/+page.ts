import { error } from '@sveltejs/kit';
import { getEntry } from '$lib/shaders/catalog';
import type { PageLoad } from './$types';

export const load: PageLoad = ({ params }) => {
	const entry = getEntry(params.slug);
	if (!entry) error(404, `No shader entry "${params.slug}"`);
	return { entry };
};
