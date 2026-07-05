FROM debian:bookworm-slim

ARG DRAWIO_VERSION=30.0.4
ARG DRAWIO_DEB_URL=https://github.com/jgraph/drawio-desktop/releases/download/v${DRAWIO_VERSION}/drawio-amd64-${DRAWIO_VERSION}.deb

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates \
       curl \
       xvfb \
       xauth \
       fonts-liberation \
       libasound2 \
       libatk-bridge2.0-0 \
       libatk1.0-0 \
       libcairo2 \
       libcups2 \
       libdbus-1-3 \
       libdrm2 \
       libexpat1 \
       libfontconfig1 \
       libgbm1 \
       libglib2.0-0 \
       libgtk-3-0 \
       libnss3 \
       libnspr4 \
       libpango-1.0-0 \
       libx11-6 \
       libxcb1 \
       libxcomposite1 \
       libxdamage1 \
       libxext6 \
       libxfixes3 \
       libxkbcommon0 \
       libxrandr2 \
       libxrender1 \
       libxshmfence1 \
       libxss1 \
       libxtst6 \
       fonts-dejavu-core \
    && curl -L --fail -o /tmp/drawio.deb "${DRAWIO_DEB_URL}" \
    && apt-get install -y --no-install-recommends /tmp/drawio.deb \
    && rm -rf /var/lib/apt/lists/* /tmp/drawio.deb

COPY drawio-entrypoint /usr/local/bin/drawio-entrypoint
RUN chmod +x /usr/local/bin/drawio-entrypoint

WORKDIR /work
ENTRYPOINT ["drawio-entrypoint"]
