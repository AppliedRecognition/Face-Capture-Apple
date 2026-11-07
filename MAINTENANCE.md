# Maintaining the 2.2 line

`2.2.x` is a **supported maintenance line**, not a one-off branch. That distinction is
the whole point of this file: a one-off branch needs no policy and no owner, and a
maintenance line needs both.

It exists because the step from this line to the current one is substantial. `2.2.1` to
`3.0.1` is 26 files, +692/−223, including `FaceCaptureSession`, `FaceCaptureView`, a new
`FaceCaptureViewState`, `SessionFaceTracking` and `FPSMeasurementPlugin`. A consumer whose
version rule is `~> 2.2` cannot take 3.x without doing work, so a fix that matters to them
has to reach them on this line or they do not get it at all.

The last such fix is `Guard the capture continuation against concurrent access`, released
here as **2.2.1** and on `main` as **3.0.1**. The two patches are byte-identical — it was a
cherry-pick, and that is how this line is maintained.

## What gets backported

* **Yes** — security fixes, crashes, data loss, and anything that makes the library
  unusable on a supported OS version.
* **No** — features, behaviour changes, API changes, and refactors. Those belong on `main`
  and reach a 2.2 consumer when they move to 3.x.

Where a fix is borderline, the question is whether a consumer who stays on 2.2 is worse off
without it. If they are not, it does not come here.

## How

```
git switch 2.2.x
git cherry-pick -x <commit-on-main>
```

`-x` records the source commit, which is what makes the next audit possible. **Do not merge
`main` into this branch.** A merge would drag 3.x behaviour onto the 2.2 line, which is the
one thing this branch exists to prevent.

Then bump `spec.version` in `FaceCapture.podspec` and tag the patch — `2.2.2`, and so on.
The tag *is* the release: this repository has no GitHub releases and no CI, so nothing
publishes itself, and a `~> 2.2` version rule picks the tag up on the consumer's next
resolve.

## Owner

Ray Ganong (`rayearl`). Naming one matters because the failure mode of a dormant branch is
not untidiness — it is a consumer waiting on a fix that nobody is watching for.

## End of life

Delete this branch when the last consumer on 2.2 has migrated to 3.x. A condition rather
than a date: until it is met, the line is supported and this file applies.
