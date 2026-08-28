# Paytm Intent Mesh — Technical Architecture

## 1. System Architecture

```text
┌──────────────────────────────┐
│      Paytm Consumer UI       │
│          Next.js              │
└──────────────┬───────────────┘
               │ REST / SSE
               ▼
┌──────────────────────────────┐
│          FastAPI             │
├──────────────────────────────┤
│ Speech / Intent processing   │
│ Intent Packet validation     │
│ Merchant matching            │
│ Offer lifecycle              │
│ Payment simulation           │
│ Opportunity Pulse            │
└──────────────┬───────────────┘
               │
       ┌───────┴────────┐
       ▼                ▼
┌─────────────┐  ┌─────────────────┐
│   SQLite    │  │ Sarvam / Fallback│
│ Persistence │  │ Language Layer   │
└─────────────┘  └─────────────────┘
               │
               ▼
      ┌───────────────────┐
      │ Soundbox Emulator │
      │ Merchant Surface  │
      └───────────────────┘
```

## 2. Frontend

The responsive Next.js application provides the consumer journey:

```text
/ask
/request/[id]
/offers/[id]
/pay/[offerId]
/success/[id]
```

The merchant interface is available at:

```text
/merchant
/merchant/opportunities
```

The interface is designed to demonstrate a Paytm-embeddable consumer feature and a Soundbox-style merchant experience.

## 3. Backend

The FastAPI backend manages the transaction path.

The implemented routes cover:

- speech transcription;
- intent parsing;
- Intent Packet creation;
- merchant matching;
- merchant requests;
- merchant responses;
- offers;
- offer acceptance;
- simulated payment;
- Opportunity Pulse;
- SSE events.

## 4. Intent Layer

The language layer converts unstructured customer language into structured intent.

Example:

```text
“Mujhe kal 7 baje tak ₹800 ke andar
1 kg eggless chocolate cake chahiye.”
```

becomes a structured request containing information such as:

```text
category: bakery
item: chocolate cake
quantity: 1 kg
budget: ₹800
deadline: tomorrow 7 PM
constraint: eggless
```

Sarvam integration is used when the API key is available. Explicit deterministic fallback paths keep the demo functional when external API/network access is unavailable.

## 5. Matching Engine

Merchant selection is deterministic.

The conceptual pipeline is:

```text
Seeded merchant graph
        ↓
Capability filtering
        ↓
Hard-constraint filtering
        ↓
Deterministic ranking
        ↓
Top merchant candidates
```

Hard requirements are not delegated to an LLM.

The design principle is:

> **AI handles unstructured language; deterministic software handles commerce rules.**

## 6. Merchant Capability Model

The prototype uses locally seeded merchant capability data.

The 20 synthetic merchants span categories including:

- bakery;
- café;
- phone repair;
- tailoring;
- salon;
- pharmacy;
- catering;
- grocery;
- flowers;
- printing;
- plumbing;
- stationery.

## 7. Live Offers

Merchant offers are streamed through Server-Sent Events.

The client also has a one-second polling fallback.

The verified event sequence includes:

```text
connected
offer_received
offer_accepted
payment_received
```

## 8. Persistence

SQLite stores the prototype transaction state, including:

- intents;
- matches;
- merchant requests/responses;
- offers;
- payments.

## 9. Reliability

The implementation includes:

- explicit fallback behavior for unavailable Sarvam access;
- hard-constraint filtering;
- merchant decline handling;
- duplicate-response protection;
- offer/payment idempotency;
- zero-match recovery;
- SSE with polling fallback.

## 10. Payment Boundary

The payment flow is simulated.

The prototype demonstrates:

- offer acceptance;
- simulated Paytm UPI payment;
- Paytm QR simulation;
- Pay Aadha milestone-payment simulation;
- merchant `₹ received` confirmation.

No production Paytm payment API or real-money movement is claimed.
