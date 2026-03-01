#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 <ECLIPSE_RELEASE>" >&2
  exit 1
fi

ECLIPSE_RELEASE="$1"

arch="$(dpkg --print-architecture)"
case "$arch" in
  amd64) eclipse_arch="x86_64" ;;
  arm64) eclipse_arch="aarch64" ;;
  *)
    echo "Arquitectura no soportada para Eclipse: $arch" >&2
    exit 1
    ;;
esac

base_path="/technology/epp/downloads/release/${ECLIPSE_RELEASE}/R"
eclipse_url=""
for pkg in eclipse-java eclipse-jee eclipse-committers eclipse-SDK; do
  candidate="${pkg}-${ECLIPSE_RELEASE}-R-linux-gtk-${eclipse_arch}.tar.gz"
  candidate_url="https://archive.eclipse.org${base_path}/${candidate}"
  if curl -fsIL "$candidate_url" >/dev/null 2>&1; then
    eclipse_url="$candidate_url"
    break
  fi
done

if [[ -z "$eclipse_url" ]]; then
  echo "No se encontro tarball de Eclipse para release=${ECLIPSE_RELEASE} arch=${eclipse_arch}" >&2
  exit 1
fi

mkdir -p /opt
curl -fL "$eclipse_url" -o /tmp/eclipse.tar.gz
tar -tzf /tmp/eclipse.tar.gz >/dev/null
tar -xzf /tmp/eclipse.tar.gz -C /opt
test -x /opt/eclipse/eclipse
ln -sf /opt/eclipse/eclipse /usr/local/bin/eclipse
rm -f /tmp/eclipse.tar.gz
