#!/bin/bash -l

set -o errexit
set -o nounset
set -o pipefail

add_tag() {
    version=$1
    commit="${2:-master}~${3:-0}"

    cdate=$(git show -s --format=%ci "${commit}")

    echo "Adding tag v${version} pointing to ${commit}..."
    GIT_COMMITTER_DATE="${cdate}" GIT_COMMITTER_NAME="Matthias Krack" GIT_COMMITTER_EMAIL="matthias.krack@psi.ch" \
    git tag \
        -a -f \
        -m "CP2K release ${version}" \
        "v${version}" "${commit}"
}

cd cp2k-repo

# reconstructed tags from release dates of tarballs at
#   https://sourceforge.net/projects/cp2k/files/
# due to missing Subversion tags
add_tag "6.1.0" "support/v6.1"
add_tag "5.1.0" "support/v5.1"
add_tag "4.1.0" "support/v4.1" "3"
add_tag "3.0.0" "support/v3.0" "5"
add_tag "2.6.2" "support/v2.6" "4"
add_tag "2.6.1" "support/v2.6" "17"
add_tag "2.6.0" "support/v2.6" "23"
add_tag "2.5.1" "support/v2.5" "2"
add_tag "2.5.0" "support/v2.5" "7"
add_tag "2.4.0" "support/v2.4" "1"
add_tag "2.3.0" "support/v2.3" "1"
