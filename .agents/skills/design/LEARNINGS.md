# Design Skill — Iteration Learnings

This file is a staging area for design discoveries that aren't yet in `SKILL.md`. It captures *what we know works*, *what we tried and rejected*, and *what is still unresolved*. Once an item is settled, it gets folded into `SKILL.md` and (if needed) the assets.

Last updated: 2026.06.21.

---

## Settled — monospace screenplay register + left-aligned column (folded 2026.06.21)

A direction change from the serif research-paper baseline. The body face is now a **Courier-led monospace** (typewriter / shooting-script voice) and the page column is **left-aligned** rather than centered. Folded into `SKILL.md`, `assets/style-tokens.css`, all five `assets/*.html` demos, and `README.md`.

- **Implementation via the `--serif` token, not a rename.** The whole system already routes body, headings, and every label register through `var(--serif)`. Repointing that one token at `"Courier Prime", "Courier Screenplay", "Courier New", "Nimbus Mono PS", Courier, …` flips the entire document to monospace with no per-rule edits. The token keeps the name `--serif` (now a misnomer) deliberately — renaming it would touch dozens of rules across CSS + 5 demos for zero visual gain. `--mono` stays a *tighter* identifier face for code/paths/tabular cells, so two monospace voices still read as distinct.
- **Left-aligned = `.page { margin: 0 }`** (was `margin: 0 auto`). Column hugs the left edge; `max-width` measure unchanged.
- **Register C lost small caps.** Courier has no `smcp`/`c2sc` features, so the state-tag register (`Stable` / `Watch` / `Transitional`) became **uppercase + letterspaced** instead. Registers A (uppercase letterspaced) and B (italic lowercase) survive the family change intact — they were always distinguished by case/italics, not by family.
- **Font availability caveat (unresolved).** Courier Prime / Courier Screenplay are not installed by default on most systems; rendering falls back to `Courier New` (universally present). Look is correct but less refined. A self-hosted `@font-face` for Courier Prime would fix this for offline/standalone artifacts — not yet wired in.
- **Older serif-only history left intact below.** The "typography reduction" entry that follows describes the *previous* serif-only system; kept as a record, superseded by this entry for the body-face question.

---

## Settled — already in SKILL.md

### Color modes
- Three modes (Mode 1 black-only / Mode 2 single ink / Mode 3 asymmetric dual ink).
- Process inks: red `#d83a2f` (light) / `#ee4d42` (dark); blue `#2e62c4` (light) / `#5a8de8` (dark).
- Mode 3 asymmetry: red leads (primary signal, active, overlay), blue supports (baseline, reference, substrate).
- Editorial register: red allowed on `WATCH` cells, revision markers, footnote numerals, drop-cap initials. Never chrome.

### Data viz patterns
- Seven named patterns: `.scatter` `.contour` `.strat` `.anno` `.bars` `.strat-dual` `.contour-dual`.
- Live as assets in `assets/data-viz.css` and `assets/data-viz-defs.svg`.
- Hatch patterns use `currentColor` so they inherit each figure's ink.
- 260-point Clifford attractor cloud shipped as a reusable `<defs>` element.

### Anti-patterns (now in SKILL.md "Explicit failure patterns to avoid")
- Soft-alpha translucent zone fills → reads as dashboard infographic.
- Node-and-edge graphs with primary/secondary dotted lines → reads as d3 / Mermaid / graphviz default.
- Symmetric two-colour data series with no role asymmetry → infographic.
- Concentric circles with soft fills → audience-target marketing slide.
- Procedural halftone, dot-matrix, or ASCII SVG generated inline → amateurish.
- Accent ink on links, buttons, dividers, badges, section paint → modernizes the artifact.

---

## Settled — typography reduction (folded 2026.06.21)

Folded into `SKILL.md § Typography`, `assets/style-tokens.css`, and `assets/data-viz.css`. The `--sans` token is removed everywhere; serif + mono carry the whole system.

- **`--sans` dropped entirely.** Two families (serif + mono). Sans-serif was a modernist intrusion; the skill is a "research paper", canonically serif-only with mono for code. All chrome labels (masthead, byline, section markers, `§` subs, dict eyebrows, notes, table headers/captions, SVG axis labels) moved to `var(--serif)`.
- **Three label registers in the serif family**, kept distinct:
  - **A — uppercase + letterspaced**: structural labels (masthead identity, byline, section markers, `§` subs, specs-panel `dt` eyebrows, note prefix). Roman inscription register.
  - **B — italic lowercase**: descriptive labels (figcaption, table caption, column headers). Tufte / mathematical-paper register; same voice as plot axes in `accent-test.html`.
  - **C — small caps**: state tags in tables (`Stable`, `Watch`, `Transitional`). Quasi-tag register. Uses `font-variant-caps: all-small-caps; font-feature-settings: "smcp" 1, "c2sc" 1` for true small caps where the font supports them.
- **Sizes consolidated** from ~14 distinct values to ~10 (could go further to ~7 if `11/11.5/12/12.5` collapse).

### Tried and rejected
- **Single italic-serif voice for all labels.** Tested in a second mock. User judgment: lost structural hierarchy; section markers no longer read as authoritative; the page felt too soft. The three-register version above wins.

### Done (2026.06.21)
- SKILL.md `## Typography` now documents the three label registers (A structural / B descriptive / C state tags) explicitly, and the "two families only" rule.
- `assets/style-tokens.css`: `--sans` token removed; all chrome labels use `var(--serif)`.
- `assets/data-viz.css`: all `var(--sans)` SVG axis/label references switched to `var(--serif)`.

### Still pending
- Optional: extract the three registers into named utility classes (`.eyebrow` / `.descriptive` / `.tag`) rather than per-component declarations. Cosmetic; current per-component approach works.
- Demo/test HTML is now serif-only too (`accent-test.html` converted 2026.06.21; `dark-substrate-*.html` and `data-patterns.html` were already clean). These remain staging artifacts to be dropped once their patterns fold into SKILL.md.

### Pattern proposals in flight (2026.05.17)
Demo file: `assets/data-patterns.html`. Currently fourteen variants across three surfaces (down from thirteen variants × four surfaces after metadata restructure):

- **Dictionaries (4):** K1 inline strip · K2 hairline grid (default) · K3 column-aligned vertical · K4 hanging-key definition. Plus `dl.meta` (the dark data plate) preserved as a dossier-only variant — earned, not default.
  - **Settled 2026.05.17:** folded into SKILL.md § Dictionaries (replacing the old § Specifications panel subsection), and into `assets/style-tokens.css` as four new utility classes. The dark plate (`dl.meta`) kept in both files with updated framing — it's still one of the three legitimate "earned dark surfaces" but reserved for genuine dossier / archival artifacts where the metadata is the centerpiece. K2 (`dl.dict-grid`) is the new default.
  - K5 S-expression variant (briefly added during a digression about applying Lisp form to design patterns) was dropped along with the rest of the lisp idea per user feedback. The lispy `(operator args)` header-line proposals (V1/V2/V3) were also dropped.
  - **Style change:** the dark plate's `dt` eyebrows now use `var(--serif)` instead of the soon-to-retire `var(--sans)` — a small step toward the broader sans removal still pending.
- **Ordered lists (3):** O1 plain numbered · O2 hairline-separated procedure · O3 bracketed references
- **Unordered lists (4):** U1 plain bulleted · U2 em-dash markers · U3 indented (no marker) · U4 hairline-separated changelog
- **Tables (3):** T1 booktabs (current default) · T2 matrix (2D adjacency/dependency) · T3 compact reference

#### Steckbrief — added 2026.05.17
Composite block: image + dict as a subject-identification card. Long print tradition (wanted posters, library catalogue cards, museum specimen sheets, archaeological find sheets). Lives as `section.steckbrief` with `figure.steckbrief-image` left and any dict variant right (default pairing: `dl.dict-grid`). Image takes 180px on wide viewports, stacks above the dict under 600px. Currently one variant (S1 — image left); could grow to S2 (image right mirror) or S3 (image above) if the need arises. The image rule from SKILL.md § Imagery applies: monochrome, blueprint hairline, dot-matrix halftone, or duotone — never decorative stock photography. Demonstrated in `data-patterns.html` § 2 using the dot-matrix Doric column reference image (`../601e5f34e2badeb90324506dc6a8a1e9.jpg`) as a stand-in subject. Pending SKILL.md fold.

CSS classes for the dict variants are named `.dict-strip`, `dl.dict-grid`, `dl.dict-aligned`, `dl.dict-hanging` — reflecting the CS-correct framing.

Once user picks the keepers per section, fold the relevant CSS into `style-tokens.css` and document the patterns in `SKILL.md` § Component patterns. Drop the rejected variants from the demo file.

### Bugs fixed (2026.05.17)
- **TOC whitespace bug.** The inline TOC in `html-skeleton.html` rendered `1Summaryoverview` without gaps between the number, title, and right-side annotation. Root cause: `display: grid` was set on `<li>`, but the spans live inside `<a>`, so the grid had only one item (the `<a>`) and the spans rendered as inline siblings without whitespace. Fix: move grid to `<a>` and add `gap: 0 0.6em`. Removed `display: grid` from `<li>`.

---

## Open questions

### Q1. Background — pure white or off-white?
**Settled (2026.05.17):** Pure `#ffffff` body. `--paper` token removed from `style-tokens.css` and `html-skeleton.html` (was a dead token used only in `system.html` table-row `:hover`). If we ever need a genuine non-inverted code surface or paper-toned container, reintroduce the token then.

### Q2. Axis font identity vs label italic
**Finding:** Both axis labels (in SVG, 8–10px) and HTML body italic (10.5–13.25px) declare `font-family: var(--serif); font-style: italic` — *declaratively the same font*.

**But:** none of the fonts in the `--serif` stack (`Source Serif, Source Serif Pro, Charter, Iowan Old Style, Cambria, Georgia`) are installed on the user's Guix System. The browser falls back to the generic `serif` keyword — almost certainly **DejaVu Serif Italic** or **Liberation Serif Italic**, both of which are installed in `/gnu/store/...font*`.

So the axis font and label italic *are* the same font as each other. Just not the font the skill was designed for. The perceived difference between axis font and label italic is likely **size-related hinting** — italic at 8–10px renders with different optical proportions than at 10.5–13.25px in the same font.

**Options:**
1. Install Source Serif Pro / Source Serif 4 on the user's system (Guix package: investigate `font-adobe-source-serif-pro` or similar). The skill renders as designed.
2. Switch the primary `--serif` declaration to a more reliably-installed serif on Linux (DejaVu Serif, Liberation Serif). Honest about what's actually rendering. Trades aesthetic intent for predictability.
3. Self-host the font in the skill's `assets/` directory and reference via `@font-face`. Breaks the "no external dependencies" rule unless we consider local font files acceptable.
4. Add a web-font load (`@import` from Google Fonts). Breaks the "no external dependencies" rule cleanly.

**Recommendation pending user choice.** If the user wants to keep the current declarative intent, option (1) — install the font locally — is the least invasive.

### Q3. Small-caps quality in the fallback font
The state-cells register C uses `font-variant-caps: all-small-caps; font-feature-settings: "smcp" 1, "c2sc" 1`. Source Serif Pro has true small caps. DejaVu Serif and Liberation Serif synthesize them (scale uppercase glyphs down). Synthesized small caps are passable but noticeably weaker than true small caps.

Linked to Q2. Solving Q2 (install Source Serif Pro) also resolves this.

---

## Verified strong patterns (worth preserving)

- **Italic serif at small sizes for axis labels and captions** — Tufte / mathematical-paper register. The plot axis font in `accent-test.html` is the canonical instance.
- **Process inks for data**: red `#d83a2f`, blue `#2e62c4`. Coral-leaning, printerly, not modern UI saturated.
- **Hatched fills (USGS rock-unit notation)** for stratigraphic and field-scale data. Five patterns: fine diagonal, stipple dots, dense diagonal, horizontal, cross-hatch.
- **Hairline isolines (no fills)** for topographic / density data. Multiple weights (index vs intermediate, USGS convention).
- **Risograph register**: substrate ink + sparser overprint annotation in second ink. Distinct primary/secondary roles.
- **Clifford attractor scatter cloud** at full field scale, in single ink, with italic serif x/y labels. The canonical mathematical-paper figure.
- **Black hairline structure carries the page**: frames, ticks, scale bars, north arrows, coordinate labels — black hairlines do the structural work; ink does the data work; the two never compete.
- **Earned dark surfaces only**: terminal/code blocks (real commands), blueprint diagrams (real diagrammatic content), specifications panels (real metadata data plate). Never decorative.

---

## File map

- `SKILL.md` — authoritative rule set.
- `README.md` — short orientation pointer for installing this folder as an Agent Skill.
- `LEARNINGS.md` — this file. Staging area before SKILL.md updates.
- `eval_queries.json` — trigger test queries.
- `034c1eeb…jpg`, `21872ef5…jpg`, `601e5f34…jpg`, `88c9f491…jpg`, `e5d6a8c9…jpg` — reference imagery (density, blueprint, dot-matrix, monochrome photography, orange duotone).
- `assets/style-tokens.css` — page palette + utility classes. `--paper` removed (2026.05.17); `--sans` removed (2026.06.21) — serif + mono only.
- `assets/html-skeleton.html` — single-file research-paper starter. Currently the three-register typography mock; `--paper` removed; TOC bug fixed.
- `assets/data-viz.css` — companion stylesheet for the seven data-viz pattern classes.
- `assets/data-viz-defs.svg` — drop-in SVG `<defs>` for the five stratigraphic hatch patterns and the Clifford attractor cloud.
- `assets/data-patterns.html` — pattern proposal demo (2026.05.17). Thirteen variants for metadata, lists, and tables. Drop once chosen variants are folded into the canonical assets.
