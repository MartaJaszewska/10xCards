// src/types.ts

import type { Database } from "./db/database.types";

// ============================================================================
// BASE DATABASE TYPE ALIASES
// ============================================================================

export type Flashcard = Database["public"]["Tables"]["flashcards"]["Row"];
export type FlashcardInsert = Database["public"]["Tables"]["flashcards"]["Insert"];
export type FlashcardUpdate = Database["public"]["Tables"]["flashcards"]["Update"];
export type Generation = Database["public"]["Tables"]["generations"]["Row"];
export type GenerationErrorLog = Database["public"]["Tables"]["generation_error_logs"]["Row"];

// ============================================================================
// ENUMS AND CONSTANTS
// ============================================================================

export type Source = "ai-full" | "ai-edited" | "manual";

// ============================================================================
// FLASHCARD DTOs AND COMMANDS
// ============================================================================

/**
 * Single flashcard DTO - excludes user_id for security
 * Used in all flashcard-related API responses
 */
export type FlashcardDTO = Pick<
  Flashcard,
  "id" | "front" | "back" | "source" | "generation_id" | "created_at" | "updated_at"
>;

/**
 * Pagination metadata for list endpoints
 */
export interface PaginationDTO {
  page: number;
  limit: number;
  total_items: number;
  total_pages: number;
  has_next: boolean;
  has_previous: boolean;
}

/**
 * Paginated list of flashcards
 * Response for GET /api/flashcards
 */
export interface FlashcardListDTO {
  data: FlashcardDTO[];
  pagination: PaginationDTO;
}

/**
 * Command to create a single flashcard
 * Used within CreateFlashcardsCommand array
 */
export type CreateFlashcardCommand = Pick<
  FlashcardInsert,
  "front" | "back" | "source" | "generation_id"
>;

/**
 * Command to create multiple flashcards (batch operation)
 * Request body for POST /api/flashcards
 */
export interface CreateFlashcardsCommand {
  flashcards: CreateFlashcardCommand[];
}

/**
 * Response after creating flashcards
 * Response for POST /api/flashcards
 */
export interface CreateFlashcardsResponseDTO {
  flashcards: FlashcardDTO[];
}

/**
 * Command to update an existing flashcard
 * Only front and back can be updated (source and generation_id are immutable)
 * Request body for PUT /api/flashcards/:id
 */
export type UpdateFlashcardCommand = Required<Pick<FlashcardUpdate, "front" | "back">>;

// ============================================================================
// GENERATION DTOs AND COMMANDS
// ============================================================================

/**
 * AI-generated flashcard proposal (not yet saved to database)
 * Used in GenerationResponseDTO
 */
export interface GenerationProposalDTO {
  front: string;
  back: string;
  source: Extract<Source, "ai-full">;
}

/**
 * Command to generate flashcards from source text
 * Request body for POST /api/generations
 */
export interface GenerateFlashcardsCommand {
  source_text: string;
}

/**
 * Response after generating flashcard proposals
 * Response for POST /api/generations
 */
export interface GenerationResponseDTO {
  generation_id: number;
  flashcards_proposals: GenerationProposalDTO[];
  generated_count: number;
  source_text_length: number;
  generation_duration: number;
  created_at: string;
}

/**
 * Basic generation information - excludes sensitive fields (user_id, source_text_hash)
 * Base type for various generation DTOs
 */
export type GenerationDTO = Pick<
  Generation,
  | "id"
  | "model"
  | "generated_count"
  | "generation_duration"
  | "source_text_length"
  | "accepted_unedited_count"
  | "accepted_edited_count"
  | "created_at"
  | "updated_at"
>;

/**
 * Detailed generation information with associated flashcards
 * Response for GET /api/generations/:id
 */
export interface GenerationDetailsDTO extends GenerationDTO {
  flashcards: FlashcardDTO[];
}

/**
 * Generation history item with calculated acceptance rate
 * Used in GenerationHistoryDTO
 */
export interface GenerationHistoryItemDTO extends GenerationDTO {
  acceptance_rate: number;
}

/**
 * Summary statistics for user's generation history
 * Used in GenerationHistoryDTO
 */
export interface GenerationSummaryDTO {
  total_generations: number;
  total_candidates_generated: number;
  total_accepted_unedited: number;
  total_accepted_edited: number;
  overall_acceptance_rate: number;
}

/**
 * Paginated generation history with summary statistics
 * Response for GET /api/generations
 */
export interface GenerationHistoryDTO {
  data: GenerationHistoryItemDTO[];
  pagination: PaginationDTO;
  summary: GenerationSummaryDTO;
}

// ============================================================================
// GENERATION ERROR LOG DTOs
// ============================================================================

/**
 * Generation error log entry - excludes sensitive fields (user_id, source_text_hash)
 * Used in error log responses
 */
export type GenerationErrorLogDTO = Pick<
  GenerationErrorLog,
  "id" | "model" | "source_text_length" | "error_code" | "error_message" | "created_at"
>;

/**
 * Paginated list of generation error logs
 * Response for GET /api/generation-error-logs
 */
export interface GenerationErrorLogListDTO {
  data: GenerationErrorLogDTO[];
  pagination: PaginationDTO;
}

// ============================================================================
// ERROR RESPONSE TYPES
// ============================================================================

/**
 * Standard error response structure
 */
export interface ErrorResponseDTO {
  error: string;
  message: string;
  details?: Record<string, unknown>;
}

/**
 * Error response for failed generation with error log reference
 */
export interface GenerationErrorResponseDTO extends ErrorResponseDTO {
  error_log_id: number;
}
