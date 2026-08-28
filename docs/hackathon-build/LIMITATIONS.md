# Paytm Intent Mesh — Limitations

This repository represents a hackathon prototype.

## Data

Merchant capability data is seeded and synthetic.

The prototype does not query Paytm's production merchant database or production inventory.

## Payments

The payment experience is simulated.

The prototype does not move real money and does not claim access to Paytm's production payment rails.

## Soundbox

The merchant device is a Soundbox-style emulator.

No physical Soundbox firmware or production device protocol is modified or claimed.

## AI

Sarvam integration is optional.

When API access is unavailable, deterministic fallback paths keep the demo functional.

The 30-case evaluation measures the checked-in prototype behavior and should not be interpreted as a general-purpose language benchmark.

## Infrastructure

The prototype uses:

- SQLite;
- in-process SSE;
- locally seeded merchant data.

A production implementation would require scalable storage, distributed event infrastructure, production merchant identity, authentication/authorization, observability, and stronger reliability guarantees.

## Security

A production deployment would need additional controls including:

- authenticated customer and merchant sessions;
- authorization boundaries;
- secrets management;
- rate limiting;
- abuse prevention;
- audit logging;
- privacy controls;
- payment-risk and fraud controls;
- secure production infrastructure.

## Fulfilment

The prototype demonstrates merchant offers and fulfilment information but does not provide production delivery logistics.

## KYC / Identity / Lending

The prototype does not implement or claim:

- production KYC;
- identity verification;
- lending;
- underwriting.

## Production Boundary

The intended distinction is:

```text
Hackathon prototype
        ≠
Production Paytm integration
```

The repository documents simulated and synthetic components explicitly so that the demo remains technically honest.
