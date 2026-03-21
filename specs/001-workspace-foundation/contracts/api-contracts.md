# API Contracts: Workspace Foundation

**Branch**: `001-workspace-foundation`
**Date**: 2026-03-19

## Overview

This phase exposes a minimal set of Serverpod endpoints. The primary purpose is to verify that the backend is reachable, authentication works, and the server is ready for sync endpoints in Phase 3.

---

## Endpoints

### AuthEndpoint

Serverpod's built-in auth module handles registration and sign-in. These are not custom endpoints — they use Serverpod's `serverpod_auth` package.

| Operation | Method | Auth Required | Description |
|-----------|--------|---------------|-------------|
| Register | createUser (email+password) | No | Creates the owner account. Only one account allowed (enforced server-side). |
| Sign In | signIn (email+password) | No | Authenticates the owner and returns a session token. |
| Sign Out | signOut | Yes | Invalidates the current session. |
| Validate Session | getAuthenticatedUser | Yes | Returns the authenticated user info or error if not authenticated. |

**Single-account enforcement**: The server must check that no existing account exists before allowing registration. If an account already exists, the registration request must return an error.

---

### HealthEndpoint (custom)

A lightweight endpoint to verify server reachability and authentication.

| Operation | Method | Auth Required | Description |
|-----------|--------|---------------|-------------|
| Ping | `ping()` | No | Returns `"pong"` — used to check if the server is reachable. |
| Authenticated Ping | `authenticatedPing()` | Yes | Returns `"pong"` — used to verify that the auth token is valid. |

**Contract**:

```
// Request: ping()
// Response: String "pong"

// Request: authenticatedPing()
// Requires: valid Serverpod session
// Response: String "pong"
// Error: ServerpodAuthenticationException if not authenticated
```

---

## Error Handling

All endpoints follow Serverpod's standard error format:

| Error | Condition | Response |
|-------|-----------|----------|
| Authentication required | Request without valid session to an authenticated endpoint | ServerpodAuthenticationException |
| Account already exists | Registration when an account already exists | Custom exception with message "Account already exists" |
| Invalid credentials | Sign-in with wrong email or password | Serverpod's auth module error response |
| Server error | Unexpected server failure | Serverpod's standard 500 response |

## Notes

- No CRUD endpoints in this phase — those come with Phase 2 (data model) and Phase 3 (sync).
- The health endpoint is intentionally minimal; its purpose is to validate connectivity and auth without touching business data.
- All endpoints use Serverpod's built-in serialization and protocol classes.
