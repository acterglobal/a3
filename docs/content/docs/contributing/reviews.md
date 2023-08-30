+++
title = "Reviews process"
description = "The review process for acter"
date = 2022-05-23T18:10:00+00:00
updated = 2021-05-23T18:10:00+00:00
draft = false
weight = 1
sort_by = "weight"
template = "docs/page.html"

[extra]
lead = "The review process for acter"
toc = true
top = false
+++

Please submit your work as early as convenient as PR to inform the devs what is being worked on. Submit it as `draft` until you want it to be reviewed.

## Submitting

When submitting please follow these rules:

1. **atomic** PRs: one feature/fix per branch/PR. Don't mix different, unreleased patches in the same branch
2. **reasoning**: Please give a description, in particular reasoning about choice of dependency etc, the PR
3. **referencing**: add `fixes #NUM` or `refs #NUM` to the description if they fix or reference specific, known issues
4. **user logs**: If your PR changes user-facing behavior or is otherwise noteworthy for actual end-users, make sure to include a changelog file for your changes (see [Tracking Changes][]).

## During the review

For the review, it is the submitters task to get the PR merged, it is their job to resolve merge-conflicts and fix broken CI-checks. Furthermore, no issue is considered done (and thus should not be closed) before a PR with the fix has been merged to `main`. For a PR to be considered fine for a merge it must:

1. have a positive review from at least one other core developer
2. all remarks in the reviews must be addressed, and are ideally resolved
3. Git History may not be rewritten after a PR has been submitted for review

When these check out and no required CI check blocks the merge, any core developer may merge the changes.

If someone left a `changes requested` review and you think you've addressed their concerns, use the github feature to re-request them to review it.

## As a reviewer

1. Be specific and precise in what you want.
2. Elaborate on the reasoning, don't be harsh or picky.
3. If you skipped parts, in particular because of lack of expertise, say so - maybe ping someone else more experienced with it, to check these out
4. If only minor changes are needed that the author is trusted to do, lease an `approve` and just expect them to fix the mentioned problems
5. If you leave a `changes requested`-review you are expected to follow up quickly if asked to review again. If that doesn't happen within a work-day, and the PR has another passing review (after the changes), it may be merged without your explicit consent.

## Tracking changes

We consider Git commits and Github PRs as developer-oriented documentation and changelogs. As such please be detailed and explain your choices and also what other options have been considered and why they might have been dismissed.

However, we are also a user-facing app and as such, when we need to provide proper change records for them to. From 2023-07-18 it is mandatory to follow this process and document any user-facing changes properly for us to be able to communicate them.

Documenting user-oriented changes is fairly easy. Just create a new file in the `.changes`-folder in the root of the repository, ideally prefixed with your PR or issue-number in the file-name for easy collision control, an optional name (with dashes `-` instead of spaces) and ending with the extension `.md`. In there, for every significant change create one line starting with a dash and space (`- `). Optionally you can add any of `[fix]`, `[feature]` or`[security]` first in the line to indicate which type of change that is.

If you have additional context you want to provider you can start any additional line explaining the same change with two spaces, aligning it under the first line. You can add as many lines of changes as you made significant changes. These are going to be rendered as markdown, so please use markdown to link to further reading, linked issues and alike.

An example file called `.changes/771-my-changes.md`:

```
- [fix] We fixed popups
  This is a further explanation, on what we did to fix popups in this changeset.
  The explanation is multiple lines long and explain that in information in detail
  and [links to the issue #771](https://github.com/acterglobal/a3/pull/771) through
  markdown which introduced these nice changelog generation code
- [feature] This is a feature we added
- This is a third thing we did, not having a signifier
```
