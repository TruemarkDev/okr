# 04 — GTM Research

Who to sell to first, against whom, through what motion. Competitive claims are from
working knowledge as of early 2026 — items marked `[verify]` need a live research pass
before use in a deck.

## Market structure (as of early 2026)

The goal-tracking market split into four camps after the 2021–22 OKR hype cycle deflated:

1. **HR-suite bundlers** — Lattice, Leapsome, Betterworks, 15Five. Goals as a module
   beside performance reviews and engagement surveys. Sell to HR/People teams,
   mid-market/enterprise. Structurally committed to failure mode F4 (goals entangled
   with reviews) — that's our wedge against them, and also why buyers with an HR-led
   budget will pick them anyway.
2. **Dedicated OKR platforms** — Quantive (ex-Gtmhub), WorkBoard, Perdoo, Profit.co.
   Enterprise-leaning, heavy, consultant-adjacent. WorkBoard sells the operating rhythm
   to Fortune 500s. This camp was hit hardest by OKR fatigue. `[verify: Quantive and
   WorkBoard current state — funding, layoffs, repositioning around "AI strategy
   execution"]`
3. **Lightweight check-in-first tools** — Tability is the archetype (small team,
   opinionated, PLG). Closest to our product thesis. `[verify: Tability's current
   pricing, team size, and whether they've added connectors/AI]`
4. **Framework-vertical tools** — Ninety.io (EOS only) and the EOS-adjacent cluster
   (Bloom Growth, etc.). Prove the "one framework community as beachhead" strategy:
   Ninety grew large serving only EOS-running SMBs. `[verify: Ninety ARR/valuation
   signals]`

**Structural events that shape the opening:**
- **Microsoft retired Viva Goals (2024)** after acquiring Ally.io for ~$300M in 2021 —
  displaced customers exist, and it signals big-suite bundling of OKRs *failed* even with
  free Teams distribution. Both a caution (engagement is genuinely hard) and an
  opportunity (the giant left the field).
- **OKR fatigue is the dominant buyer sentiment.** Positioning as "an OKR tool" in 2026
  buys the incumbent category's baggage. Position against the failure modes ("goals that
  update themselves", "the Monday meeting page") rather than the acronym.
- **AI resets the demo.** Every incumbent has bolted a copilot onto a 2018 product; a
  product where AI is the check-in engine (doc 01 §2) demos differently. `[verify: what
  Lattice/Perdoo/Quantive AI features actually shipped vs announced]`

## Beachhead options

| Option | Motion | Pros | Cons |
|---|---|---|---|
| **A. SMB product/eng teams, check-in-first** (Tability's lane) | PLG, self-serve, Slack-led | Fast feedback, no SSO/SCIM in v1, our thesis fits it exactly | Small ACVs, churny segment, Tability incumbent |
| **B. EOS-running SMBs** (Ninety's lane) | Community-led (EOS Implementers as channel) | Proven willingness to pay for framework-vertical; scorecard+connectors is a real gap `[verify: does Ninety have metric connectors]` | EOS Worldwide licensing/ecosystem politics; not our native community |
| **C. Data-mature mid-market, "metrics-first goals"** (North Star / WBR angle) | Sales-assisted, land via data team | Connector moat lands hardest here; least crowded framing | Longer cycles, needs SSO/SCIM/security earlier, harder to demo self-serve |
| **D. Viva Goals / legacy-tool displacement** | Outbound to a finite list | Named, reachable accounts | One-time pool `[verify: how much remains unclaimed in 2026]`; they may have churned from the *category*, not the tool |

**Working recommendation: A as the entry, C as the expansion.** *(Superseded in part by
doc 06: with LeaveBalanceApp in the portfolio, option B becomes runnable as a low-cost
pilot module with distribution we already own — see doc 06 Path C.)* Start in the
check-in-first PLG lane where v1 (no connectors, no SSO) is sellable, differentiate
against Tability with connectors + AI-drafted check-ins as they ship in v2, then move
upmarket on the metrics-first story where the moat is strongest. Option B is the highest
"buy vs build a community" risk despite good economics — revisit only with an EOS-side
partner. This ordering is a hypothesis to test in discovery interviews, not a decision.

## Positioning (draft)

- **Category frame:** not "OKR software" — *"goal tracking that updates itself."* The
  demo is: connect Stripe/PostHog/Jira in 10 minutes, watch the KRs move on their own,
  get Monday's digest written for you.
- **Against HR suites:** "your goals shouldn't live inside your performance-review tool —
  that's why nobody updates them."
- **Against heavyweight OKR platforms:** "you don't need a consultant and a 6-week
  rollout to know if you're on track."
- **Against spreadsheets/Notion (the real competitor at SMB):** "the spreadsheet doesn't
  ping the owner, chart confidence, or notice it's been stale for three weeks."

## Channel & motion notes

- **Slack/Teams app directories** are a real acquisition surface for check-in-first tools
  — the integration *is* the product's front door.
- **Content wedge:** the framework-landscape material (doc 02) is itself the content
  strategy — "OKRs vs NCTs vs Rocks" comparison content ranks and converts framework
  shoppers; we hold genuinely deep material here.
- **Template/community wedge:** free goal-linter or "KR quality checker" as a top-of-
  funnel AI tool.
- **Discovery to run before any of this (doc 01 §4):** 5–10 interviews with orgs that
  abandoned an OKR tool; 3–5 with current Tability/Perdoo/Lattice-goals users; the churn
  reasons and "what would make you switch" answers pick the beachhead for real.
