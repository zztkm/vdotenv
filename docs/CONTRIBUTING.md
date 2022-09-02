# Contributing Guide

I'm really glad you're reading this, because we need volunteer developers to help this project come to fruition.


The [issue tracker](https://github.com/zztkm/vdotenv/issues) is the preferred channel for bug reports, feature requests, and submitting pull requests.

### Feature requests

Feature requests are welcome, but please take a moment to find out whether your idea fits with the scope and aims of the project. It's up to you to make a strong case to convince the project's developers of the merits of this feature.

To get approval for your feature request, please create an issue on the issue tracker with as much detail and context as possible.

### Reporting Bugs
A bug is a demonstrable, reproducible problem that is caused by the code in the repository. Good bug reports are extremely helpful, so thanks!

**Guidelines for bug reports:**

1. Use the GitHub issue search — check if the issue has already been reported.
2. Check if the issue has been fixed — try to reproduce it using the latest **master** branch in the repository.
3. Isolate the problem - you should provide a live example — ideally also create a reduced test case.

### Submitting Pull requests

Good pull requests are an amazing help.

[Fork](https://help.github.com/en/github/getting-started-with-github/fork-a-repo) the project, clone your fork, and configure the remotes:

```console
  $ git clone https://github.com/<your-username>/vdotenv.git
  $ cd vdotenv
  $ git remote add upstream https://github.com/zztkm/vdotenv.git
```

Create a new topic branch to contain your feature, change, or fix:
```console
  $ git switch -c <topic-branch-name>
```

Development workflow:
1. Add features or fix bugs, etc.
2. Create tests for your work.
3. Run the test.
	- `make test`

Locally merge (or rebase) the upstream development branch into your topic branch:

```console
  $ git pull upstream main
```

Push your topic branch up to your fork:
```console
# Always run v fmt -w file.v before pushing your code.
  $ make doc
  $ git push origin <topic-branch-name>
```

[Create new Pull Request](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests/creating-a-pull-request) with a clear title and description against the master branch.

By submitting a patch, you agree to allow the project owner to license your work under the terms of the [MIT License](../LICENSE.txt).

