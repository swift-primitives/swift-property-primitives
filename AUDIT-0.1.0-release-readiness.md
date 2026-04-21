# Audit: swift-property-primitives 0.1.0 Release Readiness

> To investigate: read this file for full context. The parent conversation
> is continuing separate work — avoid modifying files under "Do Not Touch."

## Issue

`swift-property-primitives` is staged for its 0.1.0 tag. A prior audit
(2026-04-20 / 2026-04-21 — `Audits/audit.md`) ran against `Modularization`,
`Testing`, `Code Surface`, `Implementation`, `Documentation` skills and
closed 30+ findings. Since then the package has accumulated:

- CI pipeline switch from `xcodebuild docbuild` to `swift build`
  symbol-graph extraction (`d1cea57`), variant `.docc/` directories removed
- README Documentation/Distribution/Sources-layout sections rewritten for
  the v1.2.0 pipeline (`1aa4d01`)
- `[PRP-003]` typealias short-form sweep across 8 per-symbol articles and
  7 inline `///` examples (`ef72a75`), skill examples likewise (`5e28b36`)
- New `Phantom-Tag-Semantics.md` section on container-scoped `Property<Tag>`
  typealias resolution (`50515c7`)
- New experiment `property-typealias-extension-forms` (`98a1926`,
  `1ea8a9c` — code-surface recompile)
- `Property.Consuming.State` class → ~Copyable struct refactor cycle
  (`7d130f1` → revert → reapply → revert landing at
  class-based on `a54cab8`) — production kept Option A
- Four `language-semantic-*-replacement` experiments + companion research
  (`8945902`) — PARTIAL, retain all four Property families

The package has not been tagged. No prior release has shipped. The 0.1.0
tag cements API; a final pre-release audit pass is the last low-cost
opportunity to catch blockers before external consumers pin.

## Parent Context

The parent conversation just completed the typealias short-form sweep + new
Phantom-Tag-Semantics article + code-surface compliance fixups. Release
checklist item: run a systematic final audit before the `0.1.0` tag. The
audit is isolated from the parent — no files listed under "Do Not Touch"
because the tree is clean (all work committed).

## Relevant Files

Full package. Priority areas (since 2026-04-20 prior audit):

- `Package.swift` — tools-version 6.3, 5 Apple platforms, 7 library
  products + test-support product, 6 source targets
- `.github/workflows/ci.yml` — 4 CI jobs (macOS, Linux release, Linux
  nightly, Windows) + docs job
- `Sources/Property Primitives/Property Primitives.docc/` — single-catalog
  shape per `[DOC-019a]`; landing, tutorial, 6 topical articles, 11
  per-symbol articles
- `Sources/Property {Typed, Consuming, View, View Read} Primitives/` — 4
  variant targets, no `.docc/` (umbrella owns docs per `[DOC-020]`
  exception)
- `Sources/Property Primitives Core/` — internal Core target with
  `Property` + exports only
- `Tests/` — 7 test targets under the umbrella (compile + runtime tests)
  plus `Tests/Support/` fixtures
- `Experiments/` — 19 experiments including the new
  `property-typealias-extension-forms` and four
  `language-semantic-*-replacement`
- `Research/` — 10 research docs, all ACTIVE/DECISION
- `Audits/audit.md` — prior audit report (2026-04-20 / 2026-04-21), 30+
  findings, 4 remaining DEFERRED/OPEN to re-verify
- `Scripts/patch-umbrella-symbol-graph.py` — retained defensively, no-op
  under `swift build` extraction

## Do Not Touch

*Empty — tree is clean, all work committed at HEAD `50515c7`.*

## Scope

Full-package audit against all skill domains relevant at L1 for release
readiness. Two-part structure:

### Part A — Re-verify prior findings

The prior audit's 4 still-unresolved findings, each to be confirmed still
a correct classification given the current code state:

1. `[IMPL-068] / [IMPL-085]` — `Property.Consuming.State` `@unchecked
   Sendable` (DEFERRED — architectural redesign out of scope).
   Re-verify: Option C (~Copyable value-type) was investigated and
   reverted; the class-based Option A remains production. Does DEFERRED
   still match intent, or is there a less-invasive fix the recent
   experiments surfaced?
2. `[IMPL-087]` — `@Inlined` property wrapper blocked on
   `swiftlang/swift#81624` (DEFERRED — upstream). Check whether the
   `deferred/inlined` branch promotion plan remains the intended
   resolution; the `Inlined Primitives` target was already removed from
   `main`, so this finding's current package-local impact may be nil.
3. Any other audit-section follow-up items not marked RESOLVED
   (`grep -nE 'OPEN|DEFERRED' Audits/audit.md`).
4. Cross-skill note at the bottom of the Modularization section about
   `[MOD-015]` narrow-import migration — is this a release-blocker or
   post-0.1.0 polish?

### Part B — Fresh systematic audit

Apply `/audit` against all skills not yet covered OR where material
work has landed since 2026-04-20:

| Skill | Priority | Reason |
|-------|:--------:|--------|
| `code-surface` | **High** | This session made many doc/example edits + renamed `BufferLinked` → `Ring` mid-session; re-sweep for any stragglers |
| `documentation` | **High** | New `[DOC-019a]` single-catalog pattern; new `Phantom-Tag-Semantics` section; README rewrite; verify all cross-references resolve |
| `implementation` | **High** | Two refactor cycles on `Property.Consuming.State` landed at reverted class-based shape; verify no `@inlinable` / `public` / typed-throws regressions |
| `testing` / `testing-swiftlang` | **Medium** | Prior audit resolved the 5 findings; verify no new test-shape violations since |
| `memory-safety` | **Medium** | `~Copyable`, `@unsafe`, `unsafe ...` expression keyword use — `[MEM-*]` compliance across View family |
| `primitives` | **High** | Foundation-independence, tier placement, naming suffix — canonical L1 rules |
| `platform` | **Medium** | Package.swift settings, swift-language-modes, `[PATTERN-001–008]` |
| `swift-package` | **Medium** | Newly added to the superrepo's CLAUDE.md load-order — `[PKG-NAME-*]` package/namespace naming |
| `modularization` | **Low** | Prior pass was thorough; spot-check nothing regressed |
| `benchmark` | **Low** | No shipped benchmarks in the repo; check whether that is a finding or intended |
| `readme` | **Medium** | README just rewritten — check against `[README-*]` rules |

### Part C — Release-readiness checks

Not skill-driven, but blocking for a public 0.1.0 tag:

1. `Package.swift` — version-relevant metadata, tools-version (6.3),
   platforms minimum, swiftLanguageModes. No `// TODO` / `// FIXME` in
   source. `swift-api-breakage-allowlist` (if used) reviewed.
2. LICENSE present, correct (Apache 2.0 per L1 license table), up-to-date.
3. README — install snippet `.package(url: ..., from: "0.1.0")` matches
   the tag about to be cut. Badges, platform-support table, CI status
   badge reachable.
4. CI green across all 4 configured jobs (macOS 26 Xcode 26.4, Linux
   Swift 6.3 release, Linux 6.4-dev nightly, Windows Swift 6.3). Docs
   job green.
5. `Research/_index.json` and `Experiments/_index.json` internally
   consistent (all entries point at existing directories, all referenced
   crossRefs resolve).
6. `Audits/_index.json` — consider flipping `audit.md` status from
   `ACTIVE` to something reflecting a completed 0.1.0 review (or leaving
   `ACTIVE` with a new audit-section). Scheme is audit-specific.
7. No uncommitted debug artifacts in `Scripts/` or `Sources/`.
8. `.gitignore` covers `.build/`, `DerivedData/`, and the `docs-work`
   intermediates the CI pipeline writes under `$RUNNER_TEMP` (local
   equivalents).
9. Tag plan: confirm `0.1.0` is the intended version. No prior tags
   exist on the repo (`git tag` returned empty), so this tag establishes
   the base version.

### Out of scope

- `deferred/inlined` branch work (tracked separately; 0.1.0 ships
  without `Inlined Primitives`).
- `project_lifetime_self_on_escapable_return_swift63_break.md` batch
  (5 experiments broken on Swift 6.3 per memory; `[PROJECT-*]` tracking).
- Ecosystem-wide concerns that depend on post-0.1.0 downstream adoption
  (narrow-import migration `[MOD-015]`).

### Procedure

Run `/audit` with swift-property-primitives as the target package. For
Part A, open `Audits/audit.md` and assess each remaining finding against
current code state; flip to RESOLVED / keep DEFERRED / escalate to OPEN
as warranted. For Part B, append a new top-level section per skill to
`Audits/audit.md`, following the same table format used by the 2026-04-20
sections. For Part C, enumerate release-readiness items as an additional
section (or separate list — scheme-driven).

Per `[HANDOFF-018]`: the audit skill's conditional clauses ("acceptable
to skip if …") are preferences for unusual cases; 0.1.0 release readiness
is the default case and warrants the stricter reading.

Per `[HANDOFF-019]`: any fixes that arise during the audit that span
multiple files or phases — commit per phase, don't batch.

## Findings Destination

Append new sections to `Audits/audit.md` (do not create a new file;
the existing file is the per-package audit artifact). Update
`Audits/_index.json` if the audit's status semantics change (e.g.,
ACTIVE → SUPERSEDED by a new section).

For Part A re-verifications, update the existing tables in-place —
flip Status column for each row that changed classification, add a
dated line like `RESOLVED 2026-04-21 (re-verified during 0.1.0
release-readiness audit)` where appropriate.

## Resume Instruction

```
Read /Users/coen/Developer/swift-primitives/swift-property-primitives/AUDIT-0.1.0-release-readiness.md — it contains the final pre-release audit brief for swift-property-primitives' 0.1.0 tag. Read the full document, then invoke the /audit skill against the target package. Write findings to Audits/audit.md per the Findings Destination section. Do not modify files under "Do Not Touch" (currently empty — tree is clean).
```
