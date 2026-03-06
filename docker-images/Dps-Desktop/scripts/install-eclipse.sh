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
STS_UPDATE_SITES=(
  "${STS_UPDATE_SITE:-https://cdn.spring.io/spring-tools/release/update/latest/}"
  "https://download.springsource.com/release/TOOLS/sts4/update/latest/"
)
STS_PREFERRED_IUS=(
  org.springframework.boot.ide.main.feature.feature.group
  org.springframework.tooling.boot.ls.feature.feature.group
  org.springframework.ide.eclipse.boot.dash.feature.feature.group
  org.springframework.ide.eclipse.xml.namespaces.feature.feature.group
  org.springsource.ide.eclipse.boot.feature.feature.group
  org.springsource.ide.eclipse.boot.dash.feature.feature.group
  org.springsource.ide.eclipse.commons.ui.feature.feature.group
  org.springsource.ide.eclipse.commons.core.feature.feature.group
)

join_by_comma() {
  local IFS=","
  echo "$*"
}

echo "Instalando Spring Tools 4 en Eclipse..."
sts_installed_count=0
for repo in "${STS_UPDATE_SITES[@]}"; do
  echo "Probando instalación STS desde: ${repo}"
  for iu in "${STS_PREFERRED_IUS[@]}"; do
    echo "  - Intentando IU: ${iu}"
    set +e
    /opt/eclipse/eclipse \
      -consolelog \
      -nosplash \
      -application org.eclipse.equinox.p2.director \
      -repository "${repo}" \
      -destination /opt/eclipse \
      -bundlepool /opt/eclipse \
      -profile SDKProfile \
      -profileProperties org.eclipse.update.install.features=true \
      -installIUs "${iu}"
    iu_rc=$?
    set -e
    if [[ "${iu_rc}" -eq 0 ]]; then
      echo "    OK: ${iu}"
      sts_installed_count=$((sts_installed_count + 1))
    else
      echo "    No disponible o incompatible: ${iu}"
    fi
  done
done

if [[ "${sts_installed_count}" -eq 0 ]]; then
  echo "No se pudo instalar Spring Tools 4 desde ninguno de los repositorios configurados." >&2
  exit 13
fi

echo "Spring Tools instalado. IUs aplicadas correctamente: ${sts_installed_count}"
