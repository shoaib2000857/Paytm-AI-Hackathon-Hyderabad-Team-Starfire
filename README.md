# Paytm Intent Mesh

> Human language becomes the merchant API.

Paytm Intent Mesh is a working two-sided prototype of an agentic commerce layer for offline India. A customer describes an outcome inside a Paytm-like experience; the system converts it into an Intent Packet, deterministically routes it to capable nearby merchants, receives offers through a Soundbox-style interface, and closes the loop with a simulated Paytm payment.

## What works

- Consumer text and browser-microphone entry
- Sarvam STT and structured intent integration when `SARVAM_API_KEY` is present
- Resilient demo transcription and local intent parser when API/network access fails
- Hard-constraint filtering and transparent deterministic merchant ranking
- SQLite persistence for intents, matches, offers, and payments
- Live offers over SSE with one-second polling fallback
- Multi-merchant Soundbox emulator
- AI extraction of multilingual merchant price, readiness, delivery, and fulfilment responses
- Functional merchant decline path and duplicate-response protection
- Offer acceptance and simulated Paytm UPI payment
- Paytm QR and Pay Aadha milestone-payment simulations
- Live merchant `₹ received` confirmation and Opportunity Pulse endpoint/screen
- Twenty synthetic merchants spanning bakery, café, phone repair, tailoring, salon, pharmacy, catering, grocery, flowers, printing, plumbing, and stationery

## Run locally

Terminal 1:

```bash
source .venv/bin/activate
uvicorn backend.main:app --reload --port 8000
```

Terminal 2:

```bash
cd frontend
npm run dev
```

Open the customer experience at `http://localhost:3000/ask` and keep a second window ready for the merchant interface at `http://localhost:3000/merchant`.

For live Sarvam usage, copy `backend/.env.example` to `backend/.env`, add the key, and export it before starting the backend. Without a key, the entire demo remains functional through deterministic fallbacks.

## Exact jury demo

1. On `/ask`, speak or submit: “Mujhe kal 7 baje tak ₹800 ke andar 1 kg eggless chocolate cake chahiye.”
2. Review the Intent Packet and select **Find for me**.
3. On the finding screen, select **Open merchant device**.
4. On the Soundbox, confirm Sweet Crumbs at ₹750 / 6:30 PM.
5. Return to the customer screen; the offer appears live. Repeat using the merchant selector for HomeBakes and Cake House if desired.
6. Choose Sweet Crumbs, pay ₹750, and show the closed-loop confirmation.
7. Finish on `/merchant/opportunities`: explicit unfulfilled demand becomes merchant growth intelligence.

## Architecture

```text
Paytm consumer feature ── REST/SSE ── FastAPI + SQLite
         │                                  │
         │                           Intent Engine
         │                         Sarvam or fallback
         │                                  │
         └──── live offers ─── Deterministic Router
                                            │
                                  Soundbox emulator
```

AI handles unstructured language and speech. Deterministic software handles hard constraints, merchant retrieval, ranking, payments, and business rules.

## Verification

```bash
cd backend && ../.venv/bin/pytest -q
cd frontend && npm run build
```

The backend suite covers the full cake transaction, hard-constraint filtering, service extraction, merchant decline, duplicate response/payment safety, and no-match behavior. `evaluation/run_evaluation.py` evaluates 30 synthetic multilingual/code-mixed requests.

Current measured deterministic fallback results:

- Category extraction: 100%
- Budget extraction: 100%
- Relevant merchant in Top-3: 100%
- Median parse + match: approximately 0.05 ms

These numbers apply only to the checked-in 30-case prototype evaluation set—not general production accuracy.
