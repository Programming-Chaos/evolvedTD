# Getting Started

Welcome to [EvolvedTD][wiki], an Evolutionary Tower Defense game!

The following sections walk you through cloning, branching, pulling,
commiting, pushing, and reviewing code changes using
[Git](http://git-scm.com/).

## Cloning

First, we get download a copy of the repository to our machine (note
the use of [SSH][] for authentication):

	git clone git@github.com:tsoule88/evolvedTD.git
	cd evolveTD

Now we run `git status`. Notice that it will say we are "on branch
`master`", this branch is the default. Its first commit is the first
commit in the repo. Commits are discrete sets of changes to the files
tracked in the repo, and what Git does is record these in a tree,
effectively keeping track of the entire history of changes to a
codebase.

## Branching

Since the `master` branch is special, we want to keep it stable, which
means that it should only be changed after a code review. So in order
to record and share changes that we wish to eventually merge into
`master`, we commit them to a different branch and share that. Once
the branch's changes have been reviewed by our peers (on GitHub, in a
[Pull Request][pr]), the entire branch is merged back into `master`.

Before changing any code, we need to make a branch for what we are
going to work on:

    git checkout -b getting-started

This command did two things: it created the branch `getting-started`
*and* it checked the branch out, meaning that our `HEAD` reference (a
pointer or marker to the checked out commit) now points to the tip of
the new branch. When we commit, it is added to the commit tree as a
child of the commit that our `HEAD` reference marks. With each commit
we add to this branch, the `getting-started` branch reference (and
`HEAD`) is moved to the new commit, but `master` (and other branches)
are not, so the history has diverged. This is a good thing, because
the differences can be compared, discussed, reviewed, and merged back
in easily via [pull request][pr].

The two things the above command did are equivalent to this:

    git branch getting-started
    git checkout getting-started

> Git has lots of documentation; use `git help subcommand` to read it,
> e.g. `git help checkout`.

Checking out a reference, i.e. a branch name or a commit hash, will
update the local files such that they match their state at the given
reference. If `git status` indicates we have modified files (use `git
diff` to see the differences), then we'll either want to commit them,
or if we're not quite ready to do so, we can [stash][] them away for
later using `git stash`.

> Use `git status -sb` to quickly see the current branch and changes

Whenever we start a new branch, unless another line of development
makes more sense, we should branch" it off `master`, which just means
checking it out first:

    git checkout master
    git checkout -b new-topic

## Pulling

Let's say a pull request was recently merged into `master` and we want
to obtain those changes. It's as easy as checking it out and pulling:

    git checkout master
    git pull

We should then integrate the latest changes into our topic branch,
which requires [merging][]. For most cases the merge will be trivially
resolved by Git; manual intervention is only necessary if the same
lines of code have been changed on each side of the merge.

Merges always merge *into* the current branch, from the one specified
on the command line. Since we want the changes in `master` to be
merged into `new-topic`, we'll start there:

    git checkout new-topic
    git merge master

Git will create a "merge" commit which brings the two branches of the
tree together by having each as a parent, for two parent commits. Git
will allow us to edit the commit message before saving it, but we
should keep the summary.

## Commiting

Go ahead and make some changes to any tracked file and save it. Git
status should now list the file as modified under "Changes not staged
for commit". This means Git is aware we've changed the file, but no
more. If we want to record these changes, we need to *stage* them to
the index (i.e. staging area), which is Git-speak for marking which
changes we want in the next commit (it doesn't have to include every
change).

> See the [online documentation][stage] for more!

Unstaged changes can be seen using `git diff`, and staged changes can
be seen using `git diff --cached` (`--staged` is an alias). The `diff`
command also accepts arbitrary ranges of references as well as paths
to particular files, but by default it shows the changes between our
working tree and the staging area, hence why staged changes are
excluded without the flag.

Perhaps we fixed a typo in this guide and so have modified the file
`README.md`, and we want to add the all the changes in the file to the
staging area:

    git add README.md

Git status should now list the modifications under "Changes to be
committed".

> Use `git add --patch` to interactively stage changes

To finish the commit and thus record the changes to the repository, we
need to [write a commit message][commit]. The first line should be a
one-line summary of the changes in the commit; for longer messages,
leave a blank line, and then add details. Commit messages should be
imperative: "Fix bug", not "Fixed bug" or "Fixes bug", e.g.:

    git commit -m "Fix typo in Getting Started"

Executing `git commit` without a message will open the program defined
in our `$EDITOR` environment variable, where a longer commit message
can be written.

## Pushing

Let's suppose we have spent the day working on a feature with its own
branch `foo`. Since we work with a team, we need to share our work,
even if it's not completely finished, so we can refactor our code
based on input we receive from our peers. First, let's take a look at
our log of changes so we can remember what we've done:

    git log --decorate --graph --oneline

The `--decorate` flag causes references to be emitted in the log, so
we can see where each branch is. The `--graph` flag draws an ASCII
tree; and `--oneline` shows just each commit's summary. The top is
most recent, so we should see `foo` but *not* `master` right before
that commit's summary. Since we are using [GitHub Flow][flow],
`master` and the remote branch that it tracks, `origin/master`, should
*always* be on the same commit if we are not actively merging a
finished pull request. Once we are sure we have not erroneously
committed to `master`, we will push our changes to GitHub:

    git push --set-upstream origin foo

If we have not pushed this branch to GitHub before, we need to specify
it with `--set-upstream origin`. When we cloned Dr. Soule's repo, Git
kept track of where it came from by adding a `remote` named
`origin`. We are setting `origin` as the upstream repo, and adding a
new branch `foo` to `origin`, so that all subsequent executions of
`git push` when we are on our local branch `foo` will automatically
send our changes to GitHub and move the `origin/foo` reference
accordingly.

Our peers can then pull our changes into their local repos by running
`git pull`, and then check those changes out with `git checkout foo`.

## Reviewing

Once we've pushed our changes to GitHub, we want to
[write a perfect][perfect] [pull request][pr]. After navigating to the
[project's page][gh], we want to find our branch `foo` and click the
"Compare & review". This will present with an overview of changes
between our branch and `master`. After writing the pull request, we
then submit it by clicking "Create pull request".

The PR will now be viewable to all our peers, and open for
discussion. We can add to the PR by pushing more commits to `foo`; in
fact, any collaborator can do this, so don't forget to pull their
changes before continuing your work.

Before a PR can be signed-off, it needs to be able to merge cleanly,
which means merging `master` into `foo`, such that when we merge `foo`
into `master`, Git will simply "fast-forward" the `master` branch
reference to the merge commit at the head of `foo`. Since this
commit's parents were `master` and `foo` to begin with, the second
merge won't make another commit as it can just move the reference
forward.

> "Any sufficiently advanced technology is indistinguishable from
> magic." - Arthur C. Clarke

After the PR has been sufficiently reviewed and signed-off by another
team member, we will want to merge it back into `master`. Since we
already took the time to ensure this will happen cleanly, GitHub
offers us a button at the bottom of the PR to automatically perform
the merge from `foo` into `master`, thus completing and closing the
pull request.

### Reverting

If published commits break the game, or for any other reason need to
be "undone", the `git revert` [command][revert] will create *inverse*
commits of the specified range, which are then committed, effectively
undoing the changes in a recorded manner. GitHub also provides a
`revert` button on merged pull requests.

[wiki]: http://course.cs.uidaho.edu/wiki404/index.php/Main_Page
[ssh]: https://help.github.com/articles/generating-ssh-keys/
[pr]: https://help.github.com/articles/using-pull-requests/
[stash]: http://git-scm.com/book/en/v1/Git-Tools-Stashing
[merging]: http://www.git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging
[stage]: http://git-scm.com/book/en/v2/Git-Basics-Recording-Changes-to-the-Repository
[commit]: http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
[flow]: https://guides.github.com/introduction/flow/index.html
[perfect]: https://github.com/blog/1943-how-to-write-the-perfect-pull-request
[gh]: https://github.com/tsoule88/evolvedTD
[revert]: http://git-scm.com/docs/git-revert

# Dependencies

## Processing

- [Download](https://processing.org/download/)
- [Tutorials](https://processing.org/tutorials/)
- [Reference](https://processing.org/reference/)
- [GitHub](https://github.com/processing)
- [Wiki](https://github.com/processing/processing/wiki)

If you wish to use Processing from the command line (or with
`processing-mode` in Emacs etc.), install the binaries through the
menu "Tools" -> "Install 'processing-java'".

## Box2D for Processing

- [Source](https://github.com/shiffman/Box2D-for-Processing)
- [Releases](https://github.com/shiffman/Box2D-for-Processing/releases)
- [Distribution](https://github.com/shiffman/Box2D-for-Processing/releases/download/2.0/box2d_processing.zip)

Can be installed through the Processing IDE menu "Sketch" -> "Import
Library" -> "Add Library" -> "Box2D for Processing". Can also be
[installed manually][lib].

[lib]: https://github.com/processing/processing/wiki/How-to-Install-a-Contributed-Library

# Data Collection

If you wish to add a field to the data collection there is a simple process to do so:

1) Add your data field to the correct table
* Open evolvedTD.pde and find the initTables() function.
* Find the table you wish to add to. Copy and paste a line from that table to the end of the table.
* Edit the string passed to the addColumn call to match what you would like to label your column data.
 * __Note__: _Add columns to the ends of the table as the excel file cells are formatted for the current order of things.  If you need to rearrange the collumns or add formatting to the cells, be sure to edit the excel document._
 * __Note__: _The labels currently have 3 spaces on each side.  This is for cosmetics and readability inside the excel document only.  However it is important because the entire string is how you reference your column._
 * __Note__: _Some tables are updated with data from every creature (multiple rows per round) and some are updated with just round data (one row per round).  Assign your data accordingly._

2) Add your row of data to the collection.
 * Open population.pde and find the updateData() function.
 * Find the table that you wish to add your data to.
 * Copy and paste a line from that table and edit it accordingly:
  * change the setType to setInt, setFloat or setString. These are the 3 data types supported.
  * change the string to the column label you created in step 1.
  * change the datafield to your data you want written to the collection.
  * your line layout should look like this: tableRow.setType("   Label   ", data);

Now your data should show up in the designated table and column in our excel and csv files.

## Editing the Excel File

Whenever you open the excel file it auto-populates it's information from the csv files generated by the game.  It then re-populates ever minute automatically.  This should mean that editing the excel file should not really be necessary.  It also means that the excel file technically changes everytime it is openned, so be careful to not save it or you will have a new commit to make.

Changes to the excel file should only be saved and made in the master excel file.  This is because with everyone adding different data collection, there may be several different formats for the same collumn.  Thus the data file for your branch should never be merged to master, rather the master excel file should be edited after your branch has been merged.

Certain edits that you may want to do to the excel file would be coloring and formatting of the cells in the collumn of data that you added.  

You can find tutorials on basic excel editing here: 
[Easy Excel Tutorials](http://www.excel-easy.com/)
