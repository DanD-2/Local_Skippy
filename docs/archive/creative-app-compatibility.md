# Creative Application Compatibility Notes

## Purpose

Use this note to judge whether the HP Z8 G4 can remain on a Linux-first Local_LLM path while also serving as a creative workstation.

The current app assumptions come from the requested stack:

1. DaVinci Resolve.
2. Blender.
3. VS Code with LLM integration.
4. Chrome or an equivalent browser.
5. GitHub workflows.
6. OneNote or an equivalent note system.
7. OBS Studio.
8. Wireshark.
9. Free-access CAD tooling.

## Current Linux Fit Assessment

## Strong Linux Fit

These are reasonable on Ubuntu Studio 24.04 LTS:

1. Blender.
2. VS Code.
3. Chrome or Chromium.
4. Git and GitHub workflows.
5. OBS Studio.
6. Wireshark.

## Viable With Caveats

These can work, but they drive more build discipline:

1. DaVinci Resolve.

Main caveats for Resolve:

1. NVIDIA drivers must be stable.
2. Codec expectations on Linux can differ from Windows.
3. The workstation build should be kept conservative rather than experimental.

## Browser-Or-Replacement Path

These are better handled through the browser or a substitute rather than expecting a perfect native match:

1. OneNote.

Practical path:

1. Use the web version of OneNote.
2. Or replace it with a Linux-friendly notes workflow if native integration matters more than exact product matching.

## CAD Direction

The current CAD requirement is free-access rather than a specific proprietary application.

That makes the Linux path more realistic.

Recommended first validation targets:

1. FreeCAD for general 3D parametric CAD evaluation.
2. LibreCAD if the need is primarily 2D drafting.
3. Blender only for modeling tasks that are not actually CAD-constrained.

See `docs/cad-selection.md` for the first-pass choice between FreeCAD and LibreCAD.

## Resolve And Driver Discipline

Resolve is the creative application most likely to punish an unstable Linux GPU stack.

Use `docs/resolve-nvidia-prep.md` before calling the workstation stable for mixed Resolve and Local_LLM use.

## Decision Rule

Ubuntu Studio remains the preferred host OS if:

1. DaVinci Resolve is acceptable on Linux for your workflow.
2. FreeCAD or another Linux-friendly free CAD tool is sufficient.
3. Browser-based OneNote access is acceptable.

Revisit the host-OS decision if:

1. Resolve workflow issues are unacceptable.
2. A Windows-only CAD application becomes mandatory.
3. Exact Microsoft desktop application parity becomes a hard requirement.