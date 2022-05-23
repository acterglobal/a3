+++
title = "Reviews process"
description = "The review process for effektio"
date = 2022-05-23T18:10:00+00:00
updated = 2021-05-23T18:10:00+00:00
draft = false
weight = 1
sort_by = "weight"
template = "docs/page.html"

[extra]
lead = "The review process for effektio"
toc = true
top = false
+++

Please submit your work as early as convinient as PR to inform the devs what is being worked on. Submit it as `draft` until you want it to be reviewed.

## Submitting

When submitting please follow these rules:

1. **atomic** PRs: one feature/fix per branch/PR. Don't mix different, unreleated patches in the same branch
2. **reasoning**: Please give a description, in particular reasoining about choice of dependency etc, the PR
3. **referencing**: add `fixes #NUM` or `refs #NUM` to the description if they fix or reference specfic, known issues

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
3. If you skipped parts, in particular because of lack of expertise, say so - maybe ping someone else more expericend with it, to check these out
4. If only minor changes are needed that the author is trusted to do, lease an `approve` and just expect them to fix the mentioned problems
5. If you leave a `changes requested`-review you are expected to follow up quickly if asked to review again. If that doesn't happen within a work-day, and the PR has another passing review (after the changes), it may be merged without your explicit consent.