# Greenfield OKR App — Research Package

Research base for a from-scratch, organization-focused goal-tracking product. Informed by
maintaining fluxday (2016-era classic OKR tool) and by where the goal-tracking market has
moved since. Three research tracks:

| Doc | Track | Question it answers |
|---|---|---|
| [01-product-research.md](01-product-research.md) | Product | What should the product be? Failure modes, core loop, UX bets |
| [02-okr-frameworks-landscape.md](02-okr-frameworks-landscape.md) | Product | What goal frameworks exist post-OKR, and what does each demand of the product? |
| [03-data-model.md](03-data-model.md) | Product | The framework-agnostic schema that supports all of them |
| [04-gtm-research.md](04-gtm-research.md) | GTM | Who do we sell to first, against whom, through what motion? |
| [05-business-viability.md](05-business-viability.md) | Business | Is this a business? Pricing, market structure, risks, kill criteria |
| [06-eos-rocks-and-leavebalance-integration.md](06-eos-rocks-and-leavebalance-integration.md) | Product + GTM | EOS/Rocks feature set, and building it as a pilot module inside LeaveBalanceApp (Path C recommendation) |

## Status / provenance

- **Date:** 2026-07-13. Drafted from working knowledge (model cutoff Jan 2026) plus lessons
  from the fluxday codebase. Competitive and market-size claims in docs 04/05 are flagged
  `[verify]` where they need a live web-research pass before being used in a deck or plan.
- **This is research, not a decision.** The explicit next steps are at the bottom of doc 05.

## The one-paragraph thesis

Classic OKR tools fail through set-and-forget goals, manual metric updates, cascading
theater, and entanglement with performance reviews. The winning 2026 shape is a
**check-in-first** product built on a **persistent metric graph with data connectors**,
where goals are time-boxed targets pinned to metrics, alignment is loose links rather than
a forced tree, and AI does the toil (drafting check-ins, linting goal quality, flagging
stale/at-risk goals, writing the exec digest). The data model is framework-agnostic —
OKRs, NCTs, EOS Rocks/Scorecards, 4DX WIGs, and North Star trees are terminology packs
over one schema — but the go-to-market must be opinionated about exactly one framework
community as the beachhead.
