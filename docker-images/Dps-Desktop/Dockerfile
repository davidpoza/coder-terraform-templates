FROM codercom/enterprise-minimal:latest

USER root
ARG USER=coder
ARG NVM_VERSION=v0.40.3
ARG ECLIPSE_RELEASE=2025-12

# Paquetes base del sistema y escritorio XFCE
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
      ca-certificates \
      curl \
      gnupg \
      git \
      openssh-client \
      software-properties-common \
      mesa-utils \
      dbus-x11 \
      libdatetime-perl \
      openssl \
      ssl-cert \
      zsh \
      xfce4 \
      xfce4-goodies

# Habilitar repositorio universe para ampliar disponibilidad de paquetes Ubuntu
RUN add-apt-repository -y universe

# Preparar keyrings APT
RUN install -d -m 0755 /etc/apt/keyrings

# Repositorio de Google Chrome
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg && \
    chmod a+r /etc/apt/keyrings/google-chrome.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list

# Repositorio de VSCode
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg && \
    chmod a+r /etc/apt/keyrings/microsoft.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list

# Repositorio de Node.js 24 (NodeSource)
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    chmod a+r /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" > /etc/apt/sources.list.d/nodesource.list

# Repositorio oficial de Docker
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg && \
    chmod a+r /etc/apt/keyrings/docker.gpg && \
    codename="$(lsb_release -cs 2>/dev/null || true)" && \
    [ -n "$codename" ] || codename="noble" && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable" > /etc/apt/sources.list.d/docker.list

# Repositorio de Eclipse Temurin (Java 21 LTS)
RUN curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg && \
    chmod a+r /etc/apt/keyrings/adoptium.gpg && \
    codename="$(lsb_release -cs 2>/dev/null || true)" && \
    [ -n "$codename" ] || codename="noble" && \
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb ${codename} main" > /etc/apt/sources.list.d/adoptium.list

# Instalar Chrome, VSCode, Node.js, Docker y Java 21
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends \
      google-chrome-stable \
      code \
      nodejs \
      docker-ce \
      docker-ce-cli \
      containerd.io \
      docker-buildx-plugin \
      docker-compose-plugin \
      temurin-21-jdk

# Instalar Eclipse IDE desde tarball oficial
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) eclipse_arch="x86_64" ;; \
      arm64) eclipse_arch="aarch64" ;; \
      *) echo "Arquitectura no soportada para Eclipse: $arch" >&2; exit 1 ;; \
    esac; \
    eclipse_url="https://www.eclipse.org/downloads/download.php?file=/technology/epp/downloads/release/${ECLIPSE_RELEASE}/R/eclipse-java-${ECLIPSE_RELEASE}-R-linux-gtk-${eclipse_arch}.tar.gz&r=1"; \
    mkdir -p /opt; \
    curl -fsSL "$eclipse_url" -o /tmp/eclipse.tar.gz; \
    tar -tzf /tmp/eclipse.tar.gz > /dev/null; \
    tar -xzf /tmp/eclipse.tar.gz -C /opt; \
    ln -sf /opt/eclipse/eclipse /usr/local/bin/eclipse; \
    rm -f /tmp/eclipse.tar.gz

# Crear launcher de Eclipse para menú de escritorio (XFCE)
RUN set -eux; \
    cat > /usr/share/applications/eclipse.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Eclipse IDE
Comment=Eclipse Integrated Development Environment
Exec=/opt/eclipse/eclipse
Icon=/opt/eclipse/icon.xpm
Terminal=false
Categories=Development;IDE;Java;
StartupNotify=true
EOF

# CLIs globales de IA
RUN npm install -g @openai/codex @google/gemini-cli @anthropic-ai/claude-code @github/copilot opencode-ai

# Permitir uso de Docker al usuario no root, instalar nvm y preparar SSH para GitHub
RUN groupadd -f docker && \
    usermod -aG docker "$USER" && \
    mkdir -p "/home/$USER/.nvm" && \
    chown -R "$USER:$USER" "/home/$USER/.nvm" && \
    curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" -o /tmp/install-nvm.sh && \
    su - "$USER" -c "bash /tmp/install-nvm.sh" && \
    rm -f /tmp/install-nvm.sh && \
    grep -qxF 'export NVM_DIR="$HOME/.nvm"' "/home/$USER/.bashrc" || echo 'export NVM_DIR="$HOME/.nvm"' >> "/home/$USER/.bashrc" && \
    grep -qxF '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' "/home/$USER/.bashrc" || echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "/home/$USER/.bashrc" && \
    grep -qxF 'export NVM_DIR="$HOME/.nvm"' "/home/$USER/.zshrc" || echo 'export NVM_DIR="$HOME/.nvm"' >> "/home/$USER/.zshrc" && \
    grep -qxF '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' "/home/$USER/.zshrc" || echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> "/home/$USER/.zshrc" && \
    mkdir -p "/home/$USER/.ssh" && \
    chown -R "$USER:$USER" "/home/$USER/.ssh" && \
    chmod 700 "/home/$USER/.ssh" && \
    touch "/home/$USER/.ssh/config" "/home/$USER/.ssh/known_hosts" && \
    chmod 600 "/home/$USER/.ssh/config" "/home/$USER/.ssh/known_hosts" && \
    grep -q '^Host github.com$' "/home/$USER/.ssh/config" || printf '%s\n' 'Host github.com' '  HostName github.com' '  User git' '  IdentityFile ~/.ssh/id_ed25519' '  IdentitiesOnly yes' >> "/home/$USER/.ssh/config" && \
    ssh-keyscan -H github.com >> "/home/$USER/.ssh/known_hosts"

# Limpieza de caches para reducir la imagen final
RUN rm /run/reboot-required* || true && \
    rm -rf /var/lib/apt/lists/*

# Setting the required environment variables
RUN echo 'LANG=en_US.UTF-8' >> /etc/default/locale; \
    echo 'export GNOME_SHELL_SESSION_MODE=ubuntu' > /home/$USER/.xsessionrc; \
    echo 'export XDG_CURRENT_DESKTOP=xfce' >> /home/$USER/.xsessionrc; \
    echo 'export XDG_SESSION_TYPE=x11' >> /home/$USER/.xsessionrc; \
    usermod -s /usr/bin/zsh $USER

USER coder
