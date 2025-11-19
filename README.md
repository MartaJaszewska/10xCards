## Project name

10x Cards

![Version](https://img.shields.io/badge/version-0.1.0-blue.svg)  
![Build](https://img.shields.io/badge/build-GitHub%20Actions-lightgrey.svg)  
![Status](https://img.shields.io/badge/status-MVP%20in%20progress-yellow.svg)  
![License](https://img.shields.io/badge/license-TBD-lightgrey.svg)

---

### Table of contents

- [Project name](#project-name)
- [Project description](#project-description)
- [Tech stack](#tech-stack)
- [Getting started locally](#getting-started-locally)
- [Available scripts](#available-scripts)
- [Project scope](#project-scope)
- [Project status](#project-status)
- [License](#license)

---

## Project description

**10x Cards** is a minimal web application for learning with flashcards, designed to drastically reduce the time needed to create high‑quality cards by leveraging AI on top of plain text input.

Manually preparing good flashcards is slow, tedious, and error‑prone – people either over-copy large chunks of text or create vague, low‑quality questions, and often give up on spaced repetition entirely. 10x Cards tackles this by letting users paste raw text (PL/EN), generate candidate flashcards with AI, quickly review them (Accept / Edit & Accept / Reject), and combine this with a simple manual flashcard editor and a basic account system.

The product is intentionally focused on a **lean MVP**:

- **AI-assisted flashcard generation** from 1,000–10,000 characters of plain text, returning up to 10 candidates per run.
- **Manual flashcard management** (create, list, search, edit, delete) in a simple flat list (no decks).
- **Basic user accounts** (email + password) with hard deletion of accounts and all related cards.
- **Prepared hooks for spaced repetition** (data model ready to be extended with review fields).
- **Generation logging** so that product metrics like AI acceptance rate and AI vs manual share can be computed later.

The target user is anyone learning from text (notes, course materials, articles) who wants a fast, web-based way to create usable flashcards without dealing with heavy organization or complex spaced-repetition configuration.

---

## Tech stack

### Frontend

- **Next.js 16 (App Router)** – main framework for the web app.
- **React 19** – UI components and client-side interactivity.
- **TypeScript 5** – static typing and better tooling.
- **Tailwind CSS 4** – utility-first styling for a consistent, modern UI.
- **Shadcn/ui** – accessible, composable UI primitives for building modals, forms, lists, etc.

> Note: The original tech stack note references “Next.js 15”, but the actual dependency is `next@16.0.3`. This README reflects the `package.json`.

### Backend

- **Supabase (PostgreSQL + Auth + RLS)**:
  - Acts as Backend-as-a-Service.
  - Provides Postgres database for flashcards, users, and AI generation logs.
  - Provides email/password authentication with row-level security to ensure users only see their own data.
  - Database schema and RLS policies are defined via SQL migrations under `supabase/migrations` (core tables: `flashcards`, `generations`, `generation_error_logs`).

### AI layer

- **OpenRouter.ai**:
  - Gateway to a variety of LLMs (OpenAI, Anthropic, Google, etc.).
  - Enables cost control via per-key limits.
  - Used to turn pasted text into candidate flashcards with strong constraints:
    - Up to 10 cards per generation.
    - Each card: `front` ≤ 200 characters, `back` ≤ 500 characters.

The exact model choice and prompts are intentionally left flexible so they can be tuned based on real-world acceptance metrics.

### Tooling, CI/CD & hosting

- **ESLint 9 + `eslint-config-next`** – linting and best practices for Next.js/React.
- **Tailwind PostCSS plugin** – integration of Tailwind with the build pipeline.
- **GitHub Actions** – planned CI/CD pipelines (build, lint, tests, deploy).
- **Vercel** – hosting for the Next.js app with automatic deployments from GitHub.

---

## Getting started locally

### Prerequisites

- **Node.js**: v20+ recommended (modern Next.js & React versions).
- **npm**: comes with Node; this repo uses `npm` (see `package-lock.json`).
- **Supabase CLI + project**:
  - PostgreSQL database with auth enabled.
  - RLS configured so users can access only their own rows.
  - Local schema managed via the SQL migrations in `supabase/migrations` (e.g. `npx supabase db reset`).
- **OpenRouter API key**:
  - For contacting the AI models used in card generation.

> The exact environment variables are still being refined. The section below uses conventional names that may be adjusted during implementation.

### 1. Clone the repository

```bash
git clone <your-fork-or-clone-url> 10-x-cards
cd 10-x-cards
```

### 2. Install dependencies

```bash
npm install
```

### 3. Configure environment variables

Create a `.env.local` file in the project root and configure (names are indicative, adjust to the actual implementation):

```bash
# Supabase (example names)
NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key

# OpenRouter.ai (server-side only)
OPENROUTER_API_KEY=your-openrouter-api-key
```

Additional variables may be introduced for things like service role keys, logging, or model selection as the backend/UI is implemented.

### 4. Run the development server

```bash
npm run dev
```

By default, the app will be available at `http://localhost:3000`.

### 5. (Optional) Lint and production build

Run ESLint:

```bash
npm run lint
```

Create a production build:

```bash
npm run build
```

Run the production server (after building):

```bash
npm start
```

---

## Available scripts

From `package.json`:

- **`npm run dev`**
  - Starts the Next.js development server with hot reloading.
- **`npm run build`**
  - Builds the application for production using `next build`.
- **`npm run start`**
  - Starts the production server using `next start` (requires a prior `npm run build`).
- **`npm run lint`**
  - Runs ESLint over the codebase using the root `eslint.config.mjs`.

---

## Project scope

### In scope (MVP)

- **User accounts & security**

  - Email + password registration.
  - Login and logout.
  - Password change (old password + new password + confirmation).
  - Hard deletion of the user account and all related flashcards.
  - Secure password hashing, basic password complexity checks.
  - Strong per-user data isolation enforced on the backend (`user_id` checks / RLS).

- **Flashcard management (CRUD)**

  - Flat list of all flashcards for the currently logged-in user (no decks/tags).
  - Default sorting: newest cards first (`created_at` descending).
  - Pagination (simple page-based model: `page`, `pageSize`).
  - Search box filtering by `front` text (case-insensitive substring).
  - Manual creation via modal:
    - `front`: required, up to 200 characters.
    - `back`: required, up to 500 characters.
    - Client-side validation and clear error messages.
    - `origin = "manual"` for manually created cards.
  - Editing existing flashcards via modal with the same validation; `origin` does not change.
  - Hard deletion of flashcards with confirm modal and no undo.

- **AI-based flashcard generation**

  - Input text area for plain text (PL/EN) with live character counter:
    - Minimum 1,000 characters, maximum 10,000 characters.
  - Validation before calling AI:
    - Below 1,000 → block call, show validation message.
    - Above 10,000 → block call, show validation message.
  - AI call (via OpenRouter) returns up to 10 candidate flashcards:
    - Each candidate respects `front`/`back` length limits.
    - Fewer candidates are allowed if the model can only extract a few good cards.
  - Candidates are held **only in session state**:
    - Not persisted until the user accepts.
    - Lost on refresh/end of session; only accepted cards are stored.
  - Review UI:
    - Navigate through candidates sequentially.
    - Actions per candidate:
      - **Accept** → save as flashcard for current user with `origin` indicating AI source.
      - **Edit + Accept** → open form, validate, then save as AI-sourced card (edited).
      - **Reject** → discard without persisting anything.

- **Error handling for AI**

  - On AI/API failure (timeout, error response, etc.):
    - Show a generic, user-friendly error message (no technical details).
    - Do not modify existing flashcards.
    - Log the error status in the generation log.

- **Generation logging & metrics foundation**

  - Every AI generation attempt creates a log entry with at least:
    - `user_id`, `input_length`, `generated_count`, `accepted_count`, `status`, `created_at`.
  - After the review session, logs are updated with:
    - Final `generated_count` and `accepted_count`.
    - Error status if applicable.
  - This supports metrics like:
    - Acceptance rate per generation/user/global.
    - Share of AI-generated vs manually created flashcards.

- **Prepared hooks for spaced repetition**
  - Flashcard data model designed to be extendable with fields such as:
    - `next_review_at`, `ease`, `interval`, etc.
  - CRUD logic kept simple so that future endpoints like “Again / Hard / Good” can be wiring on top.

### Out of scope (MVP)

The following are explicitly **not** part of this MVP:

- **Spaced repetition algorithm**

  - No custom SR algorithm in this iteration.
  - No full review flow yet; integration with an existing open-source algorithm is planned for a later version.

- **Advanced organization features**

  - No decks, tags, categories, folders, or sharing of decks between users.

- **Rich imports and external integrations**

  - No import from PDFs, DOCX, images, or other non-plain-text formats.
  - No integrations with external platforms (LMS, other learning tools).

- **Non-web clients**

  - No native mobile apps; focus is on a web app (desktop-first, mobile-friendly where convenient).

- **Soft delete & advanced UX**

  - No soft delete (trash/undo) for flashcards or accounts.
  - No rich onboarding flows, tutorials, or tooltips beyond basic affordances.

- **Advanced analytics & privacy**
  - No analytics dashboards; raw data in logs is sufficient for now.
  - Detailed legal/privacy documents (e.g., full GDPR policy) are out-of-scope for the MVP; only standard data handling assumptions.

---

## Project status

**Status: MVP in progress.**

Planned and/or in-progress tracks include:

- **Authentication & account lifecycle**

  - Email/password flows, session handling, password change, and account deletion backed by Supabase.

- **Flashcard CRUD**

  - Manual creation, listing, searching, editing, and deletion of flashcards, scoped per user.

- **AI generation & review**

  - Integration with OpenRouter.ai for flashcard candidate generation, plus the full Accept / Edit / Reject review experience.

- **Logging & metrics**

  - Database structures and logic for logging every AI generation and deriving metrics such as acceptance rate and AI vs manual share.

- **Spaced repetition integration**
  - **Not yet implemented**; data model and endpoints are being designed to support this in a future iteration.

For detailed product requirements and user stories, see the internal PRD (`.ai/prd.md`) in this repository.

---

## License

A formal license has **not yet been specified** for this project.

Until a `LICENSE` file is added and/or a `license` field is defined in `package.json`, treat the repository as **all rights reserved** (no implicit permission to use, modify, or distribute). The license choice (e.g. MIT or another OSS license) will be decided and documented in a future update.
