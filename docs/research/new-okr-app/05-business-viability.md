# 05 — Business Viability

Is this a business? Honest read, with kill criteria. Market-size and competitor numbers
are `[verify]`-grade until a live research pass is done.

## The uncomfortable priors

State these up front because they, not the product ideas, decide viability:

1. **Goal software has a structural engagement problem.** The product's value depends on
   a weekly behavior (check-ins) that organizations demonstrably stop doing. Every
   incumbent's churn story is the same. Our whole thesis (connectors + AI removing the
   toil) is a bet that the engagement problem is a *toil* problem, not a *motivation*
   problem. If it's motivation, no feature fixes it. **This is the #1 assumption to
   test.**
2. **Microsoft exited.** Viva Goals had free distribution inside Teams and still couldn't
   sustain engagement. Interpreting this as "bundlers can't do focus" is the bull case;
   "the category can't retain" is the bear case.
3. **The category has weak pricing power at SMB.** Goal tools price ~$5–10/user/mo at SMB
   `[verify current price points]`; buyers compare against Notion templates and
   spreadsheets (≈ free). Real ACVs live mid-market/enterprise, which demands SSO/SCIM/
   security posture and a sales motion.
4. **It's a crowded, post-hype category.** Differentiation must be felt in the first
   session (the connectors demo), not explained.

## Why it might work anyway

- **The engagement fix is newly possible.** Connectors + AI-drafted check-ins didn't
  exist as a cheap-to-build combination until ~2023–24. Incumbents carry 2018
  architectures where metrics are manual fields; retrofitting a metric graph under an
  existing product is much harder than building on one.
- **Retention economics dominate this category.** A tool that keeps teams checking in for
  12+ months at even modest ACV beats incumbents on LTV without beating them on logo
  count. The 8-consecutive-weeks gate (doc 01 §4) is the leading indicator.
- **The wedge is measurable in discovery.** "Would goals that update themselves have kept
  you on the tool you churned from?" is directly askable.

## Pricing sketch (hypothesis)

- **Free:** 1 team, manual measures, Slack check-ins. The Notion-replacement tier.
- **Team ($8–12/user/mo `[verify vs market]`):** connectors (the paywall line — metered
  or gated by source count), AI drafts/digest, scorecards.
- **Business ($15–20/user/mo):** SSO/SCIM, org rollups, API, framework templates,
  audit.
- Connectors as the paywall aligns price with the moat and with delivered value
  (auto-updating = the thing they'd churn without).

## Cost/effort shape

- v1 (doc 01 §4) is a small-team build: standard Rails-or-equivalent monolith + Slack app
  + Postgres (doc 03 is deliberately boring infra). The expensive parts are v2:
  connector breadth (each source is an integration to maintain) and AI cost per check-in
  (bounded — drafts are short-context; the exec digest is the priciest call).
- Biggest hidden cost: **connector maintenance treadmill** (APIs change, OAuth apps need
  review). Mitigation: start with 3–4 connectors max (sheet, one warehouse, Jira/Linear,
  Stripe) and a generic webhook.

## Risk register

| Risk | Severity | Mitigation / test |
|---|---|---|
| Engagement is motivational, not toil (thesis fails) | Fatal | Discovery interviews + v1 8-week retention gate before any v2 spend |
| Tability (or Perdoo) ships connectors+AI first | High | `[verify their roadmaps]`; speed on v2; positioning on metric-graph depth |
| PLG ACVs too small to sustain; mid-market needs sales before we're ready | High | Keep option C (doc 04) warm; SSO-ready architecture, don't build it early |
| AI features commoditize (every tool has drafts by 2027) | Medium | Moat is the metric graph + connector data, not the model calls |
| Category re-contracts (post-OKR fatigue → nobody buys goal tools at all) | Medium | KPIs-only/scorecard mode (docs 02/03) serves the post-goal buyer with the same build |
| EOS/framework IP entanglement if pursuing option B | Low (avoidable) | Only enter with an EOS-ecosystem partner |

## Kill / proceed criteria

- **Proceed past discovery** only if ≥6/10 churned-tool interviewees name manual updates
  or staleness (not "we stopped believing in OKRs") as the churn cause.
- **Proceed past v1** only if ≥50% of onboarded teams hit the 8-consecutive-week check-in
  streak without founder hand-holding.
- **Kill or pivot** if v1 retention fails after Slack-prompt + confidence UX iterations —
  that result would mean the engagement problem is motivational, and the remaining
  pivot is the KPIs-only scorecard product for data-mature teams (same schema, different
  buyer).

## Next steps (the actual queue)

1. **Live competitive research pass** — clear every `[verify]` in docs 04/05 (candidates:
   deep-research run on Tability/Perdoo/Quantive/Ninety/Lattice 2026 state, pricing,
   AI/connector shipping status).
2. **Discovery interview script + target list** — 5–10 churned-OKR-tool orgs, 3–5
   current-tool users; script keyed to the kill criteria above.
3. **Decide beachhead** (doc 04) from interview data.
4. **Product brief / PRD** for v1 (the loop) — candidate for the `cpo`/`product-owner`
   agent flow once 1–3 are done.
5. Only then: v1 build plan and estimate.
