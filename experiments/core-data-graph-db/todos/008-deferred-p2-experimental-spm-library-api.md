---
status: deferred
priority: p2
issue_id: "008"
tags: [spm, api-design, library]
dependencies: ["003", "004", "005"]
---

# Experimental SPM Library API

Turn the Core Data graph spike into an experimental Swift Package Manager library where users can model graphs, optionally subclass node/edge managed-object types, and run algorithms over snapshots.

## Plan

See `docs/plans/2026-05-22-experimental-spm-library-api-plan.md`.

## Deferred Because

This is a promising direction, but we are parking it for now to avoid prematurely productizing the graph experiment before the REST-layer experiment gets its own first spike.

## Resume Criteria

- Decide package name and public API stance.
- Choose property-graph-first, subclass-first, or hybrid extension model.
- Create a milestone plan from the parked API plan.
