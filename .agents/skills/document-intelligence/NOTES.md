# Docling Experiment Note

Last updated: 2026-06-14

- Docker backend is the preferred path; local Guix/Python hit native-library friction.
- Current image tag is `local/document-intelligence-docling:v11` so Docker rebuilds with the latest helper logging, batching support, and without baked `DOCLING_ARTIFACTS_PATH`.
- `--max-pages` is a rejection limit in Docling, not a slicing option. Use `--page-range 1:1` to test a small conversion.
- Full-document conversion can be killed with Docker status 137 on low-RAM systems. Use `--batch-pages 1` or `--batch-pages 3` for reliable range-by-range output.
- Default conversion now implies `--batch-pages 1`; set `DOCLING_DEFAULT_BATCH_PAGES=0` only when intentionally testing full-document conversion.
- Host-path mounting was not the whole issue; Hugging Face snapshot entries are symlinks into `../../blobs`, so Docker needs a dereferenced artifact cache.
- Docling default PDF pipeline still tried to initialize RapidOCR and download/write model files into read-only site-packages.
- Current mitigation: materialize `model.safetensors`, `config.json`, and `preprocessor_config.json` into `$XDG_CACHE_HOME/codex-document-intelligence/docling-layout-heron-artifacts` and mount that directory as `/opt/docling-models`.
- If Docker created the bind source as a root-owned empty directory, the launcher falls back to `/tmp/codex-document-intelligence-<uid>/docling-layout-heron-artifacts`.
- If no local layout artifacts exist, the wrapper runs the container through `sh`, unsets baked `DOCLING_ARTIFACTS_PATH`, and lets Docling populate the mounted writable cache.
- OCR is intended to be opt-in via `DOCLING_ENABLE_OCR=1` for scanned PDFs.
- Podman rootless image unpack hit subordinate UID/GID limits on this host. Treat Podman as explicit opt-in only; default launcher path should stay Docker.
