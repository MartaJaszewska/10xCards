# REST API Plan for 10xCards

## Overview

This document describes the REST API for 10xCards, a web application for creating and managing flashcards with AI-powered generation.

**Base URL:** `/api` (application endpoints) and `/auth/v1` (Supabase Auth endpoints)

<!-- **Authentication:** Bearer token (JWT) via Supabase Auth -->

## Quick Reference - All Endpoints

<!--
### Authentication (Supabase Auth)

- `POST /auth/v1/signup` - Register new user
- `POST /auth/v1/token?grant_type=password` - Login
- `POST /auth/v1/logout` - Logout
- `PUT /auth/v1/user` - Change password
- `DELETE /auth/v1/user` - Delete account -->

### Flashcards

- `GET /api/flashcards` - List flashcards (with pagination and search)
- `GET /api/flashcards/:id` - Get single flashcard
- `POST /api/flashcards` - Create flashcards (batch)
- `PUT /api/flashcards/:id` - Update flashcard
- `DELETE /api/flashcards/:id` - Delete flashcard

### Generations

- `POST /api/generations` - Generate flashcard proposals from text
- `GET /api/generations` - Get generation history
- `GET /api/generations/:id` - Get generation details
- `GET /api/generation-error-logs` - Get generation error logs

## 1. Resources

### 1.1 Core Resources

| Resource          | Database Table          | Description                             |
| ----------------- | ----------------------- | --------------------------------------- |
| Authentication    | `auth.users`            | User account management (Supabase Auth) |
| Flashcards        | `flashcards`            | User's learning flashcards              |
| Generations       | `generations`           | AI generation session logs              |
| Generation Errors | `generation_error_logs` | Failed AI generation attempts           |

## 2. Endpoints

<!-- ### 2.1 Authentication Endpoints (Supabase Auth)

These endpoints are provided by Supabase Auth and should be used directly.

#### 2.1.1 Register User

**Endpoint:** `POST /auth/v1/signup`

**Description:** Creates a new user account with email and password.

**Request Body:**

```json
{
  "email": "user@example.com",
  "password": "SecureP@ssw0rd"
}
```

**Success Response (200 OK):**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "...",
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com",
    "created_at": "2025-11-19T12:00:00Z"
  }
}
```

**Error Responses:**

- `400 Bad Request` - Invalid email format or password requirements not met
- `422 Unprocessable Entity` - Email already registered

#### 2.1.2 Login

**Endpoint:** `POST /auth/v1/token?grant_type=password`

**Description:** Authenticates user and returns access token.

**Request Body:**

```json
{
  "email": "user@example.com",
  "password": "SecureP@ssw0rd"
}
```

**Success Response (200 OK):**

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": 3600,
  "refresh_token": "...",
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com"
  }
}
```

**Error Responses:**

- `400 Bad Request` - Invalid credentials

#### 2.1.3 Logout

**Endpoint:** `POST /auth/v1/logout`

**Description:** Invalidates the current session.

**Headers:**

```
Authorization: Bearer {access_token}
```

**Success Response (204 No Content)**

**Error Responses:**

- `401 Unauthorized` - Invalid or expired token

#### 2.1.4 Change Password

**Endpoint:** `PUT /auth/v1/user`

**Description:** Updates user's password.

**Headers:**

```
Authorization: Bearer {access_token}
```

**Request Body:**

```json
{
  "password": "NewSecureP@ssw0rd"
}
```

**Success Response (200 OK):**

```json
{
  "user": {
    "id": "123e4567-e89b-12d3-a456-426614174000",
    "email": "user@example.com",
    "updated_at": "2025-11-19T12:30:00Z"
  }
}
```

**Error Responses:**

- `401 Unauthorized` - Invalid token
- `400 Bad Request` - Password requirements not met

#### 2.1.5 Delete Account

**Endpoint:** `DELETE /auth/v1/user`

**Description:** Permanently deletes user account and all associated data (cascades to flashcards, generations, and error logs).

**Headers:**

```
Authorization: Bearer {access_token}
```

**Success Response (204 No Content)**

**Error Responses:**

- `401 Unauthorized` - Invalid token -->

### 2.2 Flashcard Endpoints

All flashcard endpoints require authentication via `Authorization: Bearer {access_token}` header.

#### 2.2.1 List Flashcards

**Endpoint:** `GET /api/flashcards`

**Description:** Retrieves paginated list of user's flashcards with optional search filtering.

**Query Parameters:**

- `page` (integer, optional, default: 1) - Page number
- `limit` (integer, optional, default: 20, max: 100) - Items per page
- `search` (string, optional) - Case-insensitive substring search on `front` field

**Example Request:**

```
GET /api/flashcards?page=1&limit=20&search=javascript
```

**Success Response (200 OK):**

```json
{
  "data": [
    {
      "id": 1,
      "front": "What is JavaScript closure?",
      "back": "A closure is a function that has access to variables in its outer scope, even after the outer function has returned.",
      "source": "ai-full",
      "generation_id": 42,
      "created_at": "2025-11-19T12:00:00Z",
      "updated_at": "2025-11-19T12:00:00Z"
    },
    {
      "id": 2,
      "front": "JavaScript event loop",
      "back": "The event loop handles asynchronous callbacks by continuously checking the call stack and callback queue.",
      "source": "manual",
      "generation_id": null,
      "created_at": "2025-11-18T10:30:00Z",
      "updated_at": "2025-11-18T10:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total_items": 45,
    "total_pages": 3,
    "has_next": true,
    "has_previous": false
  }
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token
- `400 Bad Request` - Invalid query parameters

#### 2.2.2 Get Single Flashcard

**Endpoint:** `GET /api/flashcards/:id`

**Description:** Retrieves a specific flashcard by ID.

**Success Response (200 OK):**

```json
{
  "id": 1,
  "front": "What is JavaScript closure?",
  "back": "A closure is a function that has access to variables in its outer scope, even after the outer function has returned.",
  "source": "ai-full",
  "generation_id": 42,
  "created_at": "2025-11-19T12:00:00Z",
  "updated_at": "2025-11-19T12:00:00Z"
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - Flashcard doesn't exist or doesn't belong to user

#### 2.2.3 Create Flashcards

**Endpoint:** `POST /api/flashcards`

**Description:** Creates one or more flashcards. Supports both single flashcard creation (manual) and batch creation (accepting multiple AI-generated candidates).

**Request Body (Single):**

```json
{
  "flashcards": [
    {
      "front": "What is TypeScript?",
      "back": "TypeScript is a strongly typed programming language that builds on JavaScript.",
      "source": "manual",
      "generation_id": null
    }
  ]
}
```

**Request Body (Batch - accepting AI candidates):**

```json
{
  "flashcards": [
    {
      "front": "Generated question 1",
      "back": "Generated answer 1",
      "source": "ai-full",
      "generation_id": 42
    },
    {
      "front": "Edited question 2",
      "back": "Edited answer 2",
      "source": "ai-edited",
      "generation_id": 42
    },
    {
      "front": "Generated question 3",
      "back": "Generated answer 3",
      "source": "ai-full",
      "generation_id": 42
    }
  ]
}
```

**Validation Rules:**

- `flashcards`: Required, array of 1-10 flashcard objects
- `front`: Required, 1-200 characters
- `back`: Required, 1-500 characters
- `source`: Required, must be one of: "manual", "ai-full", "ai-edited"
- `generation_id`: Optional, must reference valid generation if provided

**Success Response (201 Created):**

```json
{
  "flashcards": [
    {
      "id": 123,
      "front": "What is TypeScript?",
      "back": "TypeScript is a strongly typed programming language that builds on JavaScript.",
      "source": "manual",
      "generation_id": null,
      "created_at": "2025-11-19T13:00:00Z",
      "updated_at": "2025-11-19T13:00:00Z"
    },
    {
      "id": 124,
      "front": "Edited question 2",
      "back": "Edited answer 2",
      "source": "ai-edited",
      "generation_id": 42,
      "created_at": "2025-11-19T13:00:01Z",
      "updated_at": "2025-11-19T13:00:01Z"
    }
  ]
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token
- `400 Bad Request` - Validation failed for any flashcard in the array
- `422 Unprocessable Entity` - Invalid generation_id or source value

#### 2.2.4 Update Flashcard

**Endpoint:** `PUT /api/flashcards/:id`

**Description:** Updates an existing flashcard. The `source` and `generation_id` fields are not modified during updates.

**Request Body:**

```json
{
  "front": "Updated question text",
  "back": "Updated answer text"
}
```

**Validation Rules:**

- `front`: Required, 1-200 characters
- `back`: Required, 1-500 characters

**Success Response (200 OK):**

```json
{
  "id": 123,
  "front": "Updated question text",
  "back": "Updated answer text",
  "source": "manual",
  "generation_id": null,
  "created_at": "2025-11-19T13:00:00Z",
  "updated_at": "2025-11-19T13:30:00Z"
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - Flashcard doesn't exist or doesn't belong to user
- `400 Bad Request` - Validation failed

#### 2.2.5 Delete Flashcard

**Endpoint:** `DELETE /api/flashcards/:id`

**Description:** Permanently deletes a flashcard (hard delete, no recovery).

**Success Response (204 No Content)**

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - Flashcard doesn't exist or doesn't belong to user

### 2.3 Generation Endpoints

#### 2.3.1 Generate Flashcards

**Endpoint:** `POST /api/generations`

**Description:** Initiates AI generation process for flashcard proposals based on user-provided text.

**Request Body:**

```json
{
  "source_text": "Long text content between 1000 and 10000 characters..."
}
```

**Validation Rules:**

- `source_text`: Required, 1000-10000 characters

**Success Response (200 OK):**

```json
{
  "generation_id": 42,
  "flashcards_proposals": [
    {
      "front": "What is the main concept?",
      "back": "The main concept is...",
      "source": "ai-full"
    },
    {
      "front": "How does X work?",
      "back": "X works by...",
      "source": "ai-full"
    }
  ],
  "generated_count": 8,
  "source_text_length": 5432,
  "generation_duration": 3421,
  "created_at": "2025-11-19T14:00:00Z"
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token
- `400 Bad Request` - Source text length outside 1000-10000 range
- `503 Service Unavailable` - AI service timeout or error
- `429 Too Many Requests` - Rate limit exceeded (if implemented)

**Error Response Format (AI Error):**

```json
{
  "error": "generation_failed",
  "message": "AI service is temporarily unavailable",
  "error_log_id": 15
}
```

**Note:** When generation fails, an error log is created in `generation_error_logs` table with details.

#### 2.3.2 Get Generation Details

**Endpoint:** `GET /api/generations/:id`

**Description:** Retrieves detailed information about a specific generation including its associated flashcards.

**Success Response (200 OK):**

```json
{
  "id": 42,
  "model": "openai/gpt-4",
  "generated_count": 8,
  "accepted_unedited_count": 5,
  "accepted_edited_count": 2,
  "source_text_length": 5432,
  "generation_duration": 3421,
  "created_at": "2025-11-19T14:00:00Z",
  "flashcards": [
    {
      "id": 101,
      "front": "Question 1",
      "back": "Answer 1",
      "source": "ai-full",
      "created_at": "2025-11-19T14:05:00Z"
    },
    {
      "id": 102,
      "front": "Question 2",
      "back": "Answer 2",
      "source": "ai-edited",
      "created_at": "2025-11-19T14:05:01Z"
    }
  ]
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token
- `404 Not Found` - Generation doesn't exist or doesn't belong to user

**Note:** The `accepted_unedited_count` and `accepted_edited_count` are calculated automatically by counting flashcards with `generation_id` matching this generation:

```sql
SELECT
  COUNT(*) FILTER (WHERE source = 'ai-full') as accepted_unedited_count,
  COUNT(*) FILTER (WHERE source = 'ai-edited') as accepted_edited_count
FROM flashcards
WHERE generation_id = :id AND user_id = auth.uid();
```

#### 2.3.3 Get User Generation History

**Endpoint:** `GET /api/generations`

**Description:** Retrieves user's generation history for analytics purposes.

**Query Parameters:**

- `page` (integer, optional, default: 1)
- `limit` (integer, optional, default: 20, max: 100)

**Success Response (200 OK):**

```json
{
  "data": [
    {
      "id": 42,
      "model": "openai/gpt-4",
      "generated_count": 8,
      "accepted_unedited_count": 5,
      "accepted_edited_count": 2,
      "source_text_length": 5432,
      "generation_duration": 3421,
      "created_at": "2025-11-19T14:00:00Z",
      "acceptance_rate": 0.875
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total_items": 15,
    "total_pages": 1,
    "has_next": false,
    "has_previous": false
  },
  "summary": {
    "total_generations": 15,
    "total_candidates_generated": 120,
    "total_accepted_unedited": 85,
    "total_accepted_edited": 20,
    "overall_acceptance_rate": 0.875
  }
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token
- `400 Bad Request` - Invalid query parameters

#### 2.3.4 Get Generation Error Logs

**Endpoint:** `GET /api/generation-error-logs`

**Description:** Retrieves error logs for AI flashcard generation for the authenticated user (or admin).

**Query Parameters:**

- `page` (integer, optional, default: 1)
- `limit` (integer, optional, default: 20, max: 100)

**Success Response (200 OK):**

```json
{
  "data": [
    {
      "id": 15,
      "model": "openai/gpt-4",
      "source_text_length": 5432,
      "error_code": "timeout",
      "error_message": "AI service request timed out after 30 seconds",
      "created_at": "2025-11-19T14:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total_items": 3,
    "total_pages": 1,
    "has_next": false,
    "has_previous": false
  }
}
```

**Error Responses:**

- `401 Unauthorized` - Missing or invalid token

## 3. Authentication and Authorization

### 3.1 Authentication Mechanism

**Provider:** Supabase Auth

**Method:** JWT (JSON Web Token) via Bearer token in Authorization header

**Token Format:**

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 3.2 Token Management

- **Access Token Expiry:** 3600 seconds (1 hour)
- **Refresh Token:** Used to obtain new access tokens without re-authentication
- **Token Storage:** Client-side (secure HTTP-only cookies recommended for production)

### 3.3 Row-Level Security (RLS)

**Implementation:** Supabase RLS policies on all domain tables

**Policy Rules:**

- Users can only read, create, update, and delete their own records
- All queries automatically filtered by `user_id = auth.uid()`
- Enforced at database level, not application level

**RLS Policies:**

```sql
-- flashcards table
CREATE POLICY "Users can view own flashcards"
  ON flashcards FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own flashcards"
  ON flashcards FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own flashcards"
  ON flashcards FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own flashcards"
  ON flashcards FOR DELETE
  USING (auth.uid() = user_id);

-- Similar policies for generations and generation_error_logs
```

### 3.4 Protected Endpoints

All endpoints under `/api/*` require valid authentication token, except:

- Health check endpoints (if implemented)
- Public documentation endpoints (if implemented)

### 3.5 Error Responses for Authentication

**401 Unauthorized:**

```json
{
  "error": "unauthorized",
  "message": "Authentication required"
}
```

**403 Forbidden:**

```json
{
  "error": "forbidden",
  "message": "You don't have permission to access this resource"
}
```

## 4. Validation and Business Logic

### 4.1 Flashcard Validation Rules

#### Field Constraints

- `front`:

  - Required for creation
  - Type: string
  - Min length: 1 character
  - Max length: 200 characters
  - Cannot be empty or whitespace only

- `back`:

  - Required for creation
  - Type: string
  - Min length: 1 character
  - Max length: 500 characters
  - Cannot be empty or whitespace only

- `source`:

  - Required for creation
  - Type: enum
  - Allowed values: "manual", "ai-full", "ai-edited"
  - Cannot be modified after creation

- `generation_id`:
  - Optional
  - Type: integer (bigint)
  - Must reference existing generation belonging to user
  - Can be null for manual flashcards
  - Set to null on cascade if generation is deleted

#### Business Rules

1. **Manual Creation:** When source is "manual", generation_id must be null
2. **AI Acceptance:** When source is "ai-full" or "ai-edited", generation_id should be provided
3. **Immutable Source:** The source field cannot be changed via update endpoint
4. **User Ownership:** user_id is automatically set from auth token, not from request body
5. **Timestamps:** created_at and updated_at are managed automatically by database

### 4.2 Generation Validation Rules

#### Input Text Constraints

- `source_text`:
  - Required
  - Type: string
  - Min length: 1000 characters
  - Max length: 10000 characters
  - Plain text only (HTML/markdown stripped before processing)

#### Generation Limits

- **Max Candidates:** Up to 10 flashcard candidates per generation
- **Min Candidates:** At least 1 candidate (but can be less if AI determines insufficient content)
- **Timeout:** 30 seconds max for AI response

#### Business Rules

1. **Hash Calculation:** source_text_hash calculated using SHA-256 for duplicate detection
2. **Duration Tracking:** generation_duration recorded in milliseconds
3. **Atomic Operation:** Generation record created before AI call, updated after
4. **Error Logging:** Failed generations logged to generation_error_logs table
5. **Model Selection:** Default model used if not specified

### 4.3 Search and Pagination Logic

#### Search Implementation

- **Field:** Searches only `front` field
- **Method:** Case-insensitive substring match (ILIKE '%search%')
- **Performance:** Index on flashcards.front for faster searching
- **Combination:** Search filter applied before pagination

#### Pagination Implementation

- **Method:** Offset-based pagination
- **Default Page Size:** 20 items
- **Max Page Size:** 100 items
- **Sort Order:** Default DESC by created_at (newest first)
- **Total Count:** Included in response for UI pagination controls

#### Query Example

```sql
SELECT * FROM flashcards
WHERE user_id = auth.uid()
  AND (front ILIKE '%search_term%' OR :search IS NULL)
ORDER BY created_at DESC
LIMIT :limit OFFSET (:page - 1) * :limit;
```

### 4.4 Deletion Logic

#### Flashcard Deletion

- **Type:** Hard delete (permanent)
- **Confirmation:** Required in UI before API call
- **Cascade:** No cascade effects (generation record remains)
- **Recovery:** Not possible (no soft delete)

#### Account Deletion

- **Type:** Hard delete (permanent)
- **Cascade:** Automatically deletes all user's:
  - Flashcards
  - Generations
  - Generation error logs
- **Implementation:** Database ON DELETE CASCADE
- **Confirmation:** Required in UI with strong warning

### 4.5 Generation Statistics Calculation Logic

#### Acceptance Tracking

- **Method:** Statistics are calculated dynamically from flashcards table, not stored separately
- **Counters:**
  - `accepted_unedited_count`: COUNT of flashcards with `generation_id` and `source = "ai-full"`
  - `accepted_edited_count`: COUNT of flashcards with `generation_id` and `source = "ai-edited"`
- **Calculation:** Acceptance rate = (accepted_unedited + accepted_edited) / generated_count

#### SQL Query for Statistics

```sql
SELECT
  g.*,
  COUNT(*) FILTER (WHERE f.source = 'ai-full') as accepted_unedited_count,
  COUNT(*) FILTER (WHERE f.source = 'ai-edited') as accepted_edited_count
FROM generations g
LEFT JOIN flashcards f ON f.generation_id = g.id
WHERE g.id = :id AND g.user_id = auth.uid()
GROUP BY g.id;
```

**Benefits of this approach:**

- No need for separate update endpoint
- Statistics always accurate and up-to-date
- Simpler implementation and fewer potential bugs
- No risk of statistics getting out of sync with actual flashcards

**Database Schema Note:**
The `accepted_unedited_count` and `accepted_edited_count` columns in the `generations` table are NULLABLE. For MVP, these can remain NULL and statistics calculated dynamically. In future optimizations, these could be populated as cache for faster queries on large datasets.

### 4.6 Error Handling

#### Client Errors (4xx)

- **400 Bad Request:** Invalid input data, validation failures
- **401 Unauthorized:** Missing or invalid authentication token
- **403 Forbidden:** Valid token but insufficient permissions
- **404 Not Found:** Resource doesn't exist or doesn't belong to user
- **422 Unprocessable Entity:** Semantic errors (e.g., invalid enum values)
- **429 Too Many Requests:** Rate limit exceeded

#### Server Errors (5xx)

- **500 Internal Server Error:** Unexpected server error
- **503 Service Unavailable:** AI service timeout or unavailable
- **504 Gateway Timeout:** Request timeout

#### Error Response Format

```json
{
  "error": "error_code",
  "message": "Human-readable error message",
  "details": {
    "field": "Additional context if applicable"
  }
}
```

### 4.7 Rate Limiting (Future Implementation)

**Recommendation for Production:**

- Generation endpoint: 10 requests per hour per user
- Flashcard CRUD: 100 requests per minute per user
- Implementation: Redis-based sliding window counter

### 4.8 Validation Error Examples

#### Flashcard Validation Error

```json
{
  "error": "validation_failed",
  "message": "Input validation failed",
  "details": {
    "front": "Front text cannot exceed 200 characters",
    "back": "Back text is required"
  }
}
```

#### Generation Validation Error

```json
{
  "error": "validation_failed",
  "message": "Source text length must be between 1000 and 10000 characters",
  "details": {
    "source_text_length": 523,
    "min_length": 1000,
    "max_length": 10000
  }
}
```

## 5. API Versioning

**Current Version:** v1 (implicit)

**Future Versioning Strategy:**

- URL versioning: `/api/v2/flashcards`
- Maintain backwards compatibility for at least one major version
- Deprecation notices in response headers

## 6. Response Headers

**Standard Headers for All Responses:**

```
Content-Type: application/json
X-Request-ID: {unique-request-id}
```

**For Paginated Responses:**

```
X-Total-Count: {total_items}
X-Page: {current_page}
X-Per-Page: {items_per_page}
```

## 7. CORS Configuration

**Allowed Origins:**

- Production: `https://10xcards.vercel.app`
- Development: `http://localhost:3000`

**Allowed Methods:** GET, POST, PUT, DELETE, OPTIONS

**Allowed Headers:** Content-Type, Authorization

## 8. Health Check Endpoint (Optional)

**Endpoint:** `GET /api/health`

**Description:** Returns API health status (no authentication required).

**Success Response (200 OK):**

```json
{
  "status": "healthy",
  "timestamp": "2025-11-19T15:00:00Z",
  "version": "1.0.0"
}
```
