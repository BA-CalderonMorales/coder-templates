# Coder Template Assets

This directory will accumulate supporting artifacts (documentation, icon images, future automation scripts) related to Coder templates under development. We intentionally do **not** store the generated `.tar` bundle here yet – those archives are ephemeral during iteration and will later be produced by automation.

## Current Assets

| File | Purpose |
|------|---------|
| `coder-template-icon.png` (to be added) | Example icon you can reference when creating a template in the Coder UI. |

If you prefer using an emoji icon directly in Coder you can still select one in the UI; storing a PNG here is useful when you want a custom branded icon.

## Planned Automation
We will add a lightweight build script / GitHub Action that:

1. Packages the Terraform + supporting files into a versioned template archive.
2. Computes a SHA256 checksum and writes it to `checksums.txt`.
3. (Optionally) Attaches the archive + checksum as workflow artifacts or a GitHub Release.

## Manual Template Creation (Current Flow)
1. From the repo root, assemble the files required by the template (e.g. Terraform `main.tf`, Docker image reference, metadata).
2. Create an archive locally (example command to be documented once structure is finalized).
3. Upload the resulting `.tar` in the Coder UI under Templates -> New Template.
4. Pick an icon (either the PNG here once added, or an emoji) and complete creation.

## Next Steps
- Add the icon PNG (rename existing `image.png` if still present) → `coder-template-icon.png`.
- Capture exact `tar` packaging command once structure is final.
- Introduce CI workflow for reproducible template bundle.

---
_This doc will evolve as we formalize the automated build & publish workflow._
