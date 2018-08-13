#!/bin/bash -l

set -o errexit
set -o nounset
set -o pipefail


git --git-dir=cp2k-repo/.git remote add origin git@github.com:dev-zero/migrated-cp2k.git
git --git-dir=cp2k-repo/.git push --all --follow-tags --set-upstream origin

git --git-dir=cp2k-data-repo/.git remote add origin git@github.com:dev-zero/migrated-cp2k-data.git
git --git-dir=cp2k-data-repo/.git push --all --follow-tags --set-upstream origin
