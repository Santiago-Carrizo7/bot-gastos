export class AppError extends Error {
  constructor(message: string, public readonly code: string = 'APP_ERROR') {
    super(message);
    this.name = this.constructor.name;
    Error.captureStackTrace(this, this.constructor);
  }
}

export class ExpenseParsingError extends AppError {
  constructor(message: string, public readonly originalResponse?: string) {
    super(message, 'EXPENSE_PARSING_ERROR');
  }
}

export class AIProviderError extends AppError {
  constructor(message: string, public readonly provider: string, public readonly statusCode?: number) {
    super(message, 'AI_PROVIDER_ERROR');
  }
}

export class ConfigError extends AppError {
  constructor(message: string) {
    super(message, 'CONFIG_ERROR');
  }
}
