# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CloudSquares Backend - Rails 8.0.2 API-only application for a SaaS real estate marketplace platform. Ruby 3.4.2, PostgreSQL 17, Redis 7.4.

## Common Commands

All development uses Docker via Makefile:

```bash
# Setup & run
make setup              # Initial setup (checks Docker, creates envs, migrates DB)
make up-dev             # Start development services
make clean-dev          # Stop dev containers

# Database
make db-migrate         # Run pending migrations
make db-rollback STEP=1 # Rollback migrations
make db-reset           # Drop, recreate, migrate, seed
make db-seed            # Load seeds.rb

# Testing
make test               # Run all RSpec tests
make test-file f=spec/requests/api/v1/users_spec.rb  # Run single test file

# Utilities
make console            # Rails console in container
make routes             # Print all routes
make logs-dev           # View container logs
```

## Architecture

### Request Flow
```
Controllers (API) → Services (business logic) → Models (data) → Serializers (response)
       ↓
   Policies (Pundit authorization)
```

### Key Directories
- `app/controllers/api/v1/` - REST API endpoints inheriting from `BaseController`
- `app/services/` - Business logic (auth, shared utilities, domain services)
- `app/policies/` - Pundit authorization policies
- `app/serializers/` - ActiveModel Serializers for JSON responses
- `app/validators/` - Custom validators (e.g., `PropertyBaseValidator`)
- `spec/` - RSpec tests with FactoryBot factories

### Authentication
- JWT-based with access tokens (15min TTL) and refresh tokens (14 days, stored in Redis)
- `Auth::JwtService` handles token generation/verification
- All API requests require `Authorization: Bearer <token>` header
- Token payload includes `user_id`, `agency_id` context

### User Roles (enum in User model)
- `admin` (0), `admin_manager` (1) - Platform admins
- `agent_admin` (2), `agent_manager` (3), `agent` (4) - Agency staff
- `user` (5) - B2C customers

### Key Patterns
- **Soft deletes**: Uses `discard` gem on some models
- **i18n**: Mobility gem with key-value backend (ru, en, kz locales)
- **Slugs**: FriendlyId with `Shared::SlugNormalizer` (supports Kazakh via Babosa)
- **Phone normalization**: Always use `Shared::PhoneNormalizer` for phone fields

### Test Helpers
```ruby
# spec/support/auth_helpers.rb
auth_headers(user)  # Generate JWT bearer token header for request specs

# spec/support/request_helpers.rb
json_body           # Parse JSON response body
```

## API Structure

Routes follow RESTful conventions under `/api/v1/`:
- Auth: `/auth/login`, `/auth/refresh`, `/auth/register-*`
- Resources: `/users`, `/agencies`, `/properties`, `/customers`, `/contacts`
- Nested: `/properties/:id/comments`, `/properties/:id/owners`
- Internal webhooks: `/api/internal/photo_jobs`

## Environment

- `.env.development`, `.env.test`, `.env.production` - Environment variables
- Key vars: `JWT_SECRET`, `DATABASE_URL`, `REDIS_URL`
- Docker services: web (port 3000), db, redis, sidekiq

## Code Quality

```bash
bundle exec rubocop     # Linting (rubocop-rails-omakase style)
bundle exec brakeman    # Security analysis
```
