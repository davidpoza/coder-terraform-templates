# Imagen base con escritorio KDE
FROM ghcr.io/makespacemadrid/coder-mks-desktop:latest

LABEL org.opencontainers.image.title="coder-mks-developer" \
      org.opencontainers.image.description="Coder Desktop extendido con utilidades dev, Docker, IA CLI y tooling de consola" \
      org.opencontainers.image.source="https://github.com/makespacemadrid/coder-workspaces" \
      org.opencontainers.image.url="ghcr.io/makespacemadrid/coder-mks-developer:latest" \
      com.centurylinklabs.watchtower.enable="true" \
      com.centurylinklabs.watchtower.scope="coder-workspaces" \
      com.centurylinklabs.watchtower.lifecycle="rolling"

USER root

ENV DEBIAN_FRONTEND=noninteractive

# Paquetes adicionales de desarrollo sobre la base desktop
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        # herramientas de desarrollo genéricas
        build-essential \
        pkg-config \
        python3 python3-venv python3-pip pipx \
        # navegador dentro del KasmVNC (via PPA, evita snap)
        firefox \
        # utilidades extra y tooling de consola
        jq \
        gnupg \
        git-lfs \
        pre-commit \
        dbus \
        dbus-x11 \
        cifs-utils \
        nfs-common \
        sshfs \
        fuse3 \
        libfuse2 \
        geany \
        desktop-file-utils \
        dnsutils \
        net-tools \
        lsof \
        htop \
        ripgrep \
        fzf \
        bat \
        eza \
        tmux \
        direnv \
        yq \
        sqlite3 \
        zip unzip p7zip-full \
        command-not-found \
        bash-completion \
        nano \
        iputils-ping \
        byobu \
        pulseaudio \
        pulseaudio-utils \
        alsa-utils \
        # dependencias que hoy se instalan en runtime (VNC/Perl)
        libdatetime-perl \
        liblist-moreutils-perl \
        libyaml-tiny-perl \
        libhash-merge-simple-perl \
        libxfont2 \
        libfontenc1 \
        ssl-cert \
    && rm -rf /var/lib/apt/lists/*

# Configuración FUSE para permitir AppImages (allow_other)
RUN echo "user_allow_other" > /etc/fuse.conf

# KasmVNC viene como módulo de Coder; solo dejamos KDE como session manager
RUN update-alternatives --set x-session-manager /usr/bin/startplasma-x11 || true

# Locales (puedes ajustar a gusto)
RUN locale-gen es_ES.UTF-8 en_US.UTF-8 && \
    update-locale LANG=es_ES.UTF-8

ENV LANG=es_ES.UTF-8 \
    LC_ALL=es_ES.UTF-8

# Docker Engine y Docker Compose desde el repo oficial de Docker
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
      | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI (repositorio oficial)
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | gpg --dearmor -o /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends gh && \
    rm -rf /var/lib/apt/lists/*

# Google Chrome (repositorio oficial)
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg && \
    chmod a+r /etc/apt/keyrings/google-chrome.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
      | tee /etc/apt/sources.list.d/google-chrome.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# Antigravity auto-updater
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg && \
    chmod a+r /etc/apt/keyrings/antigravity-repo-key.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" \
      | tee /etc/apt/sources.list.d/antigravity.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends antigravity && \
    rm -rf /var/lib/apt/lists/*

# Node.js 22 LTS y las CLIs de IA para trabajo con código
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
      | tee /etc/apt/sources.list.d/nodesource.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends nodejs && \
    npm install -g --omit=dev --no-update-notifier --no-fund \
        pnpm \
        yarn \
        @openai/codex \
        @anthropic-ai/claude-code \
        @google/gemini-cli \
        @continuedev/cli \
        @qwen-code/qwen-code && \
    npm cache clean --force && \
    rm -rf /var/lib/apt/lists/*

# Visual Studio Code (repositorio oficial Microsoft)
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg && \
    chmod a+r /etc/apt/keyrings/microsoft.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
      | tee /etc/apt/sources.list.d/vscode.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends code && \
    rm -rf /var/lib/apt/lists/*

# Utilidades NVIDIA para poder usar `nvidia-smi` cuando hay GPUs
RUN set -e; \
    apt-get update; \
    if ! apt-get install -y --no-install-recommends nvidia-utils-535; then \
      if ! apt-get install -y --no-install-recommends nvidia-utils-530; then \
        apt-get install -y --no-install-recommends nvidia-utils-525 || true; \
      fi; \
    fi; \
    rm -rf /var/lib/apt/lists/*

# GitHub Desktop (shiftkey build) y Claude Desktop (unofficial build)
ARG GITHUB_DESKTOP_REPO=shiftkey/desktop
ARG CLAUDE_DESKTOP_REPO=aaddrick/claude-desktop-debian
RUN set -e; \
    GH_DESKTOP_URL="$(curl -fsSL "https://api.github.com/repos/${GITHUB_DESKTOP_REPO}/releases/latest" | \
      jq -r '.assets[] | select(.name | test("GitHubDesktop-linux-amd64-.*\\.deb$")) | .browser_download_url' | head -n1)"; \
    CLAUDE_URL="$(curl -fsSL "https://api.github.com/repos/${CLAUDE_DESKTOP_REPO}/releases/latest" | \
      jq -r '.assets[] | select(.name | test("claude-desktop_.*_amd64\\.deb$")) | .browser_download_url' | head -n1)"; \
    if [ -z "$GH_DESKTOP_URL" ] || [ -z "$CLAUDE_URL" ]; then \
      echo "No se encontraron assets .deb en GitHub releases" >&2; \
      exit 1; \
    fi; \
    curl -fsSL "$GH_DESKTOP_URL" -o /tmp/github-desktop.deb; \
    curl -fsSL "$CLAUDE_URL" -o /tmp/claude-desktop.deb; \
    apt-get update; \
    apt-get install -y --no-install-recommends /tmp/github-desktop.deb /tmp/claude-desktop.deb; \
    rm -rf /var/lib/apt/lists/* /tmp/github-desktop.deb /tmp/claude-desktop.deb

# Electron apps dentro de contenedores Docker necesitan desactivar el sandbox
# (no hay user namespaces). Los wrappers añaden --no-sandbox y pistas de Ozone.
ENV ELECTRON_DISABLE_SANDBOX=1 \
    ELECTRON_OZONE_PLATFORM_HINT=auto
RUN <<'EOSH'
set -e
wrap() {
  local name="$1"; local target="$2"; local extra="$3"
  if [ -x "$target" ]; then
    mv "$name" "${name}.real" || true
    cat > "$name" <<SHWRAP
#!/bin/sh
exec env ELECTRON_DISABLE_SANDBOX=1 ELECTRON_OZONE_PLATFORM_HINT="${ELECTRON_OZONE_PLATFORM_HINT:-auto}" \
  "$target" --no-sandbox --disable-gpu-sandbox --disable-setuid-sandbox --disable-seccomp-filter-sandbox --no-zygote $EXTRA_FLAGS "$@"
SHWRAP
    chmod +x "$name"
  fi
}
TARGET_BIN=/usr/lib/github-desktop/github-desktop EXTRA_FLAGS="--password-store=basic" wrap /usr/bin/github-desktop /usr/lib/github-desktop/github-desktop
TARGET_BIN=/usr/share/claude-desktop/claude-desktop EXTRA_FLAGS="--disable-gpu" wrap /usr/bin/claude-desktop /usr/share/claude-desktop/claude-desktop
TARGET_BIN=/usr/share/code/bin/code EXTRA_FLAGS="" wrap /usr/bin/code /usr/share/code/bin/code
EOSH

# Extensiones VS Code preinstaladas para escritorio/remoto
RUN su - coder -c 'set -e; \
  EXT_LIST="anthropic.claude-code opencodeai.opencode google.gemini-code-assistant qwen-team.qwen-vscode openai.openai"; \
  for ext in $EXT_LIST; do \
    code --install-extension "$ext" --force --user-data-dir /home/coder/.vscode/data --extensions-dir /home/coder/.vscode/extensions || true; \
  done; \
  mkdir -p /home/coder/.vscode-server/extensions'

# AppImage Pool (gestor de AppImages con actualizaciones e integración en menú)
ARG APPIMAGEPOOL_VERSION=5.0.0
RUN <<'EOSH'
set -e
mkdir -p /opt/appimagepool
APPIMAGE_URLS=" \
  https://github.com/prateekmedia/appimagepool/releases/download/${APPIMAGEPOOL_VERSION}/appimagepool-${APPIMAGEPOOL_VERSION}-x86_64.AppImage \
  https://github.com/prateekmedia/appimagepool/releases/download/${APPIMAGEPOOL_VERSION}/AppImagePool-${APPIMAGEPOOL_VERSION}-x86_64.AppImage \
  https://github.com/prateekmedia/appimagepool/releases/download/${APPIMAGEPOOL_VERSION}/AppImagePool-${APPIMAGEPOOL_VERSION}.x86_64.AppImage \
  https://github.com/prateekmedia/appimagepool/releases/latest/download/appimagepool-latest-x86_64.AppImage \
  https://github.com/prateekmedia/appimagepool/releases/latest/download/AppImagePool-latest-x86_64.AppImage \
"
found=""
for url in $APPIMAGE_URLS; do
  if curl -fLsS "${url}" -o /opt/appimagepool/AppImagePool.AppImage; then
    found="$url"
    break
  fi
done
if [ -z "$found" ] || [ ! -s /opt/appimagepool/AppImagePool.AppImage ]; then
  echo "AppImage Pool download failed" >&2
  exit 1
fi
chmod +x /opt/appimagepool/AppImagePool.AppImage
ln -sf /opt/appimagepool/AppImagePool.AppImage /usr/local/bin/appimagepool
cat <<'EOFICON' > /usr/share/icons/hicolor/scalable/apps/appimagepool.svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" role="img">
  <defs>
    <linearGradient id="grad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#1b8cf2"/>
      <stop offset="100%" stop-color="#0c5ea8"/>
    </linearGradient>
  </defs>
  <rect width="64" height="64" rx="12" fill="url(#grad)"/>
  <path fill="#fff" d="M32 10c-3 0-5.4 2.4-5.4 5.4S29 20.8 32 20.8s5.4-2.4 5.4-5.4S35 10 32 10Zm0 12.9c-3 0-5.4 2.4-5.4 5.4S29 33.6 32 33.6s5.4-2.4 5.4-5.4S35 22.9 32 22.9Zm0 12.9c-3 0-5.4 2.4-5.4 5.4S29 46.6 32 46.6s5.4-2.4 5.4-5.4S35 35.8 32 35.8Z"/>
  <path fill="#e8f3ff" d="M18 18h4v28h-4zm24 0h4v28h-4z"/>
</svg>
EOFICON
cat <<'EOF' > /usr/share/applications/appimagepool.desktop
[Desktop Entry]
Type=Application
Name=AppImage Pool
Exec=appimagepool
Icon=appimagepool
Categories=Utility;
EOF
EOSH
RUN update-desktop-database /usr/share/applications || true && \
    gtk-update-icon-cache -q /usr/share/icons/hicolor || true

# Accesos directos en el escritorio por defecto
RUN set -e; \
    mkdir -p /etc/skel/Desktop && \
    for f in code.desktop github-desktop.desktop claude-desktop.desktop firefox.desktop geany.desktop appimagepool.desktop; do \
      src="/usr/share/applications/$f"; \
      if [ -f "$src" ]; then ln -sf "$src" "/etc/skel/Desktop/$f"; fi; \
    done; \
    chmod +x /etc/skel/Desktop/*.desktop || true

ENV PIPX_HOME=/opt/pipx \
    PIPX_BIN_DIR=/opt/pipx/bin \
    PATH="/opt/pipx/bin:/usr/local/bin:${PATH}"

# Crear directorios de pipx y dar permisos al usuario coder (UID 1000)
RUN mkdir -p /opt/pipx /opt/pipx/bin /opt/pipx/venvs && \
    chown -R 1000:1000 /opt/pipx && \
    mkdir -p /home/coder/.local && \
    ln -sfn /opt/pipx/bin /home/coder/.local/bin && \
    chown -R 1000:1000 /home/coder/.local
