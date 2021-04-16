# Contributing to ActsAsParanoid

We welcome all contributions to ActsAsParanoid. Below are some guidelines to
help the process of handling issues and pull requests go smoothly.

## Issues

When creating an issue, please try to provide as much information as possible.
Also, please follow the guidelines below to make it easier for us to figure out
what's going on. If you miss any of these points we will probably ask you to
improve the ticket.

- Include a clear title describing the problem
- Describe what you are trying to achieve
- Describe what you did, preferably including relevant code
- Describe what you expected to happen
- Describe what happened instead, possibly including relevant output
- Use [code blocks](https://github.github.com/gfm/#fenced-code-blocks) to
  format any code and output in your ticket to make it readable.

## Pull requests

If you have an idea for a particular feature, it's probably best to create a
GitHub issue for it before trying to implement it yourself. That way, we can
discuss the feature and whether it makes sense to include in ActsAsParanoid itself
before putting in the work to implement it.

If you want to send pull requests or patches, try to follow the instructions
below. **If you get stuck, please make a pull request anyway and we'll try to
help out.**

- Make sure `rake test` runs without reporting any failures.
- Add tests for your feature. Otherwise, we can't see if it works or if we
  break it later.
- Make sure latest master merges cleanly with your branch. Things might
  have moved around since you forked.
- Try not to include changes that are irrelevant to your feature in the
  same commit.
- Keep an eye on the build results in GitHub Actions. If the build fails and it
  seems due to your changes, please update your pull request with a fix.

### The review process

- We will try to review your pull request as soon as possible but we can make no
  guarantees. Feel free to ping us now and again.
- We will probably ask you to rebase your branch on current master at some point
  during the review process.
  If you are unsure how to do this,
  [this in-depth guide](https://git-rebase.io/) should help out.
- If you have any unclear commit messages, work-in-progress commits, or commits
  that just fix a mistake in a previous commits, we will ask you to clean up
  the history.
  Again, [the git-rebase guide](https://git-rebase.io/) should help out.
- At the end of the review process we may still choose not to merge your pull
  request. For example, this could happen if we decide the proposed feature
  should not be part of ActsAsParanoid, or if the technical implementation does not
  match where we want to go with the architecture the project.
- We will generally not merge any pull requests that make the build fail, unless
  it's very clearly not related to the changes in the pull request.
