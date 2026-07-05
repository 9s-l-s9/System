---
name: design
description: >
  Use this skill by default whenever producing HTML, websites, web pages, interactive docs, visual documentation, architecture overviews, project knowledge bases, concept pages, dossiers, technical reports, or other designed artifacts, unless the user asks for another visual direction. Apply a technical-manual / cybernetic aesthetic: white page, near-black monospace body (IBM Plex Mono) with a Space Mono display register for chrome and headings, black terminal blocks as the only chrome-dark element, booktabs tables, hairline rules, dense two-column layout, and an addressable / machine-readable structure where every block is typed and carries a stable identifier. Reads like a systems manual, parts catalog, or control-theory document, not a marketing page or a terminal UI. Imagery is monochrome or duotone: blueprint / exploded line drawings with measurement annotations, one-bit dot-matrix renderings, orange/red duotone halftones, and monochrome photography. Do not use for pure code-only, backend, data, or prose tasks unless the output includes visual design or HTML.
license: CC0-1.0
---

# Technical-Manual / Cybernetic Default Design Skill

## Purpose

Use this as the default visual system for HTML and designed artifacts. The goal is to make generated websites, architecture overviews, project knowledge bases, concept pages, technical reports, dossiers, and interactive documentation feel like a **technical manual** — a systems manual, parts catalog, engineering field document, or control-theory monograph — rather than a marketing page or a terminal UI.

The spine of the aesthetic is **legibility of structure**: the page is not decorated, it is *specified*. Every element looks catalogued, addressed, and wired to every other element — a reader (or a machine) can point at any region and find its type, its identifier, and its relations. This is the cybernetics tell: a system is its diagram of relationships. Three things carry it — high **density** (a real manual is dense), an **addressable / machine-readable structure** (typed blocks, stable IDs, cross-references, semantic markup), and a **systems-diagram vocabulary** (block diagrams, signal-flow, feedback loops). It descends from the typeset research-paper tradition (booktabs tables, hairline rules, numbered sections) but pushes denser and more instrument-like.

This is a default house style, not a one-off theme. Apply it automatically whenever the user asks for a website, HTML document, web-based report, knowledge base, visual documentation, concept page, or other design output, unless the user explicitly asks for a different aesthetic.

**One layout, applied consistently.** The aesthetic does not branch into variants. Every artifact uses the same typography, density, and structural devices described below.

## Trigger policy

Use this skill when the user asks for any of the following:

- An HTML document, even when the request is primarily informational, such as an architecture overview, codebase map, project concept, knowledge base, documentation page, status report, research note, or generated mini-site.
- A website, landing page, personal site, portfolio, or dashboard rendered as a readable document.
- A visual or layout-oriented artifact, including diagrams, information architecture, design content, report pages, or styled documents.
- A project archive, wiki, logbook, research notebook, system map, model card, dataset page, or technical dossier.
- A default visual style where no other style was specified.

Do not use this skill for pure code-only tasks, backend implementation, CLI scripts, unstyled prose, data cleaning, or debugging unless the user also asks for HTML, UI, visual documentation, or design output.

## Core principles

The artifact should feel like:

```text
systems manual / parts catalog
+ control-theory monograph
+ engineering field report
+ archival dossier / wiki node
+ blueprint workbook
```

Prioritize structure, legibility, density, and editorial restraint over decoration.

- **White page, near-black ink.** The page reads like a typeset manual, not an interface.
- **Terminal/code blocks are the only chrome-dark elements** in the document surface. Solid black background with off-white text. They sit on the page like embedded screenshots of a real terminal.
- **Monospace body — technical-manual register.** IBM Plex Mono carries prose, headings, and every label — a corporate-technical monospace that reads as systems documentation, not a typewritten script. A **Space Mono display register** is reserved for the chrome and headings (masthead, title, section numbers, coordinate ruler, colophon) — the NASA-plaque display voice. No proportional serif; the whole document is monospace. `--serif`/`--mono` resolve to Plex Mono, `--display` to Space Mono.
- **Dense.** A real manual is dense. Run prose in a hairline-ruled **two-column** measure; pack metadata; prefer a four-row table to a four-sentence paragraph. See § Compression.
- **Addressable / machine-readable.** Every block is typed and carries a stable identifier (`N-nn` nodes, `P-nn` parts, `F-nn` faults, `ADDR 0xNN`). Cross-references are live anchors that read as record keys (`→ P-02`). Use semantic HTML, `data-*` attributes, and microdata so the structure is real, not faked. See § Addressability.
- **Booktabs-style tables** (see Tables section).
- **Numbered sections** (`1`, `2`, `3` …) with subsections marked `§`. Numbered `Table N` / `Fig. N` captions at the bottom of the figure.
- **Centered measure, no frame.** The page measure centers on the viewport with symmetric margins. Do **not** box it with a vertical side border (either edge): a vertical rule is what makes a page read as a boxed UI panel; without it the centered measure reads as a placed plate. Horizontal hairline rules still terminate at the measure. (Running prose inside the measure is two-column; see § Compression.)
- **Compressed.** Body 12–13px, line-height 1.4–1.45, dense two-column measure inside a ~1000–1080px page.
- **No accent color in the chrome.** No decorative paint, no button fills, no stripes. The orange/red signature is reserved for imagery treatment (see Imagery).
- **Imagery is monochrome or duotone**: blueprint line drawings, one-bit dot-matrix renderings, orange/red duotone halftones, monochrome photography. No stock photography, no flat illustration, no glossy product renders.
- **No sticky sidebars** chasing the reader. (Running prose is two-column within the measure; see § Compression.)
- **Hairline rules instead of shadows.** Sharp rectangular geometry; no rounded corners.
- **Dense, indexed information architecture.** Metadata everywhere: dates, IDs, revision markers, file paths, counters.
- **Minimal animation.** Respect `prefers-reduced-motion`.
- **Black surfaces must be earned.** Each dark moment on a white page is a strong signal. Three patterns earn it: **terminal/code blocks** (carrying real commands or output), **blueprint diagrams** (carrying real diagrammatic content with monospace dimension annotations), and the **dark data-plate dict variant** (`dl.meta`, used only when the artifact is a genuine dossier and the metadata is itself the centerpiece — see § Dictionaries). Never introduce a dark surface as decoration, visual variety, or as a default metadata treatment.

## Explicit failure patterns to avoid

These came out of real iteration failures. They feel "designed" but read as decoration, not document:

- **Decorative top stripes** (e.g. a bar of repeating orange dashes across the page header). Reads as retro chrome.
- **Blinking status dots in the header.** Distracting; signals nothing.
- **Page-wide dot-grid or scanline backgrounds** with no relation to the content underneath.
- **ASCII art used as a flow diagram in a document.** Use a real SVG with rectangles, labels, and arrows. (Dot-matrix rendering of figurative subjects as *imagery* is different and encouraged — see Imagery.)
- **Oversized display-caps heroes** (`clamp(2.4rem, 7vw, 5.5rem)` titles shouting across the screen). Wastes the page and reads as marketing.
- **Accent-color "command" buttons stacked under the hero.** Documents do not have CTAs.
- **Tag pills sprinkled on every card as ornament.** Use a `State` column with a single word instead.
- **Proportional-serif or proportional-sans body.** The body is monospace (IBM Plex Mono); a proportional face reads as a different document entirely. The only non-body face is the Space Mono display register on chrome/headings — itself monospace.
- **Heavy accent-color use in chrome.** Accent (orange/red) is reserved for *imagery duotone treatment*, never for buttons, stripes, or backgrounds.
- **Card-grid layouts with surface fills and bordered boxes** as the primary structural device. Use hairline-ruled tables instead.
- **Corner badges on code blocks** (orange "SH" / "MAKE" tags). Reads as retro chrome. If a block needs context, write a sentence above it.
- **Decorative cover imagery on title pages.** The default is *no* cover image — title, byline, abstract, metadata, contents are enough. Only add imagery on a title page if it carries meaning (e.g. a specifications data plate). When in doubt, skip imagery.
- **Procedural halftones, dot-matrix renderings, or ASCII illustrations generated inline in SVG.** They almost always look amateurish in actual practice. Use a pre-rendered raster asset, or skip the treatment.
- **Forced title width constraints** (`max-width: 22ch` on the `<h1>`). Titles use their natural width within the page measure; only wrap when they actually overflow.
- **Paragraph `max-width: …ch` layered on top of the page measure.** The page measure (~700–900px) is the paragraph measure — don't double-constrain. Doing so leaves dead space inside the column and breaks the typographic rhythm.
- **Soft-alpha translucent zone fills in figures** (concentric circles with 15–30% fill behind hairlines, "heatmap zone" colouring). Reads as dashboard infographic immediately. Use hairline isolines, hatched fills, or stipple instead.
- **Auto-layout node-and-edge graphs** with primary/secondary dotted lines and force-directed placement. Reads as d3 / Mermaid / graphviz default. A *hand-authored* cybernetic block diagram (typed blocks, orthogonal routing, an explicit labelled feedback path) is the opposite and is encouraged — see § Cybernetic block diagrams. The ban is on the lazy auto-layout look, not on systems diagrams.
- **Two colour-coded data series with no role asymmetry.** Reads as modern data viz. Either drop to single ink (Mode 2) or commit to the Mode 3 red-leads / blue-supports hierarchy.
- **Accent ink on links, buttons, dividers, section paint, badge fills.** The accent is for the data and diagram surface (and the narrow editorial register). Any chrome use modernizes it.

Also avoid the standard anti-patterns: glossy SaaS gradients, bubbly cards, large border radii, soft pastel UI, glassmorphism, heavy drop shadows, generic stock-photo marketing, spacious hero sections that waste the page.

## Default palette

```css
:root {
  --bg: #ffffff;
  --paper: #fbfbfa;          /* very subtle off-white if a non-inverted code surface is needed */
  --ink: #0a0a0a;
  --ink-2: #1d1d1d;
  --muted: #565656;
  --faint: #8a8a8a;
  --rule: #0a0a0a;           /* booktabs heavy rules */
  --rule-soft: #d4d4d4;      /* row separators, hairlines */
  --term-bg: #000000;        /* terminal block background, blueprint imagery background */
  --term-fg: #ededed;
  --term-muted: #9a9a9a;

  /* duotone imagery palette — used only inside imagery treatments,
     never as decorative paint, never on buttons or backgrounds */
  --duotone-bg: #0a0a0a;
  --duotone-fg: #ff5a1f;     /* warm orange */
  --duotone-hi: #ffd24a;     /* yellow highlight, for two-color halftones */

  /* data-visualisation accent inks — see § Color modes.
     Allowed only on the data/diagram surface of figures and on a
     narrow set of editorial marks. Never as chrome, links, or fills. */
  --accent-red:       #d83a2f;   /* process red on light substrate */
  --accent-blue:      #2e62c4;   /* process blue on light substrate */
  --accent-red-dark:  #ee4d42;   /* lifted for dark substrate */
  --accent-blue-dark: #5a8de8;   /* lifted for dark substrate */

  /* dark-substrate accent inks — see § Dark substrate variant.
     Replace red/blue on fully inverted pages. */
  --accent-amber:  #c4813e;     /* lead ink (replaces red) */
  --accent-violet: #8860b4;     /* support ink (replaces blue) */
}
```

No accent in the chrome. Where a single textual signal is needed (e.g. a metadata value reading `Guile only`), italics or a serif-italic word is sufficient. The duotone palette and the data-viz accents are separate systems with separate rules — duotone applies only inside imagery treatments, the accent inks apply only inside data-viz figures and a narrow editorial register described below.

## Color modes

Every document operates in one of three colour modes. Modes are cumulative — moving up costs more, so default to the lowest mode that still does the job. Most documents stay in Mode 1.

### Mode 1 — Black only (default)

Body type, hairline rules, booktabs tables, terminal blocks, SVG hairline figures, and (when imagery is warranted) duotone or blueprint treatments. No accent ink. The default for almost everything.

### Mode 2 — Single ink (red **or** blue)

When the artifact carries a data layer that needs to be distinguished from structure. One ink per artifact; the ink is *the data*. Black still does frames, hairlines, tables, prose, captions.

Hex values, paired to substrate:

| Ink                       | Light substrate | Dark substrate |
|---------------------------|-----------------|----------------|
| Red — process / Venetian  | `#d83a2f`       | `#ee4d42`      |
| Blue — process / printerly| `#2e62c4`       | `#5a8de8`      |

The light values are the canonical ones — most pages are white. Dark-substrate values are reserved for the rare dark-mode artifact (which is itself a departure from the white-page baseline).

Either ink, never both, in Mode 2. Tendencies, not laws:

- Red — scatter clouds, hatched bar focus, sample annotation, focus highlights.
- Blue — area-fill maps, contour data, structural data substrates.

The constraint is *one ink per artifact*, not which ink.

### Mode 3 — Dual ink (asymmetric: red leads, blue supports)

When the data has an asymmetric relationship — signal vs context, active vs baseline, overlay vs substrate. Two inks with **fixed** roles:

- **Red** — primary signal, active series, current revision, overlay annotation, focus mark.
- **Blue** — baseline, reference, underlying structure, context substrate.
- **Black** — still does frames, hairlines, type, chrome. Never displaced.

The asymmetry is the rule. If you cannot name which ink is primary in one sentence, drop to Mode 2.

**What Mode 3 may not do, even when admitted:**

- Two equal-weight colour-coded series with no hierarchy — reads as infographic.
- Decorative dual-colour zones with no role distinction.
- Either ink as chrome paint, link colour, dividers, backgrounds — same rule as Mode 2.
- More than two inks ever.
- Switching which ink is primary mid-artifact.

**Print traditions supporting dual ink** (and proving it does not have to read as modern):

- Topographic maps (blue contours + red routes/grids)
- Anatomical drawings (red arteries + blue veins)
- Engineering revisions (blue original + red redline)
- Risograph overprinting (one base, one annotation layer)
- Russian Constructivist composition (Rodchenko, El Lissitzky)
- Medieval rubrication paired with later marginal annotation

### Editorial register (narrow)

Whether the artifact is in Mode 1, 2, or 3, the chosen accent ink (or red in Mode 1 if you must) may also appear in a *tightly scoped* typographic editorial register:

- A `WATCH` / `CRITICAL` / `DEPRECATED` state cell in a booktabs table.
- A revision marker in a margin (`REV. 2`).
- A footnote reference numeral.
- A drop-cap initial at a chapter start.

That is the entire allowed set. Red still may not be a link colour, body emphasis, section paint, badge fill, or decoration. If a bold or an italic could do the job, use bold or italic. Editorial red is reserved for *criticality* or *rubric*, not "look here."

### Dark substrate variant

A fully inverted page — black background, light text. A departure from the white-page baseline; use deliberately, not as a default.

Inverted page palette:

| Token         | Light (default) | Dark substrate |
|---------------|-----------------|----------------|
| `--bg`        | `#ffffff`       | `#0a0a0a`      |
| `--ink`       | `#0a0a0a`       | `#ededed`      |
| `--ink-2`     | `#1d1d1d`       | `#d4d4d4`      |
| `--muted`     | `#565656`       | `#9a9a9a`      |
| `--faint`     | `#8a8a8a`       | `#6a6a6a`      |
| `--rule`      | `#0a0a0a`       | `#ededed`      |
| `--rule-soft` | `#d4d4d4`       | `#2a2a2a`      |

Red and blue do not read well on dark substrate. Two replacement inks:

- **Amber `#c4813e`** — lead ink. Desaturated brass tone with print/industrial lineage (darkroom safelights, amber terminals, engineering warning plates). Replaces red as primary signal.
- **Lithographic violet `#8860b4`** — support ink. Warm red-violet with engineering lineage (diazo copies, lithographic overprint). Replaces blue as substrate/reference ink.

Mode logic carries over unchanged. Mode 2: amber as single ink (`.scatter`, `.contour`, `.strat`, `.anno`, `.bars`). Mode 3: amber leads, violet supports (`.strat-dual`, `.contour-dual`). The structural ink (now light) still does frames, ticks, hairlines, type. Anno and bars are Mode 2 patterns — their base/context elements use structural ink, not violet.

The editorial register uses amber instead of red on dark substrate.

## Typography

**Monospace throughout — the technical-manual register.** No proportional serif and no proportional sans — both read as an intrusion on a manual page. **IBM Plex Mono** (the `--serif` token, kept under that name so existing rules inherit it; `--mono` is the same family) carries prose *and* all labels, code, and tabular cells. **Space Mono** (`--display`) is reserved for the chrome/heading register only — masthead, title, section numbers and heads, the coordinate ruler, the colophon — its wider, NASA-plaque proportions giving the display voice against the Plex body. Body prose stays roman; the registers below distinguish themselves by case, letter-spacing, and italics.

Both fonts are installed via the Guix config (`font-ibm-plex`, `font-space-mono`); the stacks fall back to `ui-monospace` so a copied-out file still renders without them.

- **Body prose:** IBM Plex Mono (`--serif`).
- **Headings + chrome display:** Space Mono (`--display`), heavier weight.
- **Identifiers, paths, code, tabular data, metadata:** IBM Plex Mono (`--mono`).
- **Label register A — structural** (masthead identity, byline, section markers, `§` subs, dict eyebrows, note prefix): the display face where it is chrome (masthead, section markers), otherwise `--serif`; uppercase, wide letter-spacing.
- **Label register B — descriptive** (figcaptions, table captions, column headers, plot axis labels): monospace, italic lowercase.
- **Label register C — state tags** (`Stable`, `Watch`, `Transitional` in tables): monospace, uppercase, letter-spaced (small-caps features are unavailable in Courier).
- Enable `font-variant-numeric: tabular-nums` for any column that contains numbers.
- Body **13–14px**, `line-height: 1.4–1.5`.
- Subsequent paragraphs inside a section can take `text-indent: 1.4em`, or use blank-line separation — pick one and stay consistent.
- Use `§` for subsection markers (e.g. `§ 1.1`, `§ Quality assurance`).

Type stacks:

```css
/* body + all labels + code — IBM Plex Mono, technical-manual register */
--serif:   "IBM Plex Mono", ui-monospace, monospace;
--mono:    "IBM Plex Mono", ui-monospace, monospace;
/* chrome + heading display register — Space Mono, NASA-plaque voice */
--display: "Space Mono", "IBM Plex Mono", ui-monospace, monospace;
```

`--display` is used only on chrome and headings (masthead, title, section numbers/heads, coordinate ruler, colophon). Everything else is `--serif`/`--mono` (Plex Mono).

Use uppercase for small system labels:

```text
INDEX     SYSTEM STATUS     FIELD NOTES     LAST MODIFIED     ARCHIVE NODE
```

## Compression

Density is central to the aesthetic — a real technical manual is dense, and the current failure mode is pages that read too airy and web-like. The page should read markedly denser than typical web defaults.

Targets:

- Body **12–13px**, line-height 1.4–1.45.
- **Two-column running prose.** Wrap body text in a hairline-ruled two-column measure (`.cols`); collapse to one column under ~720px. Figures and wide tables sit full-width outside `.cols`, or use `.break-avoid` so they don't split across the column gap. This is the biggest single density lever — a single wide column reads as a web article, two columns read as a manual.
- Section vertical spacing ≤ 22px.
- Table cell padding 3–6px vertical, 0–10px horizontal.
- Code-block padding 10–14px.
- Outer page measure ~1000–1080px to hold two columns; no sticky sidebars eating horizontal space.
- **The column measure is the paragraph measure.** Don't add `max-width: …ch` to paragraphs on top of the column constraint; that double-constrains the text and leaves dead space.
- Trim prose. Prefer one tight paragraph to two loose ones. Cut adverbs, transitions, and meta-narration. A four-row table beats a four-sentence paragraph.
- Inline metadata wherever possible (`Vol. 1 · No. 0 · 2026.05.13 · branch main`) rather than spreading it across stacked rows. Pack the title-page spec grid (`dl.dict-grid`) with real fields.

Compression failure mode: dense type stacked without rules or breathing room. Use hairline `border-top`/`border-bottom` between blocks; whitespace alone is not enough at this density.

## Addressability

The manual treats the page as an **addressable system**. This is what separates it from a research paper: not just numbered sections, but a scheme where every block is *typed and keyed*, and the chrome advertises that the document is indexed. Aim for both the *look* of a catalogued system and, where cheap, genuine machine-readability.

- **Namespaced identifiers.** Give blocks stable IDs in a small set of namespaces — e.g. `N-nn` (nodes), `P-nn` (parts), `F-nn` (faults), `T-n` (tables). Pick namespaces that fit the subject; keep them consistent within an artifact. A reference resolves to exactly one record.
- **Section address markers.** Right-align an `.addr` marker in each section head: `FIG 1 · ADDR 0x02`. Reads as a memory/catalog address, not decoration.
- **Cross-reference chips.** Make references live anchors styled as record keys: `<a class="xref" href="#sec-4">P-02</a>` renders `→ P-02`. The addressing is then real (clickable), not cosmetic.
- **Coordinate ruler.** A thin `.coord-top` strip at the page edge (`A0 · A1 · A2 …`, sheet/scale/rev) frames the page as an indexed drawing. One per page, at the top.
- **Real structure.** Use semantic HTML (`<section>`, `<table>`, `<nav>`), `data-*` attributes on typed blocks (`data-unit="N-04"`), and light microdata (`itemscope itemtype="https://schema.org/TechArticle"`). The aesthetic read is primary, but keep the markup honestly parseable.

Do not let addressing become noise: IDs must be stable and meaningful, not random serials sprinkled for texture. If an ID does not resolve to a real record somewhere in the document, drop it.

## Layout grammar

Build pages from clear, separated typographic blocks:

- A compact top masthead with identity on the left and revision/date metadata on the right.
- A title page block: title → byline → italic *Abstract.* paragraph → metadata definition list → inline TOC, all separated by hairline rules.
- Numbered sections with `§` subsections.
- Booktabs tables for module maps, references, logs.
- Numbered SVG figures.
- A colophon footer with end-of-document marker, generation date, and format note.

Skeleton:

```text
┌──────────────────────────────────────────────────────────┐
│ MASTHEAD: id · subtitle              vol · date · branch │
├──────────────────────────────────────────────────────────┤
│ TITLE PAGE                                               │
│   Title (serif, modest size)                             │
│   Byline                                                 │
│   Abstract. <italic paragraph>                           │
│   ─────── hairline ────────                              │
│   Metadata DL (mono)                                     │
│   Contents (2-col inline)                                │
├──────────────────────────────────────────────────────────┤
│ 1 SECTION                                                │
│ 2 SECTION                                                │
│ ...                                                      │
├──────────────────────────────────────────────────────────┤
│ Colophon: end-of-document · single file · date           │
└──────────────────────────────────────────────────────────┘
```

Use hairline rules instead of shadows:

```css
.section { border-top: 1px solid var(--rule); }
.hairline { border-top: 1px solid var(--rule-soft); }
```

## HTML document defaults

When generating HTML, prefer a complete, standalone document unless the user asks otherwise.

Default requirements:

- Semantic HTML (`<main>`, `<nav>`, `<section>`, `<article>`, `<aside>`, `<header>`, `<footer>`).
- Responsive layout.
- CSS variables for the palette.
- No external dependencies unless requested.
- Accessible contrast.
- Visible focus states.
- Reduced-motion support.
- Clear hierarchy.
- A `@media print` block that inverts terminal blocks back to white-with-border so they print legibly.
- Metadata blocks for context, date, source, status, and scope.
- Navigable anchors for long documents.

The HTML should still work if copied into a single `.html` file.

## Common artifact patterns

### Architecture overview

```text
1  SUMMARY
2  ENTRY POINTS
3  MODULE MAP
4  DATA / DEPENDENCY SURFACE
5  CONFIGURATION FLOW
6  POLICY / QA
7  FRICTION POINTS / OPEN QUESTIONS
8  EVENT LOG / NEXT STEPS
```

Open with a title page (title, byline, *Abstract.*, metadata, contents). Use booktabs tables for modules, paths, roles. Use one SVG flow diagram if there is a flow worth diagramming.

### Project knowledge base

```text
INDEX     PROJECTS     CONCEPTS     DECISIONS     LOGS     REFERENCES     OPEN QUESTIONS
```

Make pages feel like linked nodes in an archive. Concise abstracts and metadata at the top of each page.

### Mini concept page

```text
CONCEPT ID     ABSTRACT     PROBLEM     SYSTEM BEHAVIOR     INTERFACE     DATA / MODEL     FAILURE MODES     NEXT BUILD
```

### Portfolio / personal site

Treat each project as an archive node, not a marketing card. Use:

```text
IDENTITY     CURRENT WORK     PROJECTS     NOTES     TOOLS     LOG     CONTACT
```

### Dashboard rendered as document

When asked for a dashboard, render it as a readable status report rather than an app UI: status table at the top, signals table, event log, next actions list. Same booktabs / hairline rule discipline.

## Component patterns

### Navigation

Small inline nav in the masthead and an inline two-column TOC on the title page. Numbered TOC entries (`1`, `2`, `3` …) reappear as section heads.

```text
Summary · Entry Points · Modules · Channels · Flow · Policy · Log
```

### Tables — booktabs convention

Tables are the primary structural unit.

- Thick top rule (1.5–2px solid ink) above the header row.
- Thin rule (0.5px solid ink) below the header row.
- Thick bottom rule (1.5–2px solid ink) at the foot.
- **No vertical lines.** No box around the table.
- Body row separators: dotted hairline (`0.5px dotted #d4d4d4`) or none for short tables.
- Column headers in serif italic lowercase (descriptive register), or uppercase letterspaced serif, muted color.
- Numbered caption at the *bottom*: `Table N — short description.`
- Identifier columns left-aligned in monospace; numeric columns tabular-nums.

```css
table.tbl {
  width: 100%;
  border-collapse: collapse;
  border-top: 1.5px solid var(--rule);
  border-bottom: 1.5px solid var(--rule);
}
table.tbl thead th {
  font-family: var(--serif);
  font-size: 10px;
  letter-spacing: .14em;
  text-transform: uppercase;
  color: var(--muted);
  text-align: left;
  border-bottom: .5px solid var(--rule);
  padding: 4px 10px 4px 0;
}
table.tbl tbody td { padding: 4px 10px 4px 0; vertical-align: top; }
table.tbl tbody tr + tr td { border-top: .5px dotted var(--rule-soft); }
table.tbl caption {
  caption-side: bottom;
  text-align: left;
  font-family: var(--serif);
  font-size: 10.5px;
  letter-spacing: .12em;
  text-transform: uppercase;
  color: var(--muted);
  padding-top: 6px;
}
```

### Terminal / code blocks — inverted

Solid black background, light text. The only chrome-dark element on the page.

```css
pre.term {
  background: #000;
  color: #ededed;
  font-family: var(--mono);
  font-size: 11.5px;
  line-height: 1.55;
  padding: 12px 14px;
  border: 0;
}
pre.term .c { color: #9a9a9a; }   /* comments */
pre.term .p { color: #d4d4d4; }   /* shell prompt $ */
pre.term .a { color: #9a9a9a; }   /* dimmed arguments */
```

Do not attach corner labels, language tags, or accent badges. If the block needs context, write a sentence above it.

### Status labels

Prefer a `State` column with a single word in small caps (`Stable`, `Active`, `Watch`), or an italic serif word for soft states (`Transitional`, `Variant`, `Draft`). Avoid pill-shaped tag boxes.

### Dictionaries — key→value structures

Document metadata, glossaries, parameter sheets, term definitions, and any other label→value content all render the same underlying structure — a *dict*. The choice between variants is purely presentational: field count, value length, and how much visual weight the dict deserves. Pick the lightest variant that does the job.

Five variants ship as utility classes in `assets/style-tokens.css`:

| Class                 | Variant                       | When to use                                                                                                              |
|-----------------------|-------------------------------|--------------------------------------------------------------------------------------------------------------------------|
| `.dict-strip`         | Inline strip                  | Supporting metadata, ≤4 short fields, masthead-style stripe.                                                             |
| `dl.dict-grid`        | Hairline multi-column grid    | 6+ short fields with parallel structure — the everyday default for substantive metadata.                                  |
| `dl.dict-aligned`     | Column-aligned vertical       | Formal specification sheet; keys right-aligned in a left column, mono values left-aligned in the next.                   |
| `dl.dict-hanging`     | Hanging key, prose value      | Values are sentences: glossaries, parameter documentation, term definitions, bibliography entries.                       |
| `dl.meta`             | Dark data plate *(dossier)*   | Earned only on a genuine dossier / archival artifact where the metadata is itself the centerpiece. **Not the default.** |

#### K1 — Inline strip

A single hairline-bounded row of `LABEL value · LABEL value · …` in mono. Smallest footprint.

```css
.dict-strip {
  padding: 6px 0;
  border-top: .5px solid var(--rule-soft);
  border-bottom: .5px solid var(--rule-soft);
  display: flex; flex-wrap: wrap; gap: 0 22px;
  font-family: var(--mono);
  font-size: 11.5px;
  color: var(--ink);
}
.dict-strip .lbl {
  font-family: var(--serif);
  letter-spacing: .14em;
  text-transform: uppercase;
  font-size: 10px;
  color: var(--muted);
  margin-right: 5px;
}
```

#### K2 — Hairline grid (the default)

White-surface multi-column grid. Hairline borders, uppercase eyebrows over mono values. The everyday default for title-page metadata.

```css
dl.dict-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  font-family: var(--mono);
  margin: 18px 0 0;
  border-top: 1px solid var(--rule);
  border-bottom: 1px solid var(--rule);
}
dl.dict-grid > div {
  padding: 10px 14px;
  border-right: .5px solid var(--rule-soft);
  border-top: .5px solid var(--rule-soft);
  display: grid; gap: 3px;
}
dl.dict-grid > div:nth-child(3n)   { border-right: 0; }
dl.dict-grid > div:nth-child(-n+3) { border-top: 0; }
dl.dict-grid dt {
  font-family: var(--serif);
  letter-spacing: .14em;
  text-transform: uppercase;
  font-size: 9.5px;
  color: var(--muted);
  margin: 0;
}
dl.dict-grid dd { margin: 0; color: var(--ink); font-size: 12px; }
```

Collapse to 2 columns under ~720px and reflow the border rules accordingly.

#### K3 — Column-aligned vertical

Two-column layout: uppercase keys right-aligned, mono values left-aligned. The classic specification-sheet / library-catalogue-card pattern; reads top-to-bottom.

```css
dl.dict-aligned {
  display: grid;
  grid-template-columns: max-content 1fr;
  gap: 4px 22px;
  padding: 4px 0;
  border-top: .5px solid var(--rule-soft);
  border-bottom: .5px solid var(--rule-soft);
}
dl.dict-aligned dt {
  text-align: right;
  font-family: var(--serif);
  letter-spacing: .14em;
  text-transform: uppercase;
  font-size: 10.5px;
  color: var(--muted);
}
dl.dict-aligned dd {
  margin: 0;
  font-family: var(--mono);
  font-size: 12px;
  color: var(--ink);
}
```

#### K4 — Hanging-key definition (prose values)

Italic-serif key, prose value that wraps freely. The only dict variant where values are themselves sentences.

```css
dl.dict-hanging {
  display: grid;
  grid-template-columns: max-content 1fr;
  gap: 6px 22px;
}
dl.dict-hanging dt {
  font-family: var(--serif);
  font-style: italic;
  font-size: 12.5px;
  color: var(--ink);
}
dl.dict-hanging dd {
  margin: 0;
  color: var(--ink-2);
  font-size: 12.5px;
  line-height: 1.5;
}
```

#### dl.meta — Dark data plate (dossier variant)

A black panel with internal hairline rules in dark gray, gridded label/value pairs in monospace, uppercase eyebrows in muted gray, values in off-white. This is the third legitimate "earned dark surface" on a white page, alongside terminal blocks and blueprint diagrams — but it claims significant visual weight. Use it deliberately, not as the default.

The right case is a *genuine dossier*: an archival artifact where the metadata is itself the focus (an engineering specifications data plate, a punch-card index, an archival colophon page). For everyday metadata, prefer K2 (`dl.dict-grid`) or K1 (`.dict-strip`).

```css
dl.meta {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  background: #000;
  color: #ededed;
  font-family: var(--mono);
  margin: 18px 0 0;
}
dl.meta > div {
  padding: 12px 16px;
  border-right: 1px solid #1f1f1f;
  border-top: 1px solid #1f1f1f;
  display: grid;
  gap: 3px;
}
dl.meta > div:nth-child(3n) { border-right: 0; }
dl.meta > div:nth-child(-n+3) { border-top: 0; }
dl.meta dt {
  font-family: var(--serif);
  font-size: 9.5px;
  letter-spacing: .14em;
  text-transform: uppercase;
  color: #8a8a8a;
}
dl.meta dd { margin: 0; color: #ededed; font-size: 12px; }
```

Collapse to 2 columns under ~720px. Print stylesheet inverts the panel (white bg, black ink, gray internal rules) so it remains legible on paper.

## Imagery

Imagery in this system is **never decorative**. The *default* is no imagery beyond the figures and tables the content demands — a clean typographic title block with abstract, metadata, and contents is sufficient for most documents. Only add an image if it carries meaning: a real diagram, a real specifications data plate, a real photograph that documents the subject.

**Procedural halftones, dot-matrix renderings, or ASCII illustrations generated inline in SVG almost always look amateurish in practice.** Iteration after iteration tends to confirm this. Use a pre-rendered raster asset, or skip the treatment. The intent behind the inspirational halftone references is achievable with prepared assets, not by hand-coding patterns and masks.

When imagery is genuinely warranted, four primary treatments:

### Blueprint / technical illustration (white-on-black)

Treatment intent: an engine cross-section or similar technical plate.

- Pure black background.
- Hairline white linework (subject and outlines).
- **Monospace annotations**: dimension callouts, part numbers, measurement values.
- Measurement bars with arrowheads on both ends, dimension numbers offset.
- Optional column of catalog identifiers / part references stacked alongside the drawing.
- No fills, no color, no shading — line only.
- Caption underneath as `Fig. N — description.`

Use for: mechanical, architectural, electrical, or system illustrations where structural detail matters. SVG with `stroke: #ededed; fill: none; stroke-width: 1; vector-effect: non-scaling-stroke`.

### Dot-matrix / one-bit halftone (monochrome)

Treatment intent: a Doric column, statue, or other subject rendered as one-bit dots.

- Subject rendered as a field of single-color dots whose density encodes value.
- Monochrome: white dots on black, or black dots on white.
- Pure one-bit: no anti-aliasing, no intermediate gray.
- Subjects favor classical, architectural, or figurative reference (columns, statues, busts, anatomy, foliage).
- Image fills its container edge-to-edge; no inner border.

Use for: hero imagery on archive nodes, cover images on dossiers, accompanying imagery on knowledge-base index pages. For production, prefer a pre-rendered one-bit asset over CSS approximation.

### Duotone halftone (orange/red on dark)

Treatment intent: a figurative subject rendered as a warm duotone halftone.

- Two-color halftone: warm orange/red dot field on a near-black background, sometimes a yellow highlight as third color.
- Used at large scale — a full image field, not an icon.
- Pairs computational treatment with figurative or classical subjects (an eye, a statue, an X glyph).
- Within the image: no labels, no chrome.
- Outside the image: standard typography, no orange paint anywhere else.

```css
.duotone {
  background: var(--duotone-bg);
  /* image rendered with two-tone halftone in --duotone-fg and --duotone-hi */
}
```

The orange/red is **only** allowed inside imagery treatments. Never as button paint, link color, stripe, or background.

### Monochrome photography

Treatment intent: documentary monochrome photography; this informs image treatment, not layout.

- Grayscale photography, regular continuous tone (not halftoned).
- Cropped tight, no caption overlay, optional small caption text below.
- Framed by a hairline border when sitting on the white page.

### SVG flow diagrams (when the artifact is structural)

For data flows, dependency surfaces, architecture diagrams: clean SVG line drawings — rectangles, labels, arrows, hairline strokes (1px solid `#0a0a0a`), monospace labels, no fills. Caption `Fig. N — description.` at the bottom. White-background variant of the blueprint style.

This is the *diagram* pattern — structural, not data-bearing. When a figure carries actual data (a scatter, a stratigraphic section, a topographic plot), use one of the [data visualisation patterns](#data-visualisation-patterns) below instead.

### Subjects to favor

When choosing or generating imagery subjects, prefer:

- Classical architecture: Doric/Ionic/Corinthian columns, archways, façades, ruins.
- Sculptural figures: busts, statues, anatomical drawings, drapery studies.
- Mechanical: engines, sections, exploded views, instrument panels.
- Botanical: pressed-leaf style, dot-matrix foliage.
- Astronomical or topographic: star maps, contour lines, isobars.
- Pure geometry: glyphs, lattices, symbols.

The signature move is **pairing anachronistic or classical subjects with computational treatment** (dot-matrix Doric columns, halftone statues).

### What to avoid

- Photographic stock imagery in color.
- Glossy product renders.
- Flat / "Corporate Memphis" illustration.
- 3D mockups.
- Emoji or icon-as-illustration.
- Gradient fills, decorative geometric backgrounds, abstract waves.

## Data visualisation patterns

When the artifact includes charts, diagrams carrying data, or quantitative figures, use these named patterns. Each is *decidedly not* modern dashboard data viz — each has a print-shop, drafting, or mathematical-paper register that the colour modes above build on. Working CSS and SVG defs live as standalone assets in this skill's `assets/` directory.

### Patterns

| Pattern          | Treatment                                                                                                                              | When to use                                                       | Mode |
|------------------|----------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|------|
| `.scatter`       | Whole-cloud data marks (Tufte-style attractor). Italic serif x/y labels. Frame + ticks in black, dots in ink.                          | Mathematical or statistical figures.                              | 2    |
| `.contour`       | Hairline isolines, *no fills*. Cartographic chrome — frame ticks, coordinate labels, north arrow, scale bar.                            | Topographic, density, or zone-density figures.                    | 2    |
| `.strat`         | Field-scale hatched fills using USGS rock-unit notation (fine diagonal, stipple, dense diagonal, horizontal, cross-hatch). Stratum names sit outside the plotted strata, usually in a right-side label column with leader ticks. Optional left-side ink bracket annotation. | Stratigraphic, layered, or banded-structure data.                  | 2    |
| `.anno`          | Monochrome base figure + ink overlay (brackets, dashed boxes, callouts, small mono labels).                                            | Annotation, revision marks, sample identification (Risograph).    | 2    |
| `.bars`          | Solid black bars + one diagonal-hatch ink bar for the focus value. Category labels and numeric values sit outside the bars, never embedded in the filled bar shapes. | Categorical comparisons with a single focus.                       | 2    |
| `.strat-dual`    | Blue substrate (hatched layers) + red overprint annotation block (bracket, ringed × marker, callout, right-side detail).                | Mode 3 dense substrate with analytical overlay.                    | 3    |
| `.contour-dual`  | Blue contour isolines as substrate + red dashed route, red waypoint markers, red landmark labels.                                       | Mode 3 topographic with an active layer (route, intervention).     | 3    |
| `.blockdiag`     | Hand-authored systems schematic: typed blocks with ports, labelled directed edges, orthogonal routing, an explicit feedback path. Black chrome; the feedback / active edge may carry the accent ink (dashed). | Cybernetic / control-system / signal-flow / dependency topology.   | 1–2  |

### Cybernetic block diagrams (`.blockdiag`)

The signature figure of the manual aesthetic. A control-system / signal-flow schematic, drawn by hand — *not* an auto-layout graph. This is the one place the node-and-edge form is encouraged, because it is deliberate, not generated.

- **Typed blocks.** Hairline rectangles, each with a `--display` block label (`C(s)`, `G(s)`), a small descriptive label (`controller`), and an `.lbl-id` carrying the node ID and ports (`N-02 :err→:u`). A summing junction is a circle with `+`/`−` signs.
- **Directed edges.** Solid hairline forward paths with small triangular arrowheads; orthogonal (right-angle) routing, never curved or diagonal. Edge labels in italic mono outside the line (`error e`, `drive u`).
- **Explicit feedback.** The feedback / active path is the one diagram element that may carry the accent ink — a **dashed** edge (`.edge-fb`) routing back to the junction, labelled (`b = H·y (negative)`). In Mode 1 keep it black-dashed; in Mode 2 it may be the single ink.
- **No fills, no shadows, no gradients.** Line and label only. Node IDs key to a node-register table (§ Addressability).

CSS ships in `assets/style-tokens.css` (`figure.blockdiag` / `.node` / `.edge` / `.edge-fb` / `.lbl-*`). Lay the diagram out by hand in SVG; do not reach for a graphing library.

### What data viz *may not* do

- Soft-alpha translucent zone fills — reads as dashboard infographic.
- Node-and-edge graphs with dotted secondary lines — reads as d3 / Mermaid / graphviz default.
- Concentric circles with soft fills — reads as audience-target marketing slide.
- Text embedded inside bars, filled strata, shaded regions, nodes, or other plotted shapes. Labels belong outside the marks: on axes, in margin columns, in captions, or connected by leader ticks/callouts.
- Procedural halftone or dot-matrix generated inline in SVG — almost always amateurish; use a prepared raster if treated imagery is required.
- Three or more data-ink colours.
- Symmetric two-colour data series — see Mode 3 rules.
- Pie charts or donut charts — not in this register, ever.

### Assets

These are the canonical, copy-pasteable implementations:

- `assets/data-viz.css` — every chart class above, plus `.ink-red` / `.ink-blue` helpers for wrapping `<g>` elements in dual-ink figures.
- `assets/data-viz-defs.svg` — shared SVG `<defs>` containing the five stratigraphic hatch patterns and a 260-point Clifford attractor cloud. Patterns and cloud use `currentColor` so they inherit the using element's ink.

To use in any document:

```html
<head>
  <link rel="stylesheet" href="assets/style-tokens.css">
  <link rel="stylesheet" href="assets/data-viz.css">
</head>
<body>
  <!-- inline the defs once near the top of <body> so figures can reference them -->
  <!-- contents of assets/data-viz-defs.svg here -->
  …
</body>
```

For single-file standalone artifacts, paste the relevant CSS and `<defs>` directly into the document. The patterns are designed to inline cleanly.

### Ink binding inside a figure

In Mode 2 the figure's parent class (`.contour`, `.strat`, etc.) sets `color: var(--accent)` and the inks resolve via `currentColor`. In Mode 3, wrap the relevant SVG fragments in `<g class="ink-red">` or `<g class="ink-blue">` to bind each ink to its role:

```html
<figure class="strat-dual">
  <svg viewBox="…">
    <g class="ink-blue">
      <!-- hatched substrate rects referencing hatch-strat-* patterns -->
    </g>
    <g class="ink-red">
      <!-- annotation bracket, callout, labels -->
    </g>
    <!-- black chrome: frame, ticks, labels -->
  </svg>
</figure>
```

## Motion

Keep motion minimal. Acceptable: hover underlines, focus rings, smooth in-page anchor scrolling.

Avoid: blinking dots, pulsing accents, bounce, parallax, ambient animation, decorative microinteractions.

Respect `prefers-reduced-motion`.

## Copywriting style

Write like a technical archive, field report, or system log.

Good:

```text
Every relation indexed. Every signal preserved.
A working archive of models, notes, prototypes, and field observations.
This document maps the current system boundary, unresolved risks, and the next useful investigation steps.
```

Avoid generic SaaS phrasing:

```text
Supercharge your productivity with seamless workflows.
```

Prefer exact, grounded labels over hype. Prose itself should be tight — cut adverbs, transitions, and meta-narration. A four-row table beats a four-sentence paragraph when the items are parallel.

## Accessibility and usability

The aesthetic must never make the artifact hard to use.

Checklist:

- Maintain strong contrast.
- Keep body text readable. 13px serif body is the floor.
- Use real headings.
- Use visible focus states.
- Avoid tiny essential text.
- Avoid color-only meaning.
- Preserve keyboard navigation.
- Add ARIA labels only when semantic HTML is not enough.
- Make dense layouts responsive rather than cramped.
- Use `prefers-reduced-motion` for animated effects.
- Provide `alt` text for halftone and blueprint imagery describing the subject (e.g. `alt="Halftone rendering of a Doric column"`).

## Code behavior

When writing HTML/CSS:

- Default to a single self-contained file.
- Include style tokens near the top.
- Use CSS Grid and Flexbox.
- Use system font fallbacks (no font imports unless the user permits external dependencies).
- Keep class names meaningful.
- Avoid unnecessary frameworks.
- If using Tailwind or React, preserve the same visual grammar: hairline rules, white page, serif prose, black terminal blocks, booktabs tables, monochrome / duotone imagery only.

## Visual references

No raster reference images are stored in this skill. The imagery rules above are
the canonical references: blueprint technical illustration, one-bit dot-matrix
subjects, orange/red duotone halftones, and documentary monochrome photography.
When designing imagery for a new page, choose the closest treatment and make the
image carry real subject matter.

## Final quality checklist

Before finishing, verify:

- Page background is white (pure black appears only inside terminal blocks and blueprint imagery containers).
- Body prose is monospace (IBM Plex Mono); headings and chrome use the Space Mono display register; all labels are mono (uppercase letterspaced or italic lowercase). No proportional serif or proportional sans anywhere. The page measure is centered with symmetric margins and no side border (not boxed).
- Terminal/code blocks are black-with-light-text and are the only chrome-dark elements on the page.
- Tables follow booktabs convention (heavy top/bottom rules, thin header rule, no verticals, captioned below).
- Section headings are numbered; subsections use `§`.
- Density is compressed (12–13px body, 1.4–1.45 line-height, tight section spacing, dense two-column running prose).
- Structure is addressable: typed blocks with stable namespaced IDs, section address markers, live cross-reference chips, semantic markup. IDs resolve to real records.
- Any systems diagram is a hand-authored `.blockdiag` (typed blocks, orthogonal edges, explicit feedback), not an auto-layout graph.
- No decorative stripes, blinking dots, dot-grid backgrounds, retro ASCII-art flow diagrams, oversized display heros, accent-color buttons, or pill ornaments.
- No cover or decorative imagery on the title page (or anywhere) unless it carries content. Default to no imagery.
- No procedural halftone, dot-matrix, or ASCII SVG generated inline. Use pre-rendered assets if treated imagery is needed.
- Title is not artificially width-constrained (no `max-width: …ch` on the `<h1>`).
- Paragraphs are not double-constrained with `ch` widths inside the page measure.
- Title-page metadata uses one of the dict variants (see § Dictionaries). Default to `dl.dict-grid` (hairline grid) or `.dict-strip` (inline strip). Reserve the dark plate (`dl.meta`) for genuine dossier artifacts.
- Each dark surface on the page carries real content — terminal commands, blueprint diagrams, or specifications. No black field exists for visual variety alone.
- Imagery is monochrome or duotone: blueprint hairline drawings, dot-matrix halftones, orange/red duotone halftones, or monochrome photography. Orange/red appears only inside imagery, never as chrome.
- Imagery subjects favor classical, architectural, sculptural, mechanical, botanical, or pure-geometric references — paired with computational treatment where dot-matrix is used.
- SVG flow diagrams are clean hairline strokes with `Fig. N` captions.
- Hairline rules and tabular structure carry the page, not shadows or filled cards.
- Print stylesheet inverts terminal blocks for legibility.
- Responsive at narrow widths without losing the typographic hierarchy.
- `alt` text describes halftone and blueprint imagery subjects.
- Colour mode is explicit. If the document uses any non-black ink it is Mode 2 (single ink) or Mode 3 (asymmetric dual ink); pick the lowest mode that does the job and follow the relevant rules.
- Accent inks appear only on the data and diagram surface of figures, and on the narrow editorial register (state cells, revision marks, footnote markers, drop-cap initials). Never as chrome, links, dividers, paint, or decoration.
- In Mode 3, the red-leads / blue-supports asymmetry can be named in one sentence. If it cannot, drop to Mode 2.
- Data figures use one of the named patterns (`.scatter`, `.contour`, `.strat`, `.anno`, `.bars`, `.strat-dual`, `.contour-dual`) — not soft-alpha zones, node-edge graphs, concentric soft circles, or pie/donut charts.
- Data labels are outside the plotted marks. No text sits inside bars, filled strata, shaded regions, nodes, or other enclosed data shapes.
