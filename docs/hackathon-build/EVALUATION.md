# Paytm Intent Mesh — Evaluation

## 1. Evaluation Scope

The repository contains a 30-case synthetic evaluation covering multilingual and code-mixed requests supported by the prototype.

The evaluation is intended to verify the behavior of the checked-in prototype rather than make general production accuracy claims.

## 2. Metrics

The evaluation checks:

1. Category extraction.
2. Budget extraction.
3. Relevant merchant retrieval in Top-3.
4. Parsing and matching latency.

## 3. Current Results

The measured deterministic fallback results are:

| Metric | Result |
|---|---:|
| Category extraction | 100% |
| Budget extraction | 100% |
| Relevant merchant in Top-3 | 100% |
| Median parse + match latency | ~0.05 ms |

## 4. Interpretation

The results apply only to the checked-in 30-case prototype evaluation set.

They should not be interpreted as:

- general multilingual model accuracy;
- production merchant-retrieval accuracy;
- real-world marketplace performance;
- a benchmark of Sarvam's production models.

## 5. Automated Tests

The backend test suite covers the main transaction flow and important failure cases, including:

- complete cake transaction;
- hard-constraint filtering;
- service extraction;
- merchant decline;
- duplicate merchant response;
- duplicate payment;
- no-match recovery.

The recorded expanded verification reached five passing backend tests.

## 6. SSE Verification

The live transaction path was verified to deliver:

```text
connected
offer_received
offer_accepted
payment_received
```

in order.

## 7. Build Verification

Frontend production build:

```bash
cd frontend
npm run build
```

Backend tests:

```bash
cd backend
../.venv/bin/pytest -q
```

Evaluation:

```bash
python evaluation/run_evaluation.py
```
