# PWA Task Checklist

Last updated: 2026-05-22

## Product Direction

Convert My Daily Closet into a phone-first PWA before investing further in native iOS distribution.

Reason:

- The main user loop is camera/upload heavy, but it can be validated faster through mobile web.
- PWA keeps the beta path simpler: one HTTPS URL, no TestFlight setup, faster iteration.
- Native iOS can remain a preview shell until retention and upload quality are proven.

## Phase 1: Installable Preview PWA

Status: in progress.

- [x] Add PWA manifest.
- [x] Add app icon asset.
- [x] Add mobile theme color and Apple web app metadata.
- [x] Add production-only service worker registration.
- [x] Cache app shell pages for basic offline fallback.
- [ ] Verify install prompt / Add to Home Screen on Android Chrome.
- [ ] Verify Add to Home Screen on iPhone Safari.
- [ ] Replace SVG-only icon with generated PNG icons: 192, 512, apple-touch-icon.
- [ ] Add a simple offline fallback screen for failed navigation.
- [ ] Add PWA install/readiness notes to README.

## Phase 2: PWA Camera And Upload Readiness

- [ ] Verify mobile Safari camera capture from `/closet/new`.
- [ ] Verify Android Chrome camera capture from `/closet/new`.
- [ ] Compress large phone photos before upload.
- [ ] Add upload progress UI.
- [ ] Add upload retry and failure states.
- [ ] Keep preview-safe local upload path working without Supabase.
- [ ] Keep real cloud upload path behind valid Supabase config.
- [ ] Test with 10 to 20 real clothing photos.

## Phase 3: PWA App Shell UX

- [ ] Port the static dashboard reference into the real Next.js UI where useful.
- [ ] Make Closet the installed-app landing route.
- [ ] Tighten 390px, 430px, and 375px layouts.
- [ ] Make Add, Closet, Stylist, Resale primary bottom-nav actions on mobile.
- [ ] Reduce form friction after recognition; default to editable confirmation only when needed.
- [ ] Add empty, loading, error, and offline states for every core route.

## Phase 4: Cloud Beta

- [ ] Restore valid Supabase project.
- [ ] Rotate any exposed service role key.
- [ ] Re-run Supabase schema and storage setup.
- [ ] Run `pnpm smoke:real`.
- [ ] Run `pnpm smoke:routes`.
- [ ] Run `pnpm smoke:preview`.
- [ ] Verify auth, upload, save, refresh, recommendation, resale draft on real phone.
- [ ] Deploy to a stable HTTPS URL.

## Phase 5: External Beta Readiness

- [ ] Add Privacy Policy.
- [ ] Add Terms of Service.
- [ ] Add account deletion or deletion request path.
- [ ] Add support email.
- [ ] Add cost and rate guardrails for AI/upload routes.
- [ ] Add basic analytics for activation events.
- [ ] Add production error logging.
- [ ] Freeze open-source boundary before public promotion.

## Current Next Step

The immediate product next step is not native iOS polish. It is:

1. Finish PWA installability verification.
2. Restore real Supabase.
3. Test the mobile web upload loop on a real phone.

