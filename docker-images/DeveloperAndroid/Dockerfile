# Developer Android image with KDE desktop and Android SDK
FROM ghcr.io/makespacemadrid/coder-mks-desktop-kde:latest

LABEL org.opencontainers.image.title="coder-mks-developer-android" \
      org.opencontainers.image.description="Coder Desktop KDE con toolchain Android (SDK/CLI), Node 22 y VS Code" \
      org.opencontainers.image.source="https://github.com/makespacemadrid/coder-workspaces" \
      org.opencontainers.image.url="ghcr.io/makespacemadrid/coder-mks-developer-android:latest" \
      com.centurylinklabs.watchtower.enable="true" \
      com.centurylinklabs.watchtower.scope="coder-workspaces" \
      com.centurylinklabs.watchtower.lifecycle="rolling"

USER root

ENV DEBIAN_FRONTEND=noninteractive

# Paquetes base para desarrollo Android + utilidades
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        pkg-config \
        openjdk-17-jdk \
        python3 python3-venv python3-pip pipx \
        unzip zip \
        git git-lfs \
        gnupg \
        jq \
        curl wget \
        ca-certificates \
        libc6:i386 libstdc++6:i386 libgcc-s1:i386 libz1:i386 libncurses6:i386 \
        libpulse0 \
        adb \
        dnsutils net-tools iputils-ping \
        ripgrep fzf \
        direnv \
        httpie \
        sqlite3 \
        yq \
        xmlstarlet \
        scrcpy \
        acl \
        libfuse2 \
        bash-completion \
        nano \
        lsof \
        htop \
        tmux \
        byobu \
        pulseaudio pulseaudio-utils alsa-utils \
        libglu1-mesa \
        qemu-kvm \
        # dependencias runtime (Perl/VNC) que queremos preinstalar
        libdatetime-perl \
        liblist-moreutils-perl \
        libyaml-tiny-perl \
        libhash-merge-simple-perl \
        libxfont2 \
        libfontenc1 \
        ssl-cert \
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

# Añadir coder al grupo KVM para aceleración del emulador
RUN usermod -aG kvm coder

# KasmVNC busca startkde; en Plasma moderno es startplasma-x11
RUN if [ -x /usr/bin/startplasma-x11 ] && [ ! -x /usr/bin/startkde ]; then \
      ln -sf /usr/bin/startplasma-x11 /usr/bin/startkde; \
    fi

# Disable KDE screen locker/screensaver
RUN printf '[Daemon]\nTimeout=0\nLockOnResume=false\nLockOnSuspend=false\nAutolock=false\n' > /etc/xdg/kscreenlockerrc

# Node.js 22 LTS + package managers (para React Native/JS tooling)
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

# Visual Studio Code
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg && \
    chmod a+r /etc/apt/keyrings/microsoft.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
      | tee /etc/apt/sources.list.d/vscode.list > /dev/null && \
    apt-get update && \
    apt-get install -y --no-install-recommends code && \
    rm -rf /var/lib/apt/lists/*

# Android SDK commandline tools + componentes principales
ENV ANDROID_HOME=/opt/android-sdk \
    ANDROID_SDK_ROOT=/opt/android-sdk \
    ANDROID_USER_HOME=/home/coder/.android \
    PATH=$PATH:/opt/android-sdk/platform-tools:/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/emulator:/opt/gradle/gradle-9.3.1/bin

ARG ANDROID_SDK_VERSION=14742923
RUN mkdir -p /opt/android-sdk/cmdline-tools && \
    curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip" -o /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d /opt/android-sdk/cmdline-tools && \
    mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip && \
    yes | /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --licenses >/dev/null || true && \
    /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --update && \
    /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager \
      "platform-tools" \
      "emulator" && \
    chown -R coder:coder /opt/android-sdk && \
    install -d -o coder -g coder /home/coder/.android

# Android Studio
ARG ANDROID_STUDIO_VERSION=2025.2.3.9
RUN curl -fsSL "https://redirector.gvt1.com/edgedl/android/studio/ide-zips/${ANDROID_STUDIO_VERSION}/android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz" -o /tmp/android-studio.tar.gz && \
    tar -xzf /tmp/android-studio.tar.gz -C /opt && \
    rm /tmp/android-studio.tar.gz && \
    chown -R coder:coder /opt/android-studio && \
    ln -sf /opt/android-studio/bin/studio /usr/local/bin/android-studio && \
    ln -sf /opt/android-studio/bin/studio /usr/local/bin/studio

# JetBrains Toolbox (para JetBrains Gateway/IDE remotos)
ARG JETBRAINS_TOOLBOX_VERSION=3.1.2.64642
RUN curl -fsSL "https://download.jetbrains.com/toolbox/jetbrains-toolbox-${JETBRAINS_TOOLBOX_VERSION}.tar.gz" -o /tmp/jetbrains-toolbox.tar.gz && \
    mkdir -p /opt/jetbrains-toolbox && \
    tar -xzf /tmp/jetbrains-toolbox.tar.gz -C /opt/jetbrains-toolbox --strip-components=1 && \
    rm /tmp/jetbrains-toolbox.tar.gz && \
    chown -R coder:coder /opt/jetbrains-toolbox && \
    ln -sf /opt/jetbrains-toolbox/jetbrains-toolbox /usr/local/bin/jetbrains-toolbox

# Accesos directos de escritorio (Android Studio + apps principales)
RUN install -d /etc/skel/Desktop && \
    cat <<'EOF' >/usr/share/applications/android-studio.desktop
[Desktop Entry]
Name=Android Studio
Comment=Android IDE
Exec=/opt/android-studio/bin/studio
Icon=/opt/android-studio/bin/studio.png
Terminal=false
Type=Application
Categories=Development;IDE;
EOF
RUN chmod +x /usr/share/applications/android-studio.desktop && \
    for app in android-studio.desktop code.desktop firefox.desktop google-chrome.desktop; do \
      if [ -f "/usr/share/applications/${app}" ]; then \
        ln -sf "/usr/share/applications/${app}" "/etc/skel/Desktop/${app}"; \
      fi; \
    done

# Gradle
RUN curl -fsSL "https://services.gradle.org/distributions/gradle-9.3.1-bin.zip" -o /tmp/gradle.zip && \
    unzip -q /tmp/gradle.zip -d /opt/gradle && \
    rm /tmp/gradle.zip

# Electron sandbox workaround for VS Code
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
TARGET_BIN=/usr/share/code/bin/code EXTRA_FLAGS="" wrap /usr/bin/code /usr/share/code/bin/code
EOSH
