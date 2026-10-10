# API Security

## Requirements

Every API exposure should implement:

- authentication when required;
- authorization;
- strict schema validation;
- rate limiting;
- request size limits;
- standardized error handling;
- security logging;
- transaction safety;
- idempotency for critical operations.

## Sensitive endpoints

The following endpoints deserve strong protection:

- /auth/login
- /auth/register
- /auth/refresh
- /players/profile
- /inventory
- /reward
- /purchase
- /match
- /ranking
- /admin/*

## Validation rules

- reject malformed JSON;
- reject unknown fields when strict validation is required;
- enforce integer ranges and allowed enums;
- reject oversized payloads;
- normalize inputs before processing;
- never perform raw SQL string concatenation with user input.

## Rate limiting

Apply limits by:

- IP;
- user account;
- endpoint;
- session;
- action type.

Examples:

- login: low threshold and lockout on repeated failures;
- reward claim: one valid operation per reward event;
- purchase: validate inventory and wallet before commit.

## Idempotency

Critical actions should support idempotency keys or transaction uniqueness, especially for:

- reward grants;
- purchases;
- match result submissions;
- mission completions;
- inventory mutations.

## Error handling

Client responses should expose only sanitized error codes, not:

- SQL strings;
- database names;
- stack traces;
- internal host names;
- secrets.

## Logging

Security logs should capture:

- timestamp;
- actor;
- endpoint;
- result;
- reason;
- metadata relevant to the event.

Do not log passwords, private tokens, or raw secret values.
