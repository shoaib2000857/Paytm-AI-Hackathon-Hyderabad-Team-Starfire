# Paytm Intent Mesh — Design Decisions

## 1. AI at the Language Boundary

The prototype intentionally separates language understanding from commerce decisions.

```text
Unstructured language
        ↓
       AI
        ↓
Structured Intent Packet
        ↓
Deterministic commerce logic
```

AI is useful for speech, multilingual understanding, and extracting entities from natural language.

## 2. Deterministic Commerce Logic

Merchant retrieval, hard constraints, ranking, payment state, and business rules are handled deterministically.

This prevents a language model from silently relaxing a requirement such as:

- maximum budget;
- required item;
- quantity;
- deadline;
- required attribute.

## 3. Existing Paytm Surface

The concept is designed around the existing consumer/merchant ecosystem.

The merchant does not need to build a separate public API for the prototype.

The Soundbox-style surface represents a low-friction merchant interaction point.

## 4. Responsive Web Prototype

A mobile-first responsive web application was selected for the hackathon because it demonstrates the consumer experience without spending the build window on app-store packaging.

## 5. SQLite

SQLite was selected for the prototype because the transaction state needs persistence while keeping the hackathon system simple and reproducible.

## 6. SSE + Polling

SSE provides the live offer experience.

Polling provides a fallback for demo-day reliability.

## 7. Synthetic Merchant Data

The prototype uses seeded synthetic merchants rather than claiming access to Paytm's production merchant database.

This makes the demo reproducible and keeps production-data claims out of the hackathon prototype.

## 8. Simulated Payments

Production Paytm payment APIs were not available to the prototype.

The payment experience therefore demonstrates the intended state transition using simulation.

The repository does not claim real-money movement.

## 9. Opportunity Pulse

An unfulfilled request is still valuable information.

Instead of treating only successful transactions as useful signals, the system exposes explicit unmet demand to merchants.

This creates a possible future loop:

```text
Unmet demand
     ↓
Merchant insight
     ↓
Merchant capability expansion
     ↓
Better future matching
```

## 10. Narrow Vertical Slice

The primary cake scenario was selected because it demonstrates multiple constraints and a complete end-to-end path.

The same architecture is intended to support other service categories represented in the synthetic merchant dataset.
