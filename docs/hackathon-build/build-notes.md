# Build Notes

- Product frozen as **Paytm Intent Mesh**; no ideation expansion.
- Organizer PDFs confirm that the solution must extend the existing Paytm user or merchant stack. The implementation presents one consumer feature and one Soundbox merchant feature.
- Kept AI at the language boundary and deterministic logic at the commerce boundary.
- Selected a mobile-first responsive web prototype because it demonstrates an embeddable Paytm feature on phones and laptops without spending hackathon time on app-store packaging.
- SQLite and in-process SSE are intentional prototype choices; polling is retained as a demo-day fallback.
- Next.js was upgraded during verification after the initial pinned version reported a security advisory.
- Backend test result: 3 passed. Frontend production build: passed.
- Full audit added merchant-response AI extraction, decline handling, offer/payment idempotency, live merchant payment confirmation, and an explicit zero-match recovery state.
- Expanded verification: 5 backend tests passed. The 30-case synthetic evaluation reached 100% category extraction, budget extraction, and Top-3 recall for the supported demo verticals. SSE delivered `connected`, `offer_received`, `offer_accepted`, and `payment_received` in order.
