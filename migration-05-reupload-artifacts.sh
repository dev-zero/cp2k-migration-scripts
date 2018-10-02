#!/bin/bash -l

set -o errexit
set -o nounset
set -o pipefail

get_link() {
    local _ver=$1
    echo "http://downloads.sourceforge.net/project/cp2k/cp2k-${_ver}.tar.bz2"
}

GH_USER=cp2k
GH_PROJ=cp2k

command -v ghr >/dev/null 2>&1 || { echo >&2 "Need (configured) ghr from https://github.com/tcnksm/ghr to upload artifacts"; exit 1; }

mkdir -p distfiles
cd distfiles

echo "Fetch all releases from sourceforge..."
for ver in 2.3 2.4.0 2.5.0 2.5.1 2.6.0 2.6.1 2.6.2 3.0 4.1 5.1 6.1 ; do
    wget "$(get_link ${ver})"
done

echo "Create releases from existing tags for vX.Y releases..."
for ver in 2.3 3.0 4.1 5.1 6.1 ; do
    ghr -username "${GH_USER}" -repository "${GH_PROJ}" -name "CP2K v${ver}" "v${ver}.0" "cp2k-${ver}.tar.bz2"
done

echo "Create releases from existing tags for vX.Y.Z releases..."
for ver in 2.4.0 2.5.0 2.5.1 2.6.0 2.6.1 2.6.2 ; do
    ghr -username "${GH_USER}" -repository "${GH_PROJ}" -name "CP2K v${ver}" "v${ver}" "cp2k-${ver}.tar.bz2"
done
