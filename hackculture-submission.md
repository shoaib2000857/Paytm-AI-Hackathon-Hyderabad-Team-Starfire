# Paytm Intent Mesh — HackCulture Submission Draft

## Theme

AI-Powered Fintech Innovation

## Problem Statement

AI for Small Businesses

## Project Title

Paytm Intent Mesh — The Agentic Commerce Layer for Offline India

## Briefly describe your AI-powered solution

AI agents can already shop from businesses with APIs, but most local Indian merchants have no API, live catalogue, or structured inventory. They may already have a Paytm QR, merchant account, and Soundbox—but customers still need to search, call, message, and compare businesses manually.

Paytm Intent Mesh turns natural language into a structured Intent Packet and routes it to nearby merchants who are likely capable of fulfilling it. A customer can say, “I need a 1 kg eggless chocolate cake under ₹800 tomorrow before 7 PM.” Sarvam AI handles multilingual speech and extracts the item, budget, deadline, hard constraints, and preferences. Deterministic software then filters and ranks merchants using capability fit, GPS distance, reliability, response speed, fulfilment history, and customer preference.

Matched merchants receive the request through a Paytm Soundbox-style interface and can respond by voice in Hindi, Telugu, Hinglish, or other supported Indian languages. Their response becomes a structured offer that appears live for the customer. The customer chooses an offer and completes a simulated Paytm payment. Unfulfilled requests power Opportunity Pulse, which shows merchants explicit unmet demand around them.

The core insight is: **human language becomes the merchant API.** Intent Mesh makes offline merchants agent-accessible without requiring a website, complete catalogue, or custom software integration.

## Prototype Deployment Link or Demo Video

TODO: Add public deployment URL or uploaded demo-video URL. Do not use localhost in the form.

## GitHub Repository

TODO: Add public GitHub repository URL after confirming that `.env` and API credentials are not committed.

## Did you use Paytm APIs, products, or technology?

YES

## How Paytm technology was used

Paytm Intent Mesh is designed as a feature inside the existing Paytm consumer and merchant ecosystem rather than as a standalone marketplace. The consumer journey is presented as “Ask Paytm” inside a Paytm-style app experience. On the merchant side, the prototype extends the Paytm Soundbox concept from payment confirmation into a connected commerce interface that can receive high-intent customer requests and capture spoken merchant offers.

The final transaction uses a simulated Paytm UPI payment interface, and the merchant device receives a live “₹750 received” confirmation. No private or production Paytm API was available during the prototype, so real money movement and Soundbox firmware integration are intentionally simulated. The working contribution is the intent, capability-routing, merchant-response, live-offer, GPS matching, and fulfilment architecture that could plug into Paytm’s existing merchant relationships and payment rails.

## Logitech Experience Booth

Select YES only if a team member actually visited the booth; otherwise select NO.

If YES, adapt this truthful template: “Yes. We enjoyed trying the Logitech products and found the experience well organized and useful during an intensive build day. The devices felt comfortable, responsive, and well suited to long development and presentation sessions.”

## Verified Prototype Evidence  

- Real Sarvam STT for customer and merchant speech
- Sarvam-105B Conversations intent and merchant-response extraction
- 20 synthetic merchants across 12 local-business categories
- Browser GPS and real proximity-aware deterministic ranking
- SQLite persistence, SSE live events, and polling fallback
- Functional offer, decline, selection, and idempotent simulated payment flows
- Live merchant payment confirmation and Opportunity Pulse
- Seven backend tests passing
- Next.js production build passing
- Thirty-case evaluation: 100% category extraction, 100% budget extraction, and 100% relevant-merchant Top-3 recall on the checked-in prototype dataset

## Known Limitations

- Paytm payment and Soundbox integration are simulated because private production APIs and device firmware access were not provided.
- Merchant and demand data are synthetic for the hackathon prototype.
- The Flutter companion source exists, but native binaries were not built because the Flutter SDK was unavailable in the build environment.
