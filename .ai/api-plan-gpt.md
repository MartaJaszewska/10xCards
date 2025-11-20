# REST API Plan

## 1. Resources

- **Flashcard**
  - **DB table**: `public.flashcards`
  - **Description**: User-owned flashcards; each card optionally linked to an AI generation record.
- **Generation**
  - **DB table**: `public.generations`
  - **Description**: Per-user metadata about successful AI flashcard generation runs and aggregate stats.
- **GenerationErrorLog**
  - **DB table**: `public.generation_error_logs`
  - **Description**: Per-user error logs for failed AI flashcard generation attempts; append-only.
- **User (implicit)**
  - **DB table**: `auth.users` (managed by Supabase)
  - **Description**: Authenticated user identity; not exposed as a first-class REST resource in this plan, but used for scoping.

## 2. Endpoints

### 2.1. Flashcards

#### 2.1.1. List flashcards

- **HTTP method**: `GET`
- **Path**: `/api/flashcards`
- **Description**: List the authenticated user's flashcards with pagination, filtering, and sorting.
- **Query parameters**:
  - `page` (optional, integer, default `1`): 1-based page index. Mutually exclusive with `cursor`.
  - `pageSize` (optional, integer, default `50`, max `200`): Number of items per page.
  - `cursor` (optional, string): Opaque cursor for cursor-based pagination (e.g. encoded `id` / `created_at`). If provided, `page`/`pageSize` are ignored.
  - `generationId` (optional, integer): Filter by `flashcards.generation_id`.
  - `source` (optional, enum): One of `ai-full`, `ai-edited`, `manual`.
  - `search` (optional, string, max 200 chars): Case-insensitive substring search on `front` and `back`.
  - `sortBy` (optional, enum, default `created_at`): One of `created_at`, `updated_at`, `front`.
  - `sortOrder` (optional, enum, default `desc`): One of `asc`, `desc`.
- **Request body**: _None_
- **Response JSON structure** (`200 OK`):
  ```json
  {
    "items": [
      {
        "id": 123,
        "front": "string",
        "back": "string",
        "source": "ai-full | ai-edited | manual",
        "generationId": 42,
        "createdAt": "2025-11-19T12:34:56.000Z",
        "updatedAt": "2025-11-19T12:35:10.000Z"
      }
    ],
    "pagination": {
      "page": 1,
      "pageSize": 50,
      "totalItems": 1234,
      "totalPages": 25,
      "nextCursor": "opaque-string-or-null"
    }
  }
  ```
- **Success codes**:
  - `200 OK`: List returned.
- **Error codes**:
  - `401 Unauthorized`: Missing or invalid Supabase session.
  - `500 Internal Server Error`: Unexpected error.

#### 2.1.2. Get single flashcard

- **HTTP method**: `GET`
- **Path**: `/api/flashcards/{id}`
- **Description**: Fetch a single flashcard owned by the authenticated user.
- **Path parameters**:
  - `id` (integer): Flashcard primary key.
- **Request body**: _None_
- **Response JSON structure** (`200 OK`):
  ```json
  {
    "id": 123,
    "front": "string",
    "back": "string",
    "source": "ai-full | ai-edited | manual",
    "generationId": 42,
    "createdAt": "2025-11-19T12:34:56.000Z",
    "updatedAt": "2025-11-19T12:35:10.000Z"
  }
  ```
- **Success codes**:
  - `200 OK`: Flashcard found and returned.
- **Error codes**:
  - `401 Unauthorized`: Missing or invalid Supabase session.
  - `404 Not Found`: Flashcard does not exist or does not belong to the user (RLS-enforced).
  - `500 Internal Server Error`: Unexpected error.

#### 2.1.3. Create flashcard (manual or AI-accepted)

- **HTTP method**: `POST`
- **Path**: `/api/flashcards`
- **Description**: Create a single flashcard for the authenticated user. Used for fully manual cards and for persisting an accepted AI-generated card (when not using bulk-save).
- **Request JSON structure**:
  ```json
  {
    "front": "string (1-200 chars)",
    "back": "string (1-500 chars)",
    "source": "ai-full | ai-edited | manual",
    "generationId": 42
  }
  ```
  - `front`: Required, non-empty, max 200 chars.
  - `back`: Required, non-empty, max 500 chars.
  - `source`: Required; enum `[ai-full, ai-edited, manual]`. For manual cards, any `generationId` is ignored and must be `null`/omitted by validation.
  - `generationId`: Optional; required only when `source` is `ai-full` or `ai-edited`. Must reference an existing `generations.id` owned by the same user.
- **Response JSON structure** (`201 Created`):
  ```json
  {
    "id": 123,
    "front": "string",
    "back": "string",
    "source": "ai-full | ai-edited | manual",
    "generationId": 42,
    "createdAt": "2025-11-19T12:34:56.000Z",
    "updatedAt": "2025-11-19T12:34:56.000Z"
  }
  ```
- **Success codes**:
  - `201 Created`: Flashcard created.
- **Error codes**:
  - `400 Bad Request`: Payload missing required fields or has inconsistent combination (e.g. `source = manual` with non-null `generationId`).
  - `401 Unauthorized`: Missing or invalid session.
  - `404 Not Found`: `generationId` does not exist or does not belong to the user.
  - `500 Internal Server Error`: Unexpected error.

#### 2.1.5. Update flashcard

- **HTTP method**: `PATCH`
- **Path**: `/api/flashcards/{id}`
- **Description**: Partially update a flashcard (e.g. when user edits an AI-generated card). For AI-generated cards, updating the text should switch `source` to `ai-edited` if it was `ai-full`.
- **Path parameters**:
  - `id` (integer): Flashcard primary key.
- **Request JSON structure**:
  ```json
  {
    "front": "string (1-200 chars, optional)",
    "back": "string (1-500 chars, optional)"
  }
  ```
  - At least one of `front`, `back` must be present.
- **Response JSON structure** (`200 OK`):
  ```json
  {
    "id": 123,
    "front": "updated",
    "back": "updated",
    "source": "ai-edited | manual",
    "generationId": 42,
    "createdAt": "2025-11-19T12:34:56.000Z",
    "updatedAt": "2025-11-19T12:36:10.000Z"
  }
  ```
- **Success codes**:
  - `200 OK`: Flashcard updated.
- **Error codes**:
  - `400 Bad Request`: Empty payload.
  - `401 Unauthorized`: Missing or invalid session.
  - `404 Not Found`: Flashcard not found or not owned by the user.
  - `500 Internal Server Error`: Unexpected error.

#### 2.1.6. Delete flashcard

- **HTTP method**: `DELETE`
- **Path**: `/api/flashcards/{id}`
- **Description**: Delete a single flashcard.
- **Path parameters**:
  - `id` (integer): Flashcard primary key.
- **Request body**: _None_
- **Response JSON structure** (`204 No Content`):
  - Empty body.
- **Success codes**:
  - `204 No Content`: Flashcard deleted.
- **Error codes**:
  - `401 Unauthorized`: Missing or invalid session.
  - `404 Not Found`: Flashcard not found or not owned by the user.
  - `500 Internal Server Error`: Unexpected error.

### 2.2. AI Flashcard Generation

These endpoints encapsulate AI generation logic and tracking using the `generations` and `generation_error_logs` tables.

#### 2.2.1. Generate flashcards from source text

- **HTTP method**: `POST`
- **Path**: `/api/ai/generations`
- **Description**: Given a block of source text, invoke the AI model to propose a set of flashcards. On success, create a `generations` row with metadata and return proposed flashcards for user review. Flashcards are **not** persisted yet; they are saved via the bulk create endpoint after user acceptance.
- **Request JSON structure**:
  ```json
  {
    "sourceText": "string (1000-10000 chars)",
    "model": "gpt-5.1",
    "maxCards": 30
  }
  ```
  - `sourceText`: Required; length between 1000 and 10000 chars (mirrors DB `source_text_length` check constraint).
  - `model`: Optional; defaults to configured model identifier if omitted. Stored in `generations.model`.
  - `maxCards`: Optional; upper bound for number of generated cards (e.g. 5-100).
- **Response JSON structure** (`201 Created` on success):
  ```json
  {
    "generation": {
      "id": 42,
      "userId": "uuid",
      "model": "gpt-5.1",
      "generatedCount": 10,
      "acceptedUneditedCount": null,
      "acceptedEditedCount": null,
      "sourceTextHash": "hex-string",
      "sourceTextLength": 2345,
      "generationDuration": 1234,
      "createdAt": "2025-11-19T12:34:56.000Z",
      "updatedAt": "2025-11-19T12:34:56.000Z"
    },
    "proposedCards": [
      {
        "front": "string (1-200 chars)",
        "back": "string (1-500 chars)"
      }
    ]
  }
  ```
- **Success codes**:
  - `201 Created`: Generation metadata persisted and AI proposals returned.
- **Error codes**:
  - `400 Bad Request`: `sourceText` length outside [1000, 10000] or invalid `maxCards`.
  - `401 Unauthorized`: Missing or invalid session.
  - `422 Unprocessable Entity`: Other validation issues.
  - `429 Too Many Requests`: Rate limiting for generation endpoint.
  - `500 Internal Server Error`: Unexpected error. Implementation SHOULD also:
    - Insert a row into `generation_error_logs` with `error_code` and `error_message` when AI provider / validation fails.

#### 2.2.2. List generations

- **HTTP method**: `GET`
- **Path**: `/api/generations`
- **Description**: List AI generation runs for the authenticated user; useful for analytics and debugging.
- **Query parameters**:
  - `page` / `pageSize` / `cursor`: Same semantics as `/api/flashcards`.
  - `model` (optional, string): Filter by model identifier.
  - `createdFrom` / `createdTo` (optional, ISO timestamps): Filter by creation date range.
- **Response JSON structure** (`200 OK`):
  ```json
  {
    "items": [
      {
        "id": 42,
        "model": "gpt-5.1",
        "generatedCount": 10,
        "acceptedUneditedCount": 5,
        "acceptedEditedCount": 3,
        "sourceTextHash": "hex-string",
        "sourceTextLength": 2345,
        "generationDuration": 1234,
        "createdAt": "2025-11-19T12:34:56.000Z",
        "updatedAt": "2025-11-19T12:35:10.000Z"
      }
    ],
    "pagination": {
      "page": 1,
      "pageSize": 50,
      "totalItems": 10,
      "totalPages": 1,
      "nextCursor": null
    }
  }
  ```
- **Success codes**:
  - `200 OK`: List returned.
- **Error codes**:
  - `401 Unauthorized`: Missing or invalid session.
  - `422 Unprocessable Entity`: Invalid query parameters.
  - `500 Internal Server Error`: Unexpected error.

#### 2.2.3. Get generation details + its flashcards

- **HTTP method**: `GET`
- **Path**: `/api/generations/{id}`
- **Description**: Fetch a single generation row and the user's flashcards associated with it.
- **Path parameters**:
  - `id` (integer): Generation primary key.
- **Query parameters**:
  - `includeFlashcards` (optional, boolean, default `true`): Whether to include associated flashcards.
- **Response JSON structure** (`200 OK`):
  ```json
  {
    "generation": {
      "id": 42,
      "model": "gpt-5.1",
      "generatedCount": 10,
      "acceptedUneditedCount": 5,
      "acceptedEditedCount": 3,
      "sourceTextHash": "hex-string",
      "sourceTextLength": 2345,
      "generationDuration": 1234,
      "createdAt": "2025-11-19T12:34:56.000Z",
      "updatedAt": "2025-11-19T12:35:10.000Z"
    },
    "flashcards": [
      {
        "id": 123,
        "front": "string",
        "back": "string",
        "source": "ai-full | ai-edited",
        "generationId": 42,
        "createdAt": "2025-11-19T12:34:56.000Z",
        "updatedAt": "2025-11-19T12:35:10.000Z"
      }
    ]
  }
  ```
- **Success codes**:
  - `200 OK`: Generation (and optionally flashcards) returned.
- **Error codes**:
  - `401 Unauthorized`: Missing or invalid session.
  - `404 Not Found`: Generation not found or not owned by the user.
  - `500 Internal Server Error`: Unexpected error.

#### 2.2.4. Update generation acceptance statistics

- **HTTP method**: `PATCH`
- **Path**: `/api/generations/{id}/stats`
- **Description**: Update `accepted_unedited_count` and `accepted_edited_count` for a generation after the user confirms which generated cards they accepted/edited. This endpoint is optional if the bulk create endpoint is defined to update these stats transactionally; but it can be useful for decoupled flows.
- **Path parameters**:
  - `id` (integer): Generation primary key.
- **Request JSON structure**:
  ```json
  {
    "acceptedUneditedCount": 5,
    "acceptedEditedCount": 3
  }
  ```
  - At least one of the fields must be provided.
  - Sum of provided fields must not exceed `generatedCount`.
- **Response JSON structure** (`200 OK`):
  ```json
  {
    "id": 42,
    "model": "gpt-5.1",
    "generatedCount": 10,
    "acceptedUneditedCount": 5,
    "acceptedEditedCount": 3,
    "sourceTextHash": "hex-string",
    "sourceTextLength": 2345,
    "generationDuration": 1234,
    "createdAt": "2025-11-19T12:34:56.000Z",
    "updatedAt": "2025-11-19T12:36:10.000Z"
  }
  ```
- **Success codes**:
  - `200 OK`: Statistics updated.
- **Error codes**:
  - `400 Bad Request`: Invalid combination of counts.
  - `401 Unauthorized`: Missing or invalid session.
  - `404 Not Found`: Generation not found or not owned by the user.
  - `422 Unprocessable Entity`: Field-level validation errors.
  - `500 Internal Server Error`: Unexpected error.

### 2.3. Generation Error Logs

These endpoints are primarily for internal tooling and diagnostics. They are user-scoped by RLS; depending on PRD they could be hidden from end users or exposed in a limited way.

#### 2.3.1. List generation error logs

- **HTTP method**: `GET`
- **Path**: `/api/generation-error-logs`
- **Description**: List error logs for AI generation attempts belonging to the authenticated user.
- **Query parameters**:
  - `page` / `pageSize` / `cursor`: Same semantics as `/api/flashcards`.
  - `model` (optional, string): Filter by model.
  - `errorCode` (optional, string, max 100 chars): Filter by `error_code`.
  - `createdFrom` / `createdTo` (optional, ISO timestamps): Filter by `created_at` range.
- **Response JSON structure** (`200 OK`):
  ```json
  {
    "items": [
      {
        "id": 1,
        "userId": "uuid",
        "model": "gpt-5.1",
        "sourceTextHash": "hex-string",
        "sourceTextLength": 2345,
        "errorCode": "validation_error",
        "errorMessage": "human-readable message (truncated/sanitized if needed)",
        "createdAt": "2025-11-19T12:34:56.000Z"
      }
    ],
    "pagination": {
      "page": 1,
      "pageSize": 50,
      "totalItems": 3,
      "totalPages": 1,
      "nextCursor": null
    }
  }
  ```
- **Success codes**:
  - `200 OK`: List returned.
- **Error codes**:
  - `401 Unauthorized`: Missing or invalid session.
  - `422 Unprocessable Entity`: Invalid query parameters.
  - `500 Internal Server Error`: Unexpected error.

#### 2.3.2. Get single generation error log

- **HTTP method**: `GET`
- **Path**: `/api/generation-error-logs/{id}`
- **Description**: Fetch a single generation error log entry.
- **Path parameters**:
  - `id` (integer): Error log primary key.
- **Response JSON structure** (`200 OK`):
  ```json
  {
    "id": 1,
    "userId": "uuid",
    "model": "gpt-5.1",
    "sourceTextHash": "hex-string",
    "sourceTextLength": 2345,
    "errorCode": "validation_error",
    "errorMessage": "human-readable message",
    "createdAt": "2025-11-19T12:34:56.000Z"
  }
  ```
- **Success codes**:
  - `200 OK`: Error log returned.
- **Error codes**:
  - `401 Unauthorized`: Missing or invalid session.
  - `404 Not Found`: Error log not found or not owned by the user.
  - `500 Internal Server Error`: Unexpected error.

> Note: There is intentionally **no** public endpoint for creating error logs; they are created internally by the AI generation endpoint when failures occur.

## 3. Authentication and Authorization

- **Authentication mechanism**:
  - Supabase Auth with JWT-based sessions stored in cookies (managed by Supabase and Next.js middleware).
  - Route handlers in `app/api/**/route.ts` will create a Supabase server client via `@supabase/ssr` using the request's cookies and rely on Supabase RLS for data isolation.
- **Authorization model**:
  - All domain tables (`flashcards`, `generations`, `generation_error_logs`) enforce Row Level Security (`enable row level security` + `force row level security`).
  - RLS policies restrict access to rows where `user_id = auth.uid()` for `select`, `insert`, `update`, `delete`.
  - The `anon` role has no direct access; only `authenticated` users can operate on these tables.
- **API-level checks**:
  - Each handler MUST verify that a user is present (`supabase.auth.getUser()` in middleware or route) before performing any DB operation.
  - Handlers SHOULD **not** accept an explicit `userId` from the client; instead they rely on `auth.uid()` in SQL / Supabase client to scope data.
  - For endpoints referencing foreign keys (e.g. `generationId`), handlers must validate that the related record exists; RLS ensures it cannot belong to another user.
- **Session handling**:
  - Follow the `.cursor/rules` guidance: use `@supabase/ssr` with `cookies.getAll` / `cookies.setAll`, never individual `get`/`set`/`remove` and never `@supabase/auth-helpers-nextjs`.

## 4. Validation and Business Logic

### 4.1. Flashcards

- **Field validation**:
  - `front`:
    - Required on create; optional on update.
    - Trimmed string length: `1-200` characters (aligned with `varchar(200)`).
  - `back`:
    - Required on create; optional on update.
    - Trimmed string length: `1-500` characters (aligned with `varchar(500)`).
  - `source`:
    - Required on create; optional on update.
    - Enum: `ai-full`, `ai-edited`, `manual` (mirrors DB `check (source in (...))`).
  - `generationId`:
    - Optional; when provided, must be a positive integer.
    - When `source = manual`, must be `null` / omitted; handler should reject inconsistent combinations with `400 Bad Request`.
- **Business rules**:
  - Creating or updating a flashcard MUST always set `user_id = auth.uid()`; the API should not allow impersonation.
  - Updating text of a card with `source = ai-full` should change `source` to `ai-edited` automatically (unless the caller explicitly sets it).
  - Deletion is physical; there is no soft-delete field in the current schema.
  - `updated_at` is maintained by a DB trigger; handlers should **not** attempt to override it.

### 4.2. Generations

- **Field validation**:
  - `model`:
    - Non-empty string; may be validated against a whitelist (e.g. `"gpt-5.1"`, `"gpt-4.1-mini"`).
  - `generatedCount`:
    - Positive integer (`>= 1`); equals the number of AI-proposed cards returned from the provider.
  - `acceptedUneditedCount` / `acceptedEditedCount`:
    - Integers `>= 0` or `null` initially.
    - When both present, must satisfy `acceptedUneditedCount + acceptedEditedCount <= generatedCount`.
  - `sourceTextHash`:
    - Non-empty hex string; application computes it (e.g. SHA-256) from `sourceText`.
  - `sourceTextLength`:
    - Integer in `[1000, 10000]` as enforced by DB `check (source_text_length between 1000 and 10000)`.
  - `generationDuration`:
    - Non-negative integer in milliseconds.
- **Business rules**:
  - A `generations` row is created only after the AI provider call returns successfully (or after minimal validation passes, depending on desired semantics).
  - If the same `sourceTextHash` is submitted repeatedly, the API MAY deduplicate by returning previous results (optional optimization).
  - Acceptance statistics are updated either via:
    - The bulk create endpoint (in the same transaction as flashcard insertion), or
    - The stats update endpoint (`PATCH /api/generations/{id}/stats`).
  - Users cannot directly delete or update critical fields like `sourceTextHash` or `sourceTextLength` from the API; any such endpoints must be internal-only.

### 4.3. Generation Error Logs

- **Field validation**:
  - `model`: Required, non-empty string.
  - `sourceTextHash`: Required, non-empty hex string.
  - `sourceTextLength`: Required integer in `[1000, 10000]`.
  - `errorCode`:
    - Required string; length `1-100` chars (aligned with `varchar(100)`).
    - Application SHOULD constrain this to a known set (e.g. `validation_error`, `provider_timeout`, `provider_error`, `rate_limited`).
  - `errorMessage`:
    - Required non-empty string; may be truncated or sanitized before writing to DB to avoid leaking provider internals.
- **Business rules**:
  - Error logs are created only internally by the AI generation endpoint or by background workers; there is no public `POST` endpoint.
  - Logs are append-only; there are no update endpoints.
  - Users see only their own logs due to RLS; an additional admin-only path could bypass this if needed (not part of MVP).

### 4.4. AI Generation Flow

- **End-to-end steps**:
  1. User sends `POST /api/ai/flashcard-generations` with `sourceText`.
  2. API:
     - Validates `sourceText` length and other fields.
     - Computes `sourceTextHash` and `sourceTextLength`.
     - Calls external AI provider with a safe prompt template and `maxCards`.
     - Measures `generationDuration`.
     - On success:
       - Inserts a row into `generations` with `generatedCount = proposedCards.length`, `accepted_* = null`.
       - Returns the `generation` row and `proposedCards` array.
     - On failure:
       - Inserts a row into `generation_error_logs` with appropriate `error_code` and `error_message`.
       - Returns `4xx` (validation/usage) or `5xx` (provider/system) as appropriate.
  3. Frontend lets user accept/edit cards; when confirmed, it calls `POST /api/flashcards/bulk` with `generationId`, chosen `cards`, and optional stats.
- **Business KPIs alignment**:
  - The combination of `generatedCount` versus `acceptedUneditedCount + acceptedEditedCount` enables computation of “percentage of AI-generated flashcards accepted” as required in PRD.
  - The split between `ai-full` and `ai-edited` cards allows measurement of how often users edit AI content before acceptance.

### 4.5. Pagination, Filtering, Sorting

- **Pagination strategy**:
  - All list endpoints (`/flashcards`, `/generations`, `/generation-error-logs`) support both page-based (`page`/`pageSize`) and cursor-based (`cursor`, `limit`) pagination.
  - Cursor-based pagination is preferred in the UI for large data sets; the API computes cursors using `id` or `(created_at, id)` pairs encoded as opaque strings.
- **Filtering**:
  - Filters are always scoped to the authenticated user's data (RLS enforced).
  - Inputs are strictly validated (e.g. enums, max string lengths) to avoid unbounded / slow queries.
- **Sorting**:
  - Sortable fields are whitelisted per endpoint.
  - Unsupported `sortBy` values return `422 Unprocessable Entity`.

### 4.6. Rate Limiting and Security

- **Rate limiting**:
  - AI generation endpoint `/api/ai/flashcard-generations`:
    - Per-user and per-IP limits (e.g. 10 requests / 5 minutes).
    - On exceeding, return `429 Too Many Requests` with a generic message.
  - Non-AI CRUD endpoints can have looser limits but still guarded to prevent abuse.
- **Input security**:
  - All text inputs (`sourceText`, `front`, `back`, `errorMessage`) must be:
    - Length-limited.
    - Sanitized/escaped before rendering in any HTML context.
  - The API must not log full `sourceText` to application logs; only hashes and lengths.
- **Data isolation**:
  - RLS ensures per-user isolation at DB level.
  - API should never expose `user_id` other than the caller’s own ID (and even that only where necessary).
- **Error handling**:
  - User-facing error messages are generic; internal details go into `generation_error_logs` or system logs.
  - 5xx responses should avoid leaking provider error payloads.
