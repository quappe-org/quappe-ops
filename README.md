# quappe-ops

Operational setup for running the Quappe platform in production.

> **Status: placeholder / vision.** Not built yet — on purpose. Quappe today is
> a single service + a single web app; a SQLite file on one server carries it a
> very long way (see the scale note in the docs). Operational infrastructure is
> an answer to load we don't have yet. This repo exists so the intent is
> recorded, not so we build it prematurely.

## Intended scope (later, when load demands it)

- **Kubernetes** manifests / Helm charts for `quappe-service` and `quappe-web`.
- **Prometheus** + Alertmanager for metrics and alerting.
- **Log shipping** to OpenSearch (or similar) from the k8s workloads.
- Ingress / TLS, secrets, backup of the service's database volume.
- A DB connection bouncer layer — only relevant once the service moves off
  single-instance SQLite to Postgres with multiple replicas. Not before.

## Guiding principle

Build an operational capability when a real operational pain appears — not in
anticipation. Each piece here should trace back to a concrete need (an incident,
a scaling wall, a compliance requirement).

## Platform

Part of the Quappe platform: **quappe-service** (API/DB/logic) ·
**quappe-web** (UI) · **quappe-ops** (this) · **quappe-insight** (analytics) ·
**quappe-docs** (the idea).

## License

PolyForm Noncommercial 1.0.0 — see [`LICENSE`](./LICENSE).
