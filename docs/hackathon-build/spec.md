# Technical Spec

Consumer: Next.js responsive app at `/ask`, `/request/[id]`, `/offers/[id]`, `/pay/[offerId]`, and `/success/[id]`.

Merchant: Soundbox emulator at `/merchant`; demand insights at `/merchant/opportunities`.

Backend: FastAPI routes for parsing, intent creation, matches, merchant requests/responses, offers, acceptance, simulated payment, Opportunity Pulse, speech transcription, and SSE events. SQLite stores the transaction path. Merchant capability data is seeded locally.

Reliability: Sarvam calls are optional and fail closed into explicit demo fallbacks. Customer live updates use SSE and polling. No real money, identity, KYC, lending, delivery, or Paytm production APIs are claimed.
