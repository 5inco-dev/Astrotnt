# Security Architecture

This folder documents the security model for the project and provides the implementation baseline for a server-authoritative game architecture.

## Scope

- Godot client is untrusted.
- Spring Boot backend is the source of truth for economy, progression, inventory, matches and authorization.
- PostgreSQL is protected by least-privilege access and secure configuration.
- Security is designed in from the start, not appended later.

## Documents

- [SECURITY_ARCHITECTURE.md](SECURITY_ARCHITECTURE.md)
- [THREAT_MODEL.md](THREAT_MODEL.md)
- [AUTHORIZATION.md](AUTHORIZATION.md)
- [API_SECURITY.md](API_SECURITY.md)

## Core rules

1. Godot never decides rewards, inventory, XP, prices, or battle results.
2. The server validates every relevant action.
3. Identity and ownership checks must happen server-side for every protected resource.
4. Secrets stay outside the game client and out of Git.
5. The backend should reject invalid or duplicate requests and log security-relevant events.
