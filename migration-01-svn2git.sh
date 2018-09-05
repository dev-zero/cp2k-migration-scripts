#!/bin/bash -l

set -o errexit
set -o nounset
set -o pipefail

#SVN_REPO_URI="http://svn.code.sf.net/p/cp2k/code"
SVN_REPO_URI="https://svn.cp2k.org/cp2k/"

SVN_CLONE_EXTRA_ARGS="${SVN_CLONE_EXTRA_ARGS:-}"

remove_backup_refs() {
    if ! git for-each-ref --format='%(refname)' | grep -qP '^refs/before-[^/]+/' ; then
        echo "No backup refs from filter-branch operations to clean"
        return
    fi

    echo "Removing backup refs from filter-branch operations..."
    git for-each-ref --format='%(refname)' | grep -P '^refs/before-[^/]+/' | while read ref; do
        echo "... ${ref}"
        git update-ref -d "${ref}"
    done
}

drop_empty_commits() {
    # find and list empty commits
    for sha in $(git rev-list --min-parents=1 --max-parents=1 --all) ; do
       if [ $(git rev-parse ${sha}^{tree}) = $(git rev-parse ${sha}^1^{tree}) ] ; then
           echo "Empty commit '$(git log --pretty=oneline --no-walk ${sha})' will be pruned"
       fi
    done

    echo "Dropping empty commits..."
    # --original refs/before-drop_empty_commits:
    #   save the previous state of the tree in refs/before-drop_empty_commits
    git filter-branch \
        --commit-filter 'git_commit_non_empty_tree "$@"' \
        --original refs/before-drop_empty_commits \
        -- --all
}

# Create a Git repository as a clone of the Subversion repo
# --trunk/--branches/--tags:
#   Since the trunk contains multiple directories of which only the cp2k/ directory
#   was branched/tagged, I consider it a non-standard layout and instead of filtering
#   the data directory afterwards, I instruct git-svn to not consider it at all.
# --no-metadata:
#   Do not include the SVN rev-info and link to SVN repo in the generated Git commit messages
# --authors-file=authors.txt:
#   Transform the SVN usernames to proper names + email-adresses (where available)

echo "Cloning CP2K from Subversion..."
git svn clone \
    --trunk=trunk/cp2k \
    --branches=branches/*/cp2k \
    --tags=tags/*/cp2k \
    --no-metadata \
    --authors-file=authors.txt \
     ${SVN_CLONE_EXTRA_ARGS} "${SVN_REPO_URI}" cp2k-repo

pushd cp2k-repo >/dev/null

drop_empty_commits
remove_backup_refs

echo "Retroactively rename .svnignore to .gitignore"

# do an in-history rename of the .svnignore to .gitignore to ensure that
# all branches and commits will have proper .gitignore. Do that by using the index
# instead of touching the actual files to speed things up.
# --original refs/before-svnignore_rename:
#   save the previous state of the tree in refs/before-svnignore_rename
git filter-branch \
    --index-filter '
        git ls-files -s | \
        sed "s-\(\t*\).svnignore-\1.gitignore-" | \
        GIT_INDEX_FILE=$GIT_INDEX_FILE.new git update-index --index-info && \
        mv "$GIT_INDEX_FILE.new" "$GIT_INDEX_FILE"
        ' \
    --tag-name-filter cat \
    --original refs/before-svnignore_rename \
    -- --all

remove_backup_refs

# since this was an empty Git repo, the reference refs/heads/master points is the same as refs/remotes/svn/trunk

echo "Creating support branches based on old SVN branches..."

# we do not have any meaningful tags we might want to preserve unfortunately :(
# but we have some branches, which have to be converted to proper Git support branches
git for-each-ref --format='%(refname) %(objectname)' refs/remotes/origin/* | while read name ref; do
    if [[ $name =~ refs/remotes/origin/cp2k-([^\-]*)-branch ]] ; then
        version="${BASH_REMATCH[1]}"
        git branch support/"v${version//_/.}" "${ref}"
    fi
done

echo "Dropping git svn clone branches..."
git for-each-ref --format='%(refname)' | grep -P '^refs/remotes/' | while read ref; do
    git update-ref -d "${ref}"
done

echo "Garbage collecting the leftovers..."
git gc

popd >/dev/null

echo "Clone the repo again, but only for the data..."
git svn clone \
    --trunk=trunk \
    --include-paths="^trunk/(basis_sets|potentials)/" \
    --no-metadata \
    --authors-file=authors.txt \
     ${SVN_CLONE_EXTRA_ARGS} "${SVN_REPO_URI}" cp2k-data-repo

pushd cp2k-data-repo >/dev/null

# and again drop the empty commits
drop_empty_commits
remove_backup_refs

echo "Garbage collecting the leftovers..."
git gc

popd >/dev/null
