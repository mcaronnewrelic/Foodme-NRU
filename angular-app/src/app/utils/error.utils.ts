/**
 * Utility functions for error handling and flattening
 */

export interface FlattenedError {
  message: string;
  status: number;
  statusText: string;
  url: string;
  name: string;
  timestamp: string;
  stack?: string;
  [key: string]: any;
}

/**
 * Flattens an error object for better logging and debugging
 * @param error - The error object to flatten
 * @param additionalContext - Optional additional context to include
 * @returns A flattened error object with all relevant properties
 */
export function flattenError(error: any, additionalContext?: Record<string, any>): FlattenedError {
  const flattenedError: FlattenedError = {
    message: error?.message || 'Unknown error',
    status: error?.status || 0,
    statusText: error?.statusText || 'Unknown',
    url: error?.url || 'Unknown URL',
    name: error?.name || 'Error',
    timestamp: new Date().toISOString(),
    stack: error?.stack || 'No stack trace available'
  };

  // Flatten nested error details if they exist
  if (error?.error && typeof error.error === 'object') {
    Object.assign(flattenedError, error.error);
  }

  // Add any additional context
  if (additionalContext) {
    Object.assign(flattenedError, additionalContext);
  }

  // Handle HttpErrorResponse specific properties
  if (error?.headers) {
    flattenedError['headers'] = error.headers;
  }

  // Handle Angular HTTP error details
  if (error?.error && typeof error.error === 'string') {
    flattenedError['errorBody'] = error.error;
  }

  return flattenedError;
}

/**
 * Extracts key information from an error for concise logging
 * @param error - The error object
 * @returns A simplified error summary
 */
export function getErrorSummary(error: any): string {
  if (!error) return 'Unknown error occurred';
  
  const status = error.status || 'Unknown';
  const message = error.message || error.error?.message || 'No message';
  const url = error.url || 'Unknown URL';
  
  return `[${status}] ${message} at ${url}`;
}

/**
 * Safely converts an error object to a JSON string
 * @param error - The error object
 * @param space - Number of spaces for indentation (optional)
 * @returns JSON string representation of the error
 */
export function errorToJson(error: any, space?: number): string {
  try {
    const flattened = flattenError(error);
    return JSON.stringify(flattened, null, space);
  } catch (e) {
    return `Error serialization failed: ${e}`;
  }
}

/**
 * Creates a user-friendly error message from an error object
 * @param error - The error object
 * @returns A user-friendly error message
 */
export function getUserFriendlyErrorMessage(error: any): string {
  if (!error) return 'An unexpected error occurred. Please try again.';
  
  // Handle specific HTTP status codes
  switch (error.status) {
    case 0:
      return 'Unable to connect to the server. Please check your internet connection.';
    case 400:
      return 'Invalid request. Please check your input and try again.';
    case 401:
      return 'You are not authorized to perform this action. Please log in.';
    case 403:
      return 'You do not have permission to access this resource.';
    case 404:
      return 'The requested resource was not found.';
    case 500:
      return 'Internal server error. Please try again later.';
    case 503:
      return 'Service temporarily unavailable. Please try again later.';
    default:
      return error.message || 'An unexpected error occurred. Please try again.';
  }
}
