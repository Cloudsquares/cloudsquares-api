# OpenAPI Documentation Implementation Plan

## Overview
Multi-phase plan to add OpenAPI 3.0.1 documentation using rswag (RSpec-based approach) with full schema definitions.

---

## Phase 0: Foundation Setup
**Status: COMPLETED** ✅

- [x] Update `spec/swagger_helper.rb` with schemas, tags, servers
- [x] Create `spec/support/swagger_shared_examples.rb`
- [x] Create `spec/support/swagger_test_helpers.rb`
- [x] Add swagger commands to `Makefile`
- [x] Populate factories with required attributes (11 files)

**Files created/modified:**
- `spec/swagger_helper.rb` - ~40 schema components, 14 tags, security schemes
- `spec/support/swagger_shared_examples.rb` - Reusable response examples
- `spec/support/swagger_test_helpers.rb` - Auth helpers for specs
- `Makefile` - Added swagger-generate, swagger-specs, swagger-validate commands
- Factory files: people, users, agencies, agency_plans, agency_settings, user_agencies, contacts, customers, properties, property_categories, property_locations, property_photos

---

## Phase 1: Authentication Endpoints
**Status: COMPLETED** ✅ (23 tests passing)

- [x] `spec/requests/api/v1/auth_spec.rb` (6 endpoints)
  - POST /api/v1/auth/login
  - POST /api/v1/auth/refresh
  - POST /api/v1/auth/logout
  - POST /api/v1/auth/register-user
  - POST /api/v1/auth/register-agent-with-agency
  - POST /api/v1/auth/register-agent (deprecated)

---

## Phase 2: Core Entity CRUD
**Status: IN PROGRESS** (7/21 endpoints)

- [x] `spec/requests/api/v1/users_spec.rb` (7 endpoints) ✅ (21 tests passing)
  - GET /api/v1/me
  - PATCH /api/v1/me
  - GET /api/v1/users
  - GET /api/v1/users/{id}
  - POST /api/v1/users
  - PATCH /api/v1/users/{id}
  - DELETE /api/v1/users/{id}

- [ ] `spec/requests/api/v1/agencies_spec.rb` (6 endpoints) ⏳
  - GET /api/v1/agencies
  - GET /api/v1/agencies/{id}
  - POST /api/v1/agencies
  - PATCH /api/v1/agencies/{id}
  - DELETE /api/v1/agencies/{id}
  - PATCH /api/v1/agencies/{id}/change_plan

- [ ] `spec/requests/api/v1/agency_plans_spec.rb` (5 endpoints)
  - GET /api/v1/agency_plans
  - GET /api/v1/agency_plans/{id}
  - POST /api/v1/agency_plans
  - PATCH /api/v1/agency_plans/{id}
  - DELETE /api/v1/agency_plans/{id}

- [ ] `spec/requests/api/v1/agency_settings_spec.rb` (3 endpoints)
  - GET /api/v1/agency_settings
  - PATCH /api/v1/agency_settings
  - GET /api/v1/agencies/{agency_id}/settings

---

## Phase 3: Properties & Categories
**Status: PENDING**

- [ ] `spec/requests/api/v1/properties_spec.rb` (7 endpoints)
  - GET /api/v1/properties
  - GET /api/v1/properties/{id}
  - POST /api/v1/properties
  - PATCH /api/v1/properties/{id}
  - DELETE /api/v1/properties/{id}
  - POST /api/v1/properties/{id}/publish
  - POST /api/v1/properties/{id}/unpublish

- [ ] `spec/requests/api/v1/property_categories_spec.rb` (5 endpoints)
  - GET /api/v1/property_categories
  - GET /api/v1/property_categories/{id}
  - POST /api/v1/property_categories
  - PATCH /api/v1/property_categories/{id}
  - DELETE /api/v1/property_categories/{id}

- [ ] `spec/requests/api/v1/property_characteristics_spec.rb` (5 endpoints)
  - GET /api/v1/property_characteristics
  - GET /api/v1/property_characteristics/{id}
  - POST /api/v1/property_characteristics
  - PATCH /api/v1/property_characteristics/{id}
  - DELETE /api/v1/property_characteristics/{id}

- [ ] `spec/requests/api/v1/property_characteristic_options_spec.rb` (2 endpoints)
  - GET /api/v1/property_characteristics/{id}/options
  - POST /api/v1/property_characteristics/{id}/options

---

## Phase 4: Property Relations
**Status: PENDING**

- [ ] `spec/requests/api/v1/property_photos_spec.rb` (5 endpoints)
  - GET /api/v1/properties/{property_id}/photos
  - POST /api/v1/properties/{property_id}/photos
  - PATCH /api/v1/properties/{property_id}/photos/{id}
  - DELETE /api/v1/properties/{property_id}/photos/{id}
  - PATCH /api/v1/properties/{property_id}/photos/reorder

- [ ] `spec/requests/api/v1/property_comments_spec.rb` (4 endpoints)
  - GET /api/v1/properties/{property_id}/comments
  - POST /api/v1/properties/{property_id}/comments
  - PATCH /api/v1/properties/{property_id}/comments/{id}
  - DELETE /api/v1/properties/{property_id}/comments/{id}

- [ ] `spec/requests/api/v1/property_owners_spec.rb` (4 endpoints)
  - GET /api/v1/properties/{property_id}/owners
  - POST /api/v1/properties/{property_id}/owners
  - PATCH /api/v1/properties/{property_id}/owners/{id}
  - DELETE /api/v1/properties/{property_id}/owners/{id}

- [ ] `spec/requests/api/v1/property_characteristic_values_spec.rb` (2 endpoints)
  - GET /api/v1/properties/{property_id}/characteristics
  - POST /api/v1/properties/{property_id}/characteristics

---

## Phase 5: Customers, Contacts & Internal
**Status: PENDING**

- [ ] `spec/requests/api/v1/customers_spec.rb` (5 endpoints)
  - GET /api/v1/customers
  - GET /api/v1/customers/{id}
  - POST /api/v1/customers
  - PATCH /api/v1/customers/{id}
  - DELETE /api/v1/customers/{id}

- [ ] `spec/requests/api/v1/contacts_spec.rb` (5 endpoints)
  - GET /api/v1/contacts
  - GET /api/v1/contacts/{id}
  - POST /api/v1/contacts
  - PATCH /api/v1/contacts/{id}
  - DELETE /api/v1/contacts/{id}

- [ ] `spec/requests/api/internal/photo_jobs_spec.rb` (2 endpoints)
  - POST /api/internal/photo_jobs/complete
  - POST /api/internal/photo_jobs/failed

---

## Summary

| Phase | Description | Endpoints | Status |
|-------|-------------|-----------|--------|
| 0 | Foundation Setup | - | ✅ COMPLETED |
| 1 | Authentication | 6 | ✅ COMPLETED |
| 2 | Core Entity CRUD | 21 | ⏳ IN PROGRESS (7/21) |
| 3 | Properties & Categories | 19 | PENDING |
| 4 | Property Relations | 15 | PENDING |
| 5 | Customers, Contacts, Internal | 12 | PENDING |

**Total Endpoints: 73**
**Completed: 13 (18%)**
**Remaining: 60 (82%)**

---

## Test Results (Latest Run)

| Spec File | Examples | Failures | Status |
|-----------|----------|----------|--------|
| auth_spec.rb | 23 | 0 | ✅ |
| users_spec.rb | 21 | 0 | ✅ |
| **Total** | **44** | **0** | ✅ |

---

## Bug Fixes Applied

1. **`UserUpdaterService`** (app/services/users/user_updater_service.rb:44)
   - Changed `params.symbolize_keys` → `params.to_h.symbolize_keys`
   - Rails 8 compatibility fix for ActionController::Parameters

2. **Error Schema** (spec/swagger_helper.rb)
   - Wrapped in `error` object to match API response format
   - `message` field supports both string and nested object

3. **SuccessMessage Schema** (spec/swagger_helper.rb)
   - Wrapped in `success` object to match API response format

4. **User Schema** (spec/swagger_helper.rb)
   - `agency` field marked as nullable (can be null)

---

## Commands

```bash
# Generate OpenAPI spec from tests
make swagger-generate-test

# Run swagger specs with documentation output
make swagger-specs

# Validate generated swagger.yaml
make swagger-validate

# Open Swagger UI (after starting dev server)
make swagger-ui
```

---

## Next Steps

1. Implement `agencies_spec.rb` (6 endpoints)
2. Implement `agency_plans_spec.rb` (5 endpoints)
3. Implement `agency_settings_spec.rb` (3 endpoints)
4. Complete Phase 2, then proceed to Phase 3
