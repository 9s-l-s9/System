# Research-Paper Default Design Skill

Install this folder as an Agent Skill.

## Files

- `SKILL.md` — the actual skill: trigger policy, palette, colour modes, layout grammar, component patterns, imagery, data visualisation patterns, copywriting, accessibility, final checklist.
- `eval_queries.json` — trigger test queries.
- `assets/style-tokens.css` — reusable CSS variables and utility classes for the page palette, masthead, title block, specifications panel, booktabs tables, terminal blocks, and colophon.
- `assets/html-skeleton.html` — a single-file starting point for standalone HTML artifacts.
- `assets/data-viz.css` — companion stylesheet for the seven named data-visualisation patterns (`.scatter`, `.contour`, `.strat`, `.anno`, `.bars`, `.strat-dual`, `.contour-dual`).
- `assets/data-viz-defs.svg` — shared SVG `<defs>`: five stratigraphic hatch patterns and a 260-point Clifford attractor cloud, all using `currentColor` so they inherit each figure's ink.
- `assets/accent-test.html`, `assets/data-patterns.html`, `assets/dark-substrate-test.html`, `assets/dark-substrate-support-test.html` — staging/demo artifacts for in-flight pattern work. Not canonical; folded into SKILL.md and dropped once settled.

## Design intent

This skill makes HTML and design artifacts default to a typeset technical-document style: white page, near-black monospace body in a Courier-led screenplay register, a left-aligned single column, black terminal blocks as the only chrome-dark surface, booktabs tables, hairline rules, numbered sections, dense indexed metadata. Imagery is monochrome or duotone — blueprint hairline drawings, dot-matrix halftones, orange/red duotone halftones, monochrome photography. The page should feel like a research paper or engineering manual, not a marketing site and not a terminal UI.

## Colour modes

Three modes, used as little as possible:

- **Mode 1 — Black only.** The default. No accent ink. Most documents.
- **Mode 2 — Single ink (red *or* blue).** When the artifact has a data layer that needs to be distinguished from structure. One ink per artifact; the ink is the data.
- **Mode 3 — Dual ink (red leads, blue supports).** When the data has an asymmetric relationship — signal vs context, active vs baseline, overlay vs substrate. Strict role hierarchy.

The two accent inks (`#d83a2f` process red and `#2e62c4` process blue, with lifted variants for dark substrate) appear only on the data and diagram surface of figures and on a narrow editorial register (state cells, revision marks, footnote markers, drop-cap initials). Never as chrome, links, dividers, paint, or decoration. See SKILL.md § Color modes for the full rule set.

## Trigger philosophy

The description is intentionally broad for visual artifacts. It should trigger for HTML documents, websites, web reports, architecture overviews, project knowledge bases, mini concepts, dashboards rendered as readable status reports, and other designed outputs — even when the user does not explicitly ask for a style.
