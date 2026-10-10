# Authorization and Identity

## Core rule

Never trust player identity or ownership values from the client. Always authorize using the authenticated identity on the server.

## Identity model

- User identity from authenticated session or token.
- Resource ownership must be checked server-side.
- Authorization must verify both identity and permissions.

## Checks that must exist

Before any protected action, verify:

- the token is valid;
- the token belongs to the expected user;
- the request is not expired or replayed;
- the user owns the resource or has proper role;
- the action is permitted by current rules.

## Examples

### Unsafe

```text
GET /players/15/inventory
```
If the client changes `15` to `16`, the request must be denied.

### Safe

```text
JWT subject = user_id 7
Requested resource = inventory for user 7
Permission = inventory:read
Result = allowed
```

## Role-based access control

Roles should be explicit and limited to needed actions, such as:

- PLAYER
- MODERATOR
- SUPPORT
- ADMIN
- SUPER_ADMIN

## Authorization policy template

```text
Token -> User identity -> Role -> Permission -> Resource ownership -> Decision
```

## Required protections

- no direct trust in `player_id` from client;
- no direct trust in `match_id` from client;
- no direct trust in inventory or reward IDs; 
- no unrestricted access to other users' data;
- denial by default.

## Token guidance

- use short-lived access tokens;
- rotate refresh tokens;
- revoke tokens on logout or suspicious activity;
- reject token algorithms not explicitly allowed;
- verify issuer, audience, expiry and signature.
