# Open Source Strategy

Last updated: 2026-05-22

## Decision

Keep the production PWA private. Open-source only safe preview materials and infrastructure-adjacent helper code.

## Keep Private

- Full Next.js production app source.
- Supabase schema evolution beyond minimal examples.
- Auth, storage, and user data integration details.
- OpenAI prompts, ranking logic, resale logic, and recognition heuristics.
- Product roadmap details that reveal business strategy.
- Real environment variables, service role keys, API keys, logs, and user data.
- Cost guardrail thresholds tied to real usage.
- Private GitHub issues, beta tester notes, and launch plans.

## Safe To Open Source

- Public product README with high-level concept.
- Native SwiftUI preview shell with local sample data only.
- Generic image background-removal helper script.
- Sample wardrobe data with fake/demo items.
- Sanitized PWA migration checklist.
- Sanitized open-source boundary document.
- Setup notes that use placeholders only.

## Optional Later

Open-source a small standalone package only if it is generic enough:

- image normalization utility
- demo-only wardrobe schema
- local-only PWA shell starter

Do not open-source anything that lets competitors reconstruct the core stylist/resale loop.

## GitHub Layout

Private source of truth:

- private production repository
- contains the production Next.js/PWA source, private docs, and deployment configuration

Public/open-source preview:

- public preview repository
- contains only safe sample data, generic scripts, preview shell code, and sanitized docs

## Sync Rule

Before syncing to the public repo:

1. Copy only allowlisted docs/scripts/sample data.
2. Search for keys, project URLs, emails, and real user content.
3. Keep private implementation files out of the public repo.
4. Commit private repo and public repo separately.

## Current Public Sync Scope

For this PWA turn, public sync should include:

- sanitized `PWA_TASK_CHECKLIST.md`
- sanitized `OPEN_SOURCE_STRATEGY.md`
- updated public `OPEN_SOURCE_BOUNDARY.md`
- public README note that the production PWA remains private

Do not copy the new service worker, manifest, or production Next.js app source to the open-source repo.
