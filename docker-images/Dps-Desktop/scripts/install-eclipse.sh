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
mkdir -p /opt
downloaded=0
for pkg in eclipse-java eclipse-jee eclipse-committers eclipse-SDK; do
  candidate="${pkg}-${ECLIPSE_RELEASE}-R-linux-gtk-${eclipse_arch}.tar.gz"
  for host in https://download.eclipse.org https://archive.eclipse.org; do
    candidate_url="${host}${base_path}/${candidate}"
    echo "Probando Eclipse tarball: ${candidate_url}"
    if curl -fL "$candidate_url" -o /tmp/eclipse.tar.gz; then
      downloaded=1
      break
    fi
  done
  if [[ "$downloaded" -eq 1 ]]; then
    break
  fi
done

if [[ "$downloaded" -ne 1 ]]; then
  echo "No se pudo descargar Eclipse para release=${ECLIPSE_RELEASE} arch=${eclipse_arch}" >&2
  exit 1
fi

tar -tzf /tmp/eclipse.tar.gz >/dev/null
tar -xzf /tmp/eclipse.tar.gz -C /opt
test -x /opt/eclipse/eclipse
ln -sf /opt/eclipse/eclipse /usr/local/bin/eclipse
rm -f /tmp/eclipse.tar.gz

# Instalar Spring Tools 4 (Spring Boot Tool Suite) como add-on de Eclipse.
STS_UPDATE_SITE="${STS_UPDATE_SITE:-https://cdn.spring.io/spring-tools/release/update/latest/}"
STS_IUS_WITH_GROUP=(
  org.springframework.boot.ide.main.feature.feature.group
  org.springframework.tooling.boot.ls.feature.feature.group
  org.springframework.ide.eclipse.boot.dash.feature.feature.group
  org.springframework.ide.eclipse.xml.namespaces.feature.feature.group
)
STS_IUS_RAW=(
  org.springframework.boot.ide.main.feature
  org.springframework.tooling.boot.ls.feature
  org.springframework.ide.eclipse.boot.dash.feature
  org.springframework.ide.eclipse.xml.namespaces.feature
)

join_by_comma() {
  local IFS=","
  echo "$*"
}

echo "Instalando Spring Tools 4 desde: ${STS_UPDATE_SITE}"
if ! /opt/eclipse/eclipse \
  -nosplash \
  -application org.eclipse.equinox.p2.director \
  -repository "${STS_UPDATE_SITE}" \
  -installIUs "$(join_by_comma "${STS_IUS_WITH_GROUP[@]}")"; then
  echo "Fallo con *.feature.group; reintentando con IDs raw..."
  /opt/eclipse/eclipse \
    -nosplash \
    -application org.eclipse.equinox.p2.director \
    -repository "${STS_UPDATE_SITE}" \
    -installIUs "$(join_by_comma "${STS_IUS_RAW[@]}")"
fi
