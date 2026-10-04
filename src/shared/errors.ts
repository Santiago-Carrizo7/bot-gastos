export class AppError extends Error {
  constructor(
    message: string,
    public readonly code: string = 'APP_ERROR',
    public readonly statusCode: number = 400
  ) {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class NotFoundError extends AppError {
  constructor(message: string = 'Recurso no encontrado') {
    super(message, 'NOT_FOUND', 404);
  }
}

export class ExpenseParsingError extends AppError {
  constructor(message: string, public readonly originalResponse?: string) {
    super(message, 'EXPENSE_PARSING_ERROR');
  }
}

export class AIProviderError extends AppError {
  constructor(message: string, public readonly provider: string, statusCode?: number) {
    super(message, 'AI_PROVIDER_ERROR', statusCode ?? 502);
  }
}

export class ConfigError extends AppError {
  constructor(message: string) {
    super(message, 'CONFIG_ERROR');
  }
}
