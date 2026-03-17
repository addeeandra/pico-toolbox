# ============================================================
# picoclaw-toolbox
# Ubuntu 24.04 base with picoclaw + multi-modal AI agent tools
# ============================================================
FROM ubuntu:24.04

# Declared here so $GITHUB_REPOSITORY expands in the LABEL below; pass via --build-arg in CI
ARG GITHUB_REPOSITORY=addeeandra/ai-toolbox
LABEL org.opencontainers.image.title="picoclaw-toolbox"
LABEL org.opencontainers.image.description="PicoClaw with a comprehensive toolbox for multi-modal AI agents"
LABEL org.opencontainers.image.source="https://github.com/$GITHUB_REPOSITORY"
LABEL org.opencontainers.image.licenses="MIT"

# ── Build args ───────────────────────────────────────────────
ARG TARGETARCH
ARG PICOCLAW_VERSION=latest
ARG DEBIAN_FRONTEND=noninteractive

# ── Base system ──────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Core utilities
    ca-certificates \
    curl \
    wget \
    git \
    unzip \
    xz-utils \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    # Shell & text tools
    bash \
    jq \
    yq \
    ripgrep \
    fd-find \
    tree \
    less \
    vim \
    nano \
    # Process & system monitoring
    htop \
    procps \
    lsof \
    # Networking
    iputils-ping \
    dnsutils \
    netcat-openbsd \
    openssh-client \
    # Python 3.12 + pip
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    # Image & document processing
    ffmpeg \
    imagemagick \
    poppler-utils \
    tesseract-ocr \
    tesseract-ocr-eng \
    ghostscript \
    # Audio
    sox \
    libsox-fmt-mp3 \
    # Misc
    sqlite3 \
    tzdata \
    locales \
    && rm -rf /var/lib/apt/lists/*

# ── ImageMagick PDF policy ───────────────────────────────────
RUN sed -i 's/rights="none" pattern="PDF"/rights="read|write" pattern="PDF"/' \
    /etc/ImageMagick-6/policy.xml 2>/dev/null || true

# ── Locale ───────────────────────────────────────────────────
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# ── Node.js LTS via NodeSource ────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── GitHub CLI (gh) ───────────────────────────────────────────
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# ── Python AI/ML packages ─────────────────────────────────────
RUN pip3 install --no-cache-dir --break-system-packages \
    # LLM SDKs
    'anthropic>=0.40' \
    'openai>=1.0' \
    google-generativeai \
    # Agent frameworks
    'langchain>=0.3' \
    'langchain-community>=0.3' \
    'langchain-anthropic>=0.3' \
    'langchain-openai>=0.3' \
    # Multi-modal
    Pillow \
    opencv-python-headless \
    # Document processing
    pypdf \
    python-docx \
    openpyxl \
    markdown \
    beautifulsoup4 \
    lxml \
    # Data & utilities
    requests \
    httpx \
    aiohttp \
    'pydantic>=2.0' \
    rich \
    typer \
    python-dotenv \
    # Web scraping
    playwright \
    # MCP SDK
    mcp

# ── Optional heavy packages (--build-arg INSTALL_HEAVY_PACKAGES=true to enable) ──
ARG INSTALL_HEAVY_PACKAGES=false
RUN if [ "$INSTALL_HEAVY_PACKAGES" = "true" ]; then \
    pip3 install --no-cache-dir --break-system-packages \
    openai-whisper \
    chromadb \
    sentence-transformers; \
    fi

# ── Playwright browsers (for web agent capabilities) ──────────
RUN python3 -m playwright install chromium --with-deps || true

# ── Node.js AI packages ───────────────────────────────────────
RUN npm install -g \
    @anthropic-ai/sdk@^0 \
    openai@^4 \
    @modelcontextprotocol/sdk \
    @modelcontextprotocol/server-filesystem \
    @modelcontextprotocol/server-github \
    @modelcontextprotocol/server-brave-search \
    ts-node \
    typescript

# ── Download & install picoclaw binary ───────────────────────
RUN set -eux; \
    ARCH=$(uname -m); \
    case "$ARCH" in \
    x86_64)  BIN_ARCH="x86_64" ;; \
    aarch64) BIN_ARCH="arm64"  ;; \
    *)        echo "Unsupported arch: $ARCH" && exit 1 ;; \
    esac; \
    if [ "$PICOCLAW_VERSION" = "latest" ]; then \
    DOWNLOAD_URL="https://github.com/sipeed/picoclaw/releases/latest/download/picoclaw_Linux_${BIN_ARCH}.tar.gz"; \
    else \
    DOWNLOAD_URL="https://github.com/sipeed/picoclaw/releases/download/${PICOCLAW_VERSION}/picoclaw_Linux_${BIN_ARCH}.tar.gz"; \
    fi; \
    curl -fsSL "$DOWNLOAD_URL" | tar -xz -C /usr/local/bin picoclaw \
    && chmod +x /usr/local/bin/picoclaw

# ── Workspace & config directories ───────────────────────────
ENV PICOCLAW_CONFIG=/root/.picoclaw/config/config.json \
    PICOCLAW_DATA=/root/.picoclaw

RUN mkdir -p \
    /root/.picoclaw/workspace/sessions \
    /root/.picoclaw/workspace/memory \
    /root/.picoclaw/workspace/skills \
    /root/.picoclaw/workspace/cron \
    /root/.picoclaw/config

# ── Copy default config template ─────────────────────────────
COPY config.example.json /root/.picoclaw/config.example.json

# ── Entrypoint wrapper ────────────────────────────────────────
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /root/.picoclaw/workspace

VOLUME ["/root/.picoclaw/workspace", "/root/.picoclaw/config"]

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -sf http://localhost:8080/health || exit 1

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["gateway"]
