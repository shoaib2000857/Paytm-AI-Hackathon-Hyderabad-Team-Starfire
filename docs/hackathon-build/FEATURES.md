# Paytm Intent Mesh — Feature Documentation

## Consumer Features

### Natural-Language Request

Customers can describe what they need in ordinary language rather than selecting from a rigid catalogue.

### Browser Microphone Input

The consumer experience supports browser microphone entry.

### Multilingual / Code-Mixed Intent

The language layer supports the prototype's multilingual and code-mixed demo requests.

### Intent Packet

Before merchant discovery, the system exposes the structured interpretation of the customer's request.

This makes the extracted requirements inspectable.

### Merchant Matching

The system finds capable merchants using deterministic filtering and ranking.

### Live Merchant Offers

Merchant responses appear live through SSE, with polling retained as a fallback.

### Offer Selection

Customers can compare/select a merchant offer before payment.

### Simulated Payment

The prototype supports simulated:

- Paytm UPI payment;
- Paytm QR payment;
- Pay Aadha milestone payment.

### Closed-Loop Confirmation

The customer and merchant receive confirmation after the simulated payment.

---

## Merchant Features

### Soundbox Emulator

The merchant interface represents a Paytm Soundbox-style interaction.

### Request Handling

Merchants can review incoming customer requests.

### Offer Response

Merchants can provide:

- price;
- readiness;
- delivery/fulfilment information.

### Decline Handling

The prototype supports merchant decline and recovery when a merchant cannot fulfil a request.

### Duplicate Protection

Repeated merchant responses are protected against duplicate processing.

### Payment Confirmation

The merchant receives a live simulated `₹ received` confirmation.

---

## Demand Intelligence

### Opportunity Pulse

Explicit unfulfilled demand is surfaced as merchant growth intelligence.

The concept is:

```text
Customer request
      ↓
No suitable merchant
      ↓
Explicit unmet demand
      ↓
Opportunity Pulse
```

This avoids treating an unfulfilled request as a successful transaction.

---

## Backend Features

- FastAPI
- SQLite persistence
- Intent Packet validation
- Merchant capability graph
- Deterministic hard filtering
- Deterministic ranking
- SSE
- Polling fallback
- Offer lifecycle
- Payment lifecycle
- Idempotency
- No-match recovery
- Sarvam-ready language integration
- Deterministic demo fallbacks

---

## Supported Demo Verticals

The synthetic merchant set spans:

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
