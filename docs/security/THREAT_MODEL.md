# Threat Model

## Assets to protect

- user accounts;
- player profiles and inventory;
- progression and economy;
- fight results and rankings;
- reward and mission logic;
- backend and database credentials;
- match integrity and server state.

## Threats and mitigations

| Threat | Impact | Probability | Mitigation | Detection | Response |
|---|---|---:|---|---|---|
| Credential stuffing | Account takeover | Medium | Rate limiting, lockouts, MFA for admin, secure password hashing | Failed login spikes | Lock suspicious accounts, notify user, review logs |
| API tampering | Economy/game abuse | High | Server-side validation, signed game commands, authoritative simulation | Request anomaly detection | Reject and audit transaction |
| IDOR / broken access control | Account data leakage | High | Require authenticated identity and ownership checks | Access patterns outside ownership | Block and investigate |
| Replay of requests | Duplicate rewards | High | Idempotency keys, transaction checks, server deduplication | Duplicate operation IDs | Reject duplicates and audit |
| Client-side game cheating | Progression abuse | High | Server-authoritative economy, validation on match result | Impossible stats, impossible actions | Ban or rollback if justified |
| SQL injection | Data compromise | Medium | Parameterized queries, ORM, DB constraints | DB error spike, unusual query patterns | Isolate DB, rotate credentials, investigate |
| Rate-limit abuse | DoS or spam | Medium | Endpoint throttling, IP/account limits | Traffic spikes | Block or slow request sources |
| Secret leakage | Full compromise | Medium | Secret manager, Git scanning, environment isolation | Secret detection alerts | Rotate secret immediately |
| Match manipulation | Rank abuse | High | Server resolves match outcome, not client input | Impossible win/loss records | Reset affected values and investigate |
| WebSocket abuse | State desync | Medium | Authenticated sessions, validation, session tracking | Large message bursts | Disconnect and audit |

## Security assumptions

- The client can be modified, intercepted, or replayed.
- An attacker may inspect network traffic and alter request payloads.
- Attackers may attempt duplicate reward claims or tamper with local game state.

## Response process

1. Detect anomaly.
2. Contain impact.
3. Investigate actor and scope.
4. Revoke or rotate affected credentials.
5. Recover correct state.
6. Document and improve controls.
