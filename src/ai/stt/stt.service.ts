import { ISpeechToTextProvider } from './base.js';
import { AppError } from '../../shared/errors.js';
import { logger } from '../../shared/logger.js';

export class SpeechToTextService {
  constructor(private readonly provider?: ISpeechToTextProvider) {}

  isConfigured(): boolean {
    return Boolean(this.provider);
  }

  async transcribe(audioBuffer: Buffer, mimeType: string = 'audio/ogg'): Promise<string> {
    if (!this.provider) {
      throw new AppError(
        'El servicio de reconocimiento de voz no está configurado (falta STT_API_KEY en variables de entorno).'
      );
    }

    if (!audioBuffer || audioBuffer.length === 0) {
      throw new AppError('El archivo de audio está vacío o no pudo ser descargado.');
    }

    logger.debug(`Iniciando transcripción con proveedor: ${this.provider.name}`);
    const text = await this.provider.transcribe({
      audioBuffer,
      mimeType,
      fileName: 'voice.ogg',
      language: 'es',
    });

    const cleaned = text.trim();
    if (!cleaned) {
      throw new AppError('No se pudo detectar voz en el mensaje de audio.');
    }

    return cleaned;
  }
}
