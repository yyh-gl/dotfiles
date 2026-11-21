import { describe, expect, test } from "bun:test";
import { shouldIgnoreInputEvent } from "./input-event.ts";

describe("shouldIgnoreInputEvent", () => {
	test("source:extensionは無視する(true)", () => {
		expect(shouldIgnoreInputEvent("extension")).toBe(true);
	});

	test.each(["interactive" as const, "rpc" as const])("source:%sは無視しない(false)", (source) => {
		expect(shouldIgnoreInputEvent(source)).toBe(false);
	});
});
