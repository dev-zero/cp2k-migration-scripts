#!/bin/bash -l

set -o errexit
set -o nounset
set -o pipefail

GITIGNORE_IO_CONF="python,fortran,c,c++,cuda,emacs,vim"

update_gitignore() {
    echo "Updating .gitignore..."

    cat > .gitignore << EOF
# base directory structure
exe/
lib/
obj/
bin/
regtesting/
install/

# ignore local arch files not meant to be shared
arch/local*

# ensure people are not accidentally committing an old .svnignore when copying their stuff
.svnignore

EOF

    git commit -m "gitignore: ignore .svnignore and local arch files" .gitignore

    curl -L -s "https://www.gitignore.io/api/${GITIGNORE_IO_CONF}" >> .gitignore
    git commit -m "gitignore: add declarations from gitignore.io" .gitignore
}

dbcsr_submodule() {
    echo "Moving DBCSR to exts/dbcsr as a Git submodule"

    mkdir -p exts
    git submodule add https://github.com/cp2k/dbcsr.git exts/dbcsr
    git rm -r src/dbcsr

    for f in makefiles/Makefile exts/{Makefile.inc,README.md} ; do
        wget "https://raw.githubusercontent.com/alazzaro/cp2k/master/cp2k/${f}" -O "${f}"
        git add "${f}"
    done

    git commit --author='Alfio Lazzaro <alfio.lazzaro@chem.uzh.ch>' -m "DBCSR: include as git submodule"
}

pushd cp2k-repo >/dev/null

update_gitignore
# dbcsr_submodule

# apply patches on top
git am ../patches

popd >/dev/null
