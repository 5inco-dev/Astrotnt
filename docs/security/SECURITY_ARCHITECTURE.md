# Security Architecture

## Trust model

The Godot client is treated as an untrusted client. Any value originating from the client must be considered potentially modified, replayed, or forged.

### Trust boundaries

- Client boundary: Godot, Android runtime, device state, local data, logs.
- Transport boundary: HTTPS/WSS between client and backend.
- API boundary: authentication, authorization, validation, rate limiting, business checks.
- Persistence boundary: PostgreSQL and application data model.
- Admin boundary: internal operators and support tools.

## Recommended architecture

```text
Android / Godot
    │
    │ HTTPS / WSS
    ▼
Spring Boot API
    ├─ Auth
    ├─ Authorization
    ├─ Validation
    ├─ Rate limiting
    ├─ Game rules
    ├─ Economy
    ├─ Inventory
    ├─ Match validation
    ├─ Audit logs
    └─ Security events
    │
    ▼
PostgreSQL
    ├─ users
    ├─ profiles
    ├─ inventory
    ├─ characters
    ├─ weapons
    ├─ matches
    ├─ missions
    └─ progression
```

## Security principles

### 1. Server authority

The server decides:

- rewards;
- XP and level progression;
- inventory ownership and item state;
- match result and winner;
- economy operations;
- prices and purchase validation;
- login/session decisions;
- authorization decisions.

### 2. Least privilege

The application database user must not be a superuser.

### 3. Defense in depth

Use multiple layers:

- TLS;
- authentication;
- authorization;
- request validation;
- transaction boundaries;
- rate limiting;
- logging;
- monitoring.

### 4. Auditability

Every critical operation should be recorded with actor, reason, timestamp and result.

## Server-side rules for gameplay

All gameplay rules must be finalized on the server when they affect persistent state:

- combat outcome;
- damage resolution;
- rank updates;
- loot and rewards;
- inventory mutation;
- progression updates;
- matchmaking assignment.

The Godot client may send commands, but the server validates and resolves them.

## Secrets and environment

Never store:

- database password;
- JWT secret;
- API keys;
- admin tokens;
- private keys;
- service credentials;
inside the Godot project or APK.

Use environment variables or a secret manager. Keep local `.env` files only in development and exclude them from Git.

## Operational security

- use separate credentials per environment;
- keep production isolated from development;
- rotate secrets routinely;
- fail securely on invalid requests;
- avoid exposing stack traces to clients;
- log security events without logging secrets.
