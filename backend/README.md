# Astrotnt Backend

This backend is the server-authoritative layer for the Astrotnt game.

## Architecture

```text
Godot Client
    │ HTTPS / JSON
    ▼
Spring Boot API
    ├─ Auth
    ├─ Players
    ├─ Characters
    ├─ Weapons
    ├─ Inventory
    ├─ Missions
    ├─ Matches
    ├─ Rewards
    └─ Ranking
    │
    ▼
PostgreSQL
```

## Run locally

```bash
mvn spring-boot:run
```

## Default endpoints

- GET /api/health

## Notes

- Client values must never be trusted for economy, progression, inventory or match outcomes.
- All critical actions are validated and resolved on the server.
