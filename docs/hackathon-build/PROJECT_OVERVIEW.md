# Paytm Intent Mesh — Project Overview

## 1. Overview

Paytm Intent Mesh is a working two-sided prototype of an agentic commerce layer for offline India.

The customer describes an outcome using natural language or speech. The system converts that request into a structured **Intent Packet**, routes it to capable nearby merchants using deterministic matching, receives merchant offers through a Soundbox-style interface, and closes the transaction through a simulated Paytm payment.

> **Human language becomes the merchant API.**

The prototype is designed around the existing Paytm consumer and merchant ecosystem rather than requiring every offline merchant to build a separate digital API.

## 2. Problem

Many offline merchants can already accept digital payments but may not have:

- a public API;
- a structured catalogue;
- live inventory infrastructure;
- a dedicated digital storefront;
- developer resources for AI-agent integrations.

At the same time, customers often know the outcome they want without knowing which merchant can provide it.

Intent Mesh connects these two sides.

## 3. Core Flow

```text
Customer need
      ↓
Natural language / speech
      ↓
Intent Packet
      ↓
Hard-constraint filtering
      ↓
Deterministic merchant ranking
      ↓
Merchant request
      ↓
Live merchant offer
      ↓
Customer selection
      ↓
Simulated Paytm payment
      ↓
Fulfilment confirmation
      ↓
Opportunity Pulse / demand intelligence
```

## 4. Consumer Experience

The consumer can:

1. Enter or speak a request.
2. Review the interpreted Intent Packet.
3. Ask the system to find a merchant.
4. View live merchant offers.
5. Select an offer.
6. Complete a simulated Paytm payment.
7. Receive closed-loop confirmation.

The primary demo request is:

> “Mujhe kal 7 baje tak ₹800 ke andar 1 kg eggless chocolate cake chahiye.”

## 5. Merchant Experience

The merchant side is represented through a Soundbox emulator.

A merchant can:

- receive a customer request;
- review the requested item/service and constraints;
- provide a price and fulfilment estimate;
- accept or decline;
- participate in the offer flow;
- receive a simulated payment confirmation.

The prototype also includes an Opportunity Pulse view for explicit unfulfilled demand.

## 6. Why This Matters

The system changes the commerce loop from:

```text
Payment
```

to:

```text
Need → Intent → Capability → Match → Offer → Payment → Fulfilment
```

This provides structured signals about customer demand and merchant capability while keeping the merchant interaction simple.

## 7. Prototype Scope

The implementation uses synthetic merchant data and simulated payment rails.

It does not claim:

- production Paytm payment integration;
- production merchant inventory;
- physical Soundbox firmware integration;
- production KYC/identity infrastructure;
- real-money movement;
- production delivery infrastructure.

These boundaries are intentional for the hackathon prototype.
