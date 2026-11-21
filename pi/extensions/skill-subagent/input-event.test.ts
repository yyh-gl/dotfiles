import { describe, expect, test } from "bun:test";
import { shouldIgnoreInputEvent } from "./input-event.ts";

describe("shouldIgnoreInputEvent", () => {
	test("source:extensionは無視する(true)", () => {
		expect(shouldIgnoreInputEvent("extension")).toBe(true);
	});
});
