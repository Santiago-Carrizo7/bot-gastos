export interface TranscribeAudioParams {
  audioBuffer: Buffer;
  fileName?: string;
  mimeType?: string;
  language?: string;
}

export interface ISpeechToTextProvider {
  readonly name: string;
  transcribe(params: TranscribeAudioParams): Promise<string>;
}
