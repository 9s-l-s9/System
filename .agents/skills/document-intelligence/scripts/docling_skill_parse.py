"""Convert documents with Docling into Markdown, JSON, and JSONL chunks."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import sys
from pathlib import Path
from typing import Any


def log(message: str) -> None:
    print(f"docling-parse: {message}", file=sys.stderr, flush=True)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert a document with Docling into LLM-friendly artifacts."
    )
    parser.add_argument("source", help="Local file path or URL accepted by Docling.")
    parser.add_argument(
        "-o",
        "--out-dir",
        default="build/document-intelligence",
        help="Directory for generated artifacts.",
    )
    parser.add_argument(
        "--chunk-size",
        type=int,
        default=1800,
        help="Approximate maximum chunk size in characters.",
    )
    parser.add_argument(
        "--chunk-overlap",
        type=int,
        default=180,
        help="Approximate character overlap between adjacent chunks.",
    )
    parser.add_argument("--no-json", action="store_true", help="Skip JSON export.")
    parser.add_argument("--no-chunks", action="store_true", help="Skip JSONL chunks.")
    parser.add_argument(
        "--max-pages",
        type=int,
        default=0,
        help="Reject documents with more than this many pages. Use 0 for Docling's default/no explicit limit.",
    )
    parser.add_argument(
        "--page-range",
        default="",
        help="1-based inclusive page range to convert, for example 1:1 or 3:8.",
    )
    parser.add_argument(
        "--batch-pages",
        type=int,
        default=0,
        help=argparse.SUPPRESS,
    )
    return parser.parse_args()


def safe_stem(source: str) -> str:
    stem = Path(source).stem or "document"
    stem = re.sub(r"[^A-Za-z0-9._-]+", "-", stem).strip("-._")
    return stem or "document"


def document_to_json(document: Any) -> dict[str, Any]:
    if hasattr(document, "export_to_dict"):
        data = document.export_to_dict()
    elif hasattr(document, "model_dump"):
        data = document.model_dump(mode="json")
    elif hasattr(document, "dict"):
        data = document.dict()
    else:
        raise TypeError("Docling document does not expose a known JSON export method.")

    if not isinstance(data, dict):
        raise TypeError("Docling JSON export did not return an object.")
    return data


def split_markdown(markdown: str, chunk_size: int, overlap: int) -> list[dict[str, Any]]:
    blocks = re.split(r"\n{2,}", markdown.strip())
    chunks: list[dict[str, Any]] = []
    current: list[str] = []
    current_size = 0
    heading_stack: list[str] = []
    current_headings: list[str] = []

    def push() -> None:
        nonlocal current, current_size, current_headings
        text = "\n\n".join(current).strip()
        if not text:
            current = []
            current_size = 0
            return
        chunks.append(
            {
                "text": text,
                "headings": current_headings,
                "char_count": len(text),
            }
        )
        tail = text[-overlap:] if overlap > 0 else ""
        current = [tail] if tail else []
        current_size = len(tail)
        current_headings = list(heading_stack)

    for block in blocks:
        heading = re.match(r"^(#{1,6})\s+(.+?)\s*$", block)
        if heading:
            level = len(heading.group(1))
            title = heading.group(2)
            heading_stack = heading_stack[: level - 1]
            heading_stack.append(title)

        block_size = len(block) + 2
        if current and current_size + block_size > chunk_size:
            push()
        if not current_headings:
            current_headings = list(heading_stack)
        current.append(block)
        current_size += block_size

    push()
    return chunks


def write_chunks(
    path: Path,
    source: str,
    stem: str,
    markdown: str,
    chunk_size: int,
    overlap: int,
) -> int:
    chunks = split_markdown(markdown, chunk_size, overlap)
    with path.open("w", encoding="utf-8") as handle:
        for index, chunk in enumerate(chunks, start=1):
            record = {
                "id": f"{stem}-chunk-{index:04d}",
                "source": source,
                "chunk_index": index,
                "headings": chunk["headings"],
                "text": chunk["text"],
                "char_count": chunk["char_count"],
            }
            handle.write(json.dumps(record, ensure_ascii=False) + "\n")
    return len(chunks)


def parse_page_range(value: str) -> tuple[int, int] | None:
    if not value:
        return None
    match = re.match(r"^(\d+)(?::(\d+))?$", value.strip())
    if not match:
        raise ValueError("--page-range must look like 1:1, 1:3, or 5")
    start = int(match.group(1))
    end = int(match.group(2) or match.group(1))
    if start < 1 or end < start:
        raise ValueError("--page-range uses 1-based pages and requires end >= start")
    return (start, end)


def main() -> int:
    args = parse_args()
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    stem = safe_stem(args.source)
    enable_ocr = os.environ.get("DOCLING_ENABLE_OCR", "0") == "1"
    page_range = parse_page_range(args.page_range)
    if page_range is not None:
        stem = f"{stem}-pages-{page_range[0]}-{page_range[1]}"

    try:
        from docling.datamodel.base_models import InputFormat
        from docling.datamodel.pipeline_options import (
            PdfPipelineOptions,
            TesseractCliOcrOptions,
        )
        from docling.document_converter import DocumentConverter
        from docling.document_converter import PdfFormatOption
    except ImportError as exc:
        print(
            f"Docling import failed in the selected Python environment: {exc}",
            file=sys.stderr,
        )
        return 2

    pipeline_options = PdfPipelineOptions()
    pipeline_options.do_ocr = enable_ocr
    pipeline_options.do_table_structure = False
    pipeline_options.force_backend_text = True
    pipeline_options.ocr_options = TesseractCliOcrOptions()

    converter = DocumentConverter(
        format_options={
            InputFormat.PDF: PdfFormatOption(pipeline_options=pipeline_options)
        }
    )
    log(f"converting {args.source}")
    convert_kwargs: dict[str, Any] = {}
    if args.max_pages > 0:
        log(f"using max_pages rejection limit={args.max_pages}")
        convert_kwargs["max_num_pages"] = args.max_pages
    if page_range is not None:
        log(f"using page_range={page_range[0]}:{page_range[1]}")
        convert_kwargs["page_range"] = page_range

    if convert_kwargs:
        result = converter.convert(args.source, **convert_kwargs)
    else:
        result = converter.convert(args.source)
    log("conversion finished; exporting markdown")
    document = result.document
    markdown = document.export_to_markdown()

    md_path = out_dir / f"{stem}.md"
    json_path = out_dir / f"{stem}.json"
    chunks_path = out_dir / f"{stem}.chunks.jsonl"
    manifest_path = out_dir / f"{stem}.manifest.json"

    log(f"writing markdown to {md_path}")
    md_path.write_text(markdown, encoding="utf-8")

    outputs: dict[str, str] = {"markdown": str(md_path)}
    if not args.no_json:
        log(f"writing json to {json_path}")
        json_path.write_text(
            json.dumps(document_to_json(document), ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        outputs["json"] = str(json_path)

    chunk_count = None
    if not args.no_chunks:
        log(f"writing chunks to {chunks_path}")
        chunk_count = write_chunks(
            chunks_path,
            args.source,
            stem,
            markdown,
            args.chunk_size,
            args.chunk_overlap,
        )
        outputs["chunks_jsonl"] = str(chunks_path)

    outputs["manifest"] = str(manifest_path)
    manifest = {
        "source": args.source,
        "parser": "docling",
        "created_at": dt.datetime.now(dt.timezone.utc).isoformat(),
        "outputs": outputs,
        "chunk_count": chunk_count,
        "chunk_size": None if args.no_chunks else args.chunk_size,
        "chunk_overlap": None if args.no_chunks else args.chunk_overlap,
        "page_range": None if page_range is None else list(page_range),
        "caveats": [
            "Review tables, formulas, OCR text, and multi-column reading order before high-stakes use."
        ],
    }
    manifest_path.write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    log("done")
    print(json.dumps({"ok": True, "outputs": outputs}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
