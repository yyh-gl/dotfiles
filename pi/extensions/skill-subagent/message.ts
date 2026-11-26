interface MessageContentPart {
	type: string;
	text?: string;
}

interface AssistantLikeMessage {
	role: string;
	content?: readonly MessageContentPart[];
}

export function extractAssistantText(message: AssistantLikeMessage): string {
	if (message.role !== "assistant") return "";
	return (message.content ?? [])
		.filter((part) => part.type === "text")
		.map((part) => part.text ?? "")
		.join("");
}
