FROM codercom/enterprise-minimal:latest

USER root
ARG USER=coder
ARG NVM_VERSION=v0.40.3
ARG ECLIPSE_RELEASE=2025-12
ARG HOST_RENDER_GID=993
ARG ANDROID_SDK_VERSION=14742923

# Paquetes base del sistema y escritorio XFCE
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
      ca-certificates \
      curl \
      jq \
      gnupg \
      git \
      openssh-client \
      software-properties-common \
      mesa-utils \
      mesa-utils-extra \
      libglx-mesa0 \
      libgl1-mesa-dri \
      libgl1 \
      libegl1 \
      libegl-mesa0 \
      libgbm1 \
      libdrm2 \
      mesa-vulkan-drivers \
      libvulkan1 \
      vainfo \
      vulkan-tools \
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

# Repositorio oficial de VirtualGL (packagecloud)
RUN curl -fsSL https://packagecloud.io/dcommander/virtualgl/gpgkey | gpg --dearmor -o /etc/apt/keyrings/virtualgl.gpg && \
    chmod a+r /etc/apt/keyrings/virtualgl.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/virtualgl.gpg] https://packagecloud.io/dcommander/virtualgl/any any main" > /etc/apt/sources.list.d/virtualgl.list

# Repositorio oficial de DBeaver CE
RUN curl -fsSL https://dbeaver.io/debs/dbeaver.gpg.key | gpg --dearmor -o /etc/apt/keyrings/dbeaver.gpg && \
    chmod a+r /etc/apt/keyrings/dbeaver.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/dbeaver.gpg] https://dbeaver.io/debs/dbeaver-ce /" > /etc/apt/sources.list.d/dbeaver.list

# Instalar Chrome, VSCode, Node.js, Docker y Java 21
RUN dpkg --add-architecture i386 && \
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y --no-install-recommends \
      apt-transport-https \
      autojump \
      build-essential \
      cmake \
      extra-cmake-modules \
      hdparm \
      htop \
      jq \
      make \
      maven \
      nano \
      ncdu \
      net-tools \
      nmap \
      python-is-python3 \
      python3 \
      python3-pip \
      rclone \
      restic \
      sshfs \
      tree \
      unzip \
      wget \
      wireguard-tools \
      zip \
      neovim \
      libc6:i386 \
      libstdc++6:i386 \
      libgcc-s1:i386 \
      zlib1g:i386 \
      google-chrome-stable \
      code \
      nodejs \
      docker-ce \
      docker-ce-cli \
      containerd.io \
      docker-buildx-plugin \
      docker-compose-plugin \
      temurin-21-jdk \
      virtualgl \
      dbeaver-ce

# Toolchain Android (SDK command-line tools + paquetes de compilacion)
ENV ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    ANDROID_USER_HOME=/home/coder/.android \
    JAVA_HOME=/usr/lib/jvm/temurin-21-jdk-amd64 \
    PATH=$PATH:/opt/android-sdk/platform-tools:/opt/android-sdk/cmdline-tools/latest/bin:/usr/lib/jvm/temurin-21-jdk-amd64/bin

RUN mkdir -p /opt/android-sdk/cmdline-tools && \
    curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip" -o /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d /opt/android-sdk/cmdline-tools && \
    mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest && \
    rm -f /tmp/cmdline-tools.zip && \
    yes | /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --licenses >/dev/null || true && \
    /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --update && \
    /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager \
      "platform-tools" \
      "build-tools;35.0.0" \
      "build-tools;34.0.0" \
      "platforms;android-35" \
      "platforms;android-34" \
      "cmdline-tools;latest" \
      "ndk;27.0.12077973" \
      "cmake;3.22.1" && \
    install -d -o "$USER" -g "$USER" /home/"$USER"/.android && \
    touch /home/"$USER"/.android/repositories.cfg && \
    chown -R "$USER":"$USER" /opt/android-sdk /home/"$USER"/.android

# Compatibilidad con rutas esperadas por Kasm/VirtualGL
RUN mkdir -p /opt/VirtualGL/bin && \
    if command -v vglrun >/dev/null 2>&1; then ln -sfn "$(command -v vglrun)" /opt/VirtualGL/bin/vglrun || true; fi

# Compatibilidad de comandos: exponer "neofetch" usando fastfetch en Ubuntu 24
RUN if command -v fastfetch >/dev/null 2>&1 && ! command -v neofetch >/dev/null 2>&1; then \
      ln -sfn "$(command -v fastfetch)" /usr/local/bin/neofetch; \
    fi

# Instalar Eclipse IDE desde tarball oficial (script dedicado)
COPY scripts/install-eclipse.sh /usr/local/bin/install-eclipse.sh
RUN chmod +x /usr/local/bin/install-eclipse.sh && \
    /usr/local/bin/install-eclipse.sh "${ECLIPSE_RELEASE}"

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
RUN npm install -g @openai/codex @google/gemini-cli @anthropic-ai/claude-code @github/copilot opencode-ai eas-cli @angular/cli

# Permitir uso de Docker al usuario no root, instalar nvm y preparar SSH para GitHub
RUN groupadd -f docker && \
    groupadd -f video && \
    groupadd -f render && \
    if ! getent group "${HOST_RENDER_GID}" >/dev/null; then groupadd -g "${HOST_RENDER_GID}" "hostgpu_${HOST_RENDER_GID}"; fi && \
    usermod -aG docker "$USER" && \
    usermod -aG video,render "$USER" && \
    usermod -aG "${HOST_RENDER_GID}" "$USER" || true && \
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

# USER coder
