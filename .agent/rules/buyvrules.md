---
trigger: always_on
---

# BuyV Engineering Rules & Context

## Tech Stack
- Backend: Python FastAPI + SQLAlchemy + SQLite.
- Frontend: Flutter (Material3).
- Auth: JWT (using jose library).

## Strict Engineering Rules
1. **Schema First:** When adding comments, always start by updating `models.py` and running migrations before touching Flutter code.
2. **Search Logic:** Search must be implemented server-side with Pagination, not as a local UI filter.
3. **Deep Linking:** The approved scheme is `buyv://product/{id}`. Modify `AndroidManifest.xml` and `Info.plist` accordingly.
4. **Commission Logic:** The commission value is currently hardcoded at 0.01; keep this as a variable for future dynamic updates.
5. **Video Cache:** Replace the standard `video_player` with `cached_video_player` in all Reels screens.

## Mandatory Documentation
- After every task, update the `DEVELOPMENT_LOG.md` file with technical details of what was achieved.
