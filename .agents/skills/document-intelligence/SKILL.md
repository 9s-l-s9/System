---
name: document-intelligence
description: >
  Parse PDFs and other source documents into LLM-friendly artifacts using Docling. Use when Codex needs to convert a document into structured Markdown, JSON, JSONL chunks, extracted tables, OCR-aware text, document summaries, RAG-ready corpora, or inspection notes while preserving layout, headings, reading order, tables, figures, page provenance, and conversion caveats. Prefer this skill for PDF-to-Markdown/JSON workflows, scanned document handling, document QA preparation, and document-ingestion pipelines.
---

# Document Intelligence

Use this skill to convert PDFs and related document formats into artifacts that an LLM can read, cite, chunk, and reason over.

## Core Rule

Prefer Docling for document conversion. It provides PDF layout understanding, reading order, table structure recognition, OCR support, and exports such as Markdown and lossless JSON. Do not use quick text extraction (`pdftotext`, `strings`, naive PDF loaders) unless the user explicitly wants speed over structure or Docling is unavailable.

Primary output should be:

- `Markdown` for direct LLM reading and human review.
- `JSON` for lossless document structure, provenance, and downstream processing.
- `JSONL chunks` for RAG/indexing, with stable chunk IDs and source metadata.

## Trigger Policy

Use this skill when the user asks to:

- Parse, convert, ingest, OCR, summarize, chunk, or inspect a PDF.
- Turn a PDF into Markdown, JSON, structured text, RAG data, or an LLM-friendly format.
- Extract document tables, sections, headings, figures, formulas, references, or page-level provenance.
- Build or debug a document-ingestion pipeline where Docling is the preferred parser.

Do not use this skill for ordinary text files, hand-written prose, or document styling tasks unless document parsing or ingestion is part of the request.

## Bundled Script

Use `scripts/docling-parse` for normal conversions. It uses Docker by default to avoid native-library conflicts between Docling's PyPI wheels and Guix. By default it converts PDFs one page at a time for low-memory safety:

```sh
.agents/skills/document-intelligence/scripts/docling-parse input.pdf
.agents/skills/document-intelligence/scripts/docling-parse input.pdf -o build/documents
.agents/skills/document-intelligence/scripts/docling-parse input.pdf --chunk-size 1800 --chunk-overlap 180
.agents/skills/document-intelligence/scripts/docling-parse input.pdf --page-range 1:1
.agents/skills/document-intelligence/scripts/docling-parse input.pdf --batch-pages 3
.agents/skills/document-intelligence/scripts/docling-parse input.pdf --no-json --no-chunks
```

Default outputs:

```text
<out-dir>/<stem>.md
<out-dir>/<stem>.json
<out-dir>/<stem>.chunks.jsonl
<out-dir>/<stem>.manifest.json
```

When `--page-range` or `--batch-pages` is used, the page range is appended to output stems, e.g. `<stem>-pages-1-3.md`, so low-RAM batch runs do not overwrite each other.

The script uses Docling's Python API:

```python
from docling.document_converter import DocumentConverter

converter = DocumentConverter()
result = converter.convert(source)
markdown = result.document.export_to_markdown()
```

If the script does not fit the task, use the same API directly in a project-specific script.

## Container Backend

Default backend:

```sh
.agents/skills/document-intelligence/scripts/docling-parse input.pdf
```

The launcher uses Docker by default and builds `local/document-intelligence-docling:v11` from `docker/Dockerfile` if the image is missing. Local files are copied into a mounted `.docling-inputs/` directory under the current working directory before the container runs, so host path identity does not matter.
If no `--page-range` or `--batch-pages` is provided, the launcher defaults to `--batch-pages 1` to avoid Docker status `137` on low-RAM systems.
Docling layout model snapshots from Hugging Face are symlink-heavy, so the launcher materializes the required layout files into a regular-file cache before bind mounting them into Docker.
If no local layout artifacts are available, the launcher unsets `DOCLING_ARTIFACTS_PATH` so Docling can download/populate models into the mounted writable cache.
Podman is opt-in because rootless Podman depends on host `/etc/subuid`, `/etc/subgid`, policy, and storage configuration that may not exist on minimal or Guix-heavy systems.

Controls:

- `DOCLING_CONTAINER=0` disables the container backend and uses local Python/Guix fallback.
- `DOCLING_CONTAINER_ENGINE=docker` is the default.
- `DOCLING_CONTAINER_ENGINE=podman` selects Podman only when the host is configured for rootless image builds.
- `DOCLING_CONTAINER_ENGINE=auto` tries Docker first, then Podman.
- `DOCLING_CONTAINER_IMAGE=...` selects another image tag.
- `DOCLING_CONTAINER_BUILD=0` disables automatic image builds.
- `DOCLING_CONTAINER_REQUIRED=1` fails immediately if the selected container engine is unavailable.
- `DOCLING_DEFAULT_BATCH_PAGES=1` is the default low-memory batch size. Set `DOCLING_DEFAULT_BATCH_PAGES=0` to attempt full-document conversion.
- `DOCLING_REQUIRE_LOCAL_ARTIFACTS=1` fails if cached layout artifacts cannot be found instead of allowing Docling to download them.
- `DOCLING_LAYOUT_ARTIFACTS=/path/to/docling-layout-heron/snapshot` pins the local layout model directory. By default the launcher first checks the known cached snapshot, then searches `docling-layout-heron` snapshots under the local Hugging Face cache.
- `DOCLING_LAYOUT_ARTIFACT_CACHE=/path/to/cache` selects the dereferenced layout-artifact directory mounted into Docker. By default it uses `$XDG_CACHE_HOME/codex-document-intelligence/docling-layout-heron-artifacts`.
- `DOCLING_LAYOUT_ARTIFACT_FALLBACK_CACHE=/path/to/cache` selects the fallback cache used when the normal cache is not writable. By default it uses `/tmp/codex-document-intelligence-<uid>/docling-layout-heron-artifacts`.
- `DOCLING_LAYOUT_HF_ROOT=/path/to/models--docling-project--docling-layout-heron` selects the Hugging Face cache root to search.
- When Podman is used, the launcher writes `~/.config/containers/policy.json` with `insecureAcceptAnything` so the build does not depend on host container policy configuration.

The launcher is standalone: it tries the configured container backend first, then falls back to an existing `python3`/`python` with Docling, a cached virtual environment under `$XDG_CACHE_HOME/codex-document-intelligence`, and finally the skill-local Guix manifest when Guix is available. First run may need network access to build the image, install Docling into the cached venv, or download Docling model assets.

On Linux, the launcher installs Docling with the official CPU-only PyTorch index to avoid accidentally downloading GPU/CUDA wheels:

```sh
python3 -m pip install --extra-index-url https://download.pytorch.org/whl/cpu docling
```

Controls:

- `DOCLING_PARSE_VENV=/path/to/venv` selects the cached venv path.
- `DOCLING_PARSE_PACKAGE=docling==...` pins or changes the Docling package spec.
- `DOCLING_PARSE_TORCH_INDEX=...` changes the extra PyTorch package index.

For low-RAM machines, keep the default one-page batching. Docker exit status `137` means the container was killed, usually by memory pressure.

The skill includes `manifest.scm` so Guix-based harnesses can load a minimal Python environment:

```sh
guix shell -m .agents/skills/document-intelligence/manifest.scm -- \
  .agents/skills/document-intelligence/scripts/docling-parse input.pdf
```

## LLM-Friendly Output Contract

When producing artifacts for later LLM use:

- Preserve the original document order. Do not alphabetize or regroup sections unless asked.
- Keep headings as Markdown headings. They are the cheapest useful hierarchy signal.
- Keep tables as Markdown tables when possible; use JSON for complex table structure.
- Keep figure captions and nearby text together.
- Include source metadata: original file path, conversion timestamp, parser, output paths, and known caveats.
- Use stable chunk IDs like `<document-stem>-chunk-0001`.
- Prefer semantic chunks split on headings and paragraphs before size limits.
- Add overlap only between adjacent chunks; do not duplicate entire sections.
- Record uncertainty. If OCR, tables, formulas, or reading order look suspect, say so in the manifest or final response.

## Workflow

1. Inspect the source file path, type, and expected output.
2. Run the bundled script unless the project already has a Docling ingestion path.
3. Review the first part of the Markdown and the manifest before using the output.
4. For scanned PDFs, enable Docling OCR options in a project-specific script if default conversion is insufficient.
5. For RAG, index JSONL chunks and retain the full Markdown/JSON beside the index for auditability.
6. In the final response, report output paths, conversion status, and any caveats.

## Quality Checks

After conversion, verify:

- The Markdown has real headings and not one flat text block.
- Tables are not collapsed into unreadable line noise.
- Repeated headers/footers are not dominating chunks.
- Page order and reading order make sense around multi-column layouts.
- The chunk file contains useful section titles or breadcrumbs.
- The manifest records the tool and source path.

For high-stakes uses, sample multiple pages manually. Docling is strong, but PDF extraction is never guaranteed to be lossless.

## Installation

If Docling is missing:

```sh
python3 -m pip install --extra-index-url https://download.pytorch.org/whl/cpu docling
```

Docling may download model assets on first use. If network access is restricted, report that model installation or cache population is required rather than falling back silently to lower-quality parsing.

## Failure Handling

If Docling fails:

- Report the exact command and the failure mode.
- Check whether the input is encrypted, image-only, malformed, or too large.
- Try a smaller page range or a project-specific Docling configuration if appropriate.
- Do not substitute naive text extraction without clearly labeling it as lower fidelity.

If only a summary is requested, still preserve the parsed Markdown/JSON when feasible so the answer can be audited later.
