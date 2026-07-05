---
name: drawio-render
description: Render, export, or batch-convert draw.io / diagrams.net files (.drawio, .drawio.svg, XML diagrams) into images or documents such as SVG, PNG, PDF, HTML, or JPG. Use when Codex needs to convert draw.io XML for project documentation, Typst/LaTeX/Markdown assets, CI build artifacts, or user-requested diagram previews, especially when fidelity matters and the official draw.io desktop renderer should be preferred over third-party XML converters.
---

# Draw.io Render

Use this skill to export draw.io / diagrams.net diagrams into reusable project assets.

## Core Rule

Prefer the official draw.io desktop renderer. Third-party XML-to-SVG converters often mishandle custom shapes, styles, fonts, and multi-page diagrams.

This skill does not install draw.io as a Guix package. Guix may not provide a `drawio` package. On Guix, prefer the bundled Docker/Podman backend, which builds a Debian image from the official draw.io desktop `.deb` and runs the CLI under `xvfb-run`.

- A native `drawio` executable on `PATH`.
- Docker or Podman available to the agent sandbox.
- Flatpak: `com.jgraph.drawio.desktop`.
- Any equivalent command via `DRAWIO_COMMAND="..."`.

## Bundled Script

Use `scripts/drawio-render` from this skill for normal exports:

```sh
guile -s .agents/skills/drawio-render/scripts/drawio-render diagram.drawio
guile -s .agents/skills/drawio-render/scripts/drawio-render -f pdf diagram.drawio -o diagram.pdf
guile -s .agents/skills/drawio-render/scripts/drawio-render -f png --scale 2 --transparent --embed-diagram diagram.drawio
guile -s .agents/skills/drawio-render/scripts/drawio-render --headless -f svg -d build/diagrams diagrams/*.drawio
guile -s .agents/skills/drawio-render/scripts/drawio-render --docker diagram.drawio
```

If the user’s home environment is configured from this repo, `drawio-render` may also be available as a shell alias that delegates to this script.

## Output Choice

- Use SVG for web, Markdown, and Typst when vector output is desired.
- Use PDF for Typst/LaTeX print workflows when PDF inclusion is preferred.
- Use PNG when raster output is required; pass `--scale 2` or higher for crisp results.
- Use `--embed-diagram` for PNG/SVG when the exported asset should remain editable in draw.io.
- Use `--page-index N` for one page or `--all-pages` for multi-page files.

## Headless Use

On systems without `$DISPLAY`, use `--headless` or set `DRAWIO_HEADLESS=1`. Native mode wraps the renderer with `xvfb-run -a` when available. Container mode always runs draw.io under `xvfb-run` inside the image.

If `xvfb-run` is unavailable, report that rendering needs either a display server or Xvfb.

## Docker / Podman Backend

Use this backend on Guix when no host draw.io package exists:

```sh
guile -s .agents/skills/drawio-render/scripts/drawio-render --docker diagram.drawio
```

The script auto-detects `docker` first, then `podman`. It builds `local/drawio-official-cli:30.0.4` from `docker/Dockerfile` if the image is missing.

Controls:

- `DRAWIO_CONTAINER=1` forces container mode.
- `DRAWIO_CONTAINER_ENGINE=podman` or `docker` selects an engine.
- `DRAWIO_CONTAINER_IMAGE=...` selects another image tag.
- `DRAWIO_CONTAINER_BUILD=0` disables automatic image builds.

Container mode mounts the current working directory at `/work`, so run the command from the project root or another directory containing both the input and desired output path.

## Failure Handling

If no renderer is found, do not attempt to hand-convert draw.io XML unless the user explicitly accepts lower fidelity. Tell the user to install/provide Docker/Podman or another official renderer and show one of:

```sh
DRAWIO_CONTAINER=1 guile -s .agents/skills/drawio-render/scripts/drawio-render diagram.drawio
DRAWIO_COMMAND="flatpak run com.jgraph.drawio.desktop" guile -s .agents/skills/drawio-render/scripts/drawio-render diagram.drawio
```
