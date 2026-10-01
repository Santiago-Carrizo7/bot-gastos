export interface CompletePromptParams {
  systemPrompt: string;
  userPrompt: string;
  temperature?: number;
}

export interface IAIProvider {
  readonly name: string;
  completePrompt(params: CompletePromptParams): Promise<string>;
}
