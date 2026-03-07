#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Uso: $0 <ECLIPSE_RELEASE>" >&2
  exit 1
fi

ECLIPSE_RELEASE="$1"
SPRING_TOOLS_REPO_URL="${SPRING_TOOLS_REPO_URL:-https://cdn.spring.io/spring-tools/release/TOOLS/sts4/update/latest/}"
ECLIPSE_RELEASE_REPO_URL="${ECLIPSE_RELEASE_REPO_URL:-https://download.eclipse.org/releases/${ECLIPSE_RELEASE}}"
ECLIPSE_ORBIT_REPO_URL="${ECLIPSE_ORBIT_REPO_URL:-https://download.eclipse.org/tools/orbit/simrel/orbit-aggregation/release/latest/}"
EXTRA_P2_REPO_URLS="${EXTRA_P2_REPO_URLS:-}"
SPRING_TOOLS_IUS="${SPRING_TOOLS_IUS:-org.springframework.boot.ide.main.feature.feature.group,org.springframework.tooling.boot.ls.feature.feature.group,org.springframework.ide.eclipse.boot.dash.feature.feature.group,org.springframework.ide.eclipse.xml.namespaces.feature.feature.group}"

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
if [[ -w /opt || (! -e /opt && -w /) ]]; then
  install_dir="/opt/eclipse"
else
  install_dir="${HOME}/.local/opt/eclipse"
fi
mkdir -p "$(dirname "$install_dir")"
candidate="eclipse-jee-${ECLIPSE_RELEASE}-R-linux-gtk-${eclipse_arch}.tar.gz"
candidate_url="https://www.eclipse.org/downloads/download.php?file=${base_path}/${candidate}&r=1"
echo "Descargando Eclipse tarball: ${candidate_url}"
if ! curl -fL "$candidate_url" -o /tmp/eclipse.tar.gz; then
  echo "No se pudo descargar Eclipse JEE para release=${ECLIPSE_RELEASE} arch=${eclipse_arch}" >&2
  exit 1
fi

tar -tzf /tmp/eclipse.tar.gz >/dev/null
tmp_extract_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_extract_dir"
}
trap cleanup EXIT

tar -xzf /tmp/eclipse.tar.gz -C "$tmp_extract_dir"
test -d "${tmp_extract_dir}/eclipse"

rm -rf "$install_dir"
mv "${tmp_extract_dir}/eclipse" "$install_dir"
test -x "${install_dir}/eclipse"

if [[ -w /usr/local/bin ]]; then
  launcher_path="/usr/local/bin/eclipse"
else
  mkdir -p "${HOME}/.local/bin"
  launcher_path="${HOME}/.local/bin/eclipse"
fi
ln -sf "${install_dir}/eclipse" "$launcher_path"

echo "Instalando Spring Tools desde ${SPRING_TOOLS_REPO_URL}"
all_repos="${SPRING_TOOLS_REPO_URL},${ECLIPSE_RELEASE_REPO_URL},${ECLIPSE_ORBIT_REPO_URL}"
if [[ -n "${EXTRA_P2_REPO_URLS}" ]]; then
  all_repos="${all_repos},${EXTRA_P2_REPO_URLS}"
fi
"${install_dir}/eclipse" \
  -nosplash \
  -application org.eclipse.equinox.p2.director \
  -followReferences \
  -repository "${all_repos}" \
  -installIU "${SPRING_TOOLS_IUS}" \
  -destination "${install_dir}"

rm -f /tmp/eclipse.tar.gz
