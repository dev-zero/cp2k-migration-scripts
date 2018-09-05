# Migration scripts for moving CP2K's Subversion to Git

Run the scripts in their natural order:

```bash
./migration-01-svn2git.sh
./migration-02-tags.sh
./migration-03-updates.sh
./migration-04-push.sh
```

Which will leave you with new directories containing fresh Git repositories:

```bash
./cp2k-repo
./cp2k-data-repo
```

For testing you can also limit the number of revisions to use
when creating the clones:

```bash
SVN_CLONE_EXTRA_ARGS="-r1:100" ./migration-01-svn2git.sh
```
