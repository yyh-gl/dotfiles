import { StringDecoder } from "node:string_decoder";

/** Wraps a StringDecoder so multi-byte characters split across chunk boundaries decode correctly. */
export function createBufferDecoder(): (chunk: Buffer) => string {
	const decoder = new StringDecoder("utf-8");
	return (chunk) => decoder.write(chunk);
}

export interface NdjsonFeedResult {
	lines: string[];
	pending: string;
}

export function parseNdjsonLine(line: string): unknown | undefined {
	if (!line.trim()) return undefined;
	try {
		return JSON.parse(line);
	} catch {
		return undefined;
	}
}

export function feedNdjsonChunk(pending: string, chunk: string): NdjsonFeedResult {
	const combined = pending + chunk;
	const lines = combined.split("\n");
	const newPending = lines.pop() ?? "";
	return { lines, pending: newPending };
}
