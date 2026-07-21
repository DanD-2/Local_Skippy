# Free CAD Selection Notes

## Legacy Note

This document is legacy reference for the older mixed-workstation deployment path.

It is not part of the current primary Ubuntu Server 26.04 dedicated-host build.

## Purpose

Use this note to choose the first free CAD tool to validate on the HP Z8 G4 Linux workstation.

The current requirement is free-access CAD rather than a specific proprietary application, so the right answer depends on the kind of design work rather than brand preference.

## Primary Candidates

## FreeCAD

Best fit when:

1. You need 3D parametric modeling.
2. You want assemblies, constraints, and engineering-oriented workflows.
3. The work is closer to mechanical design than to illustration.

Tradeoffs:

1. Interface and workflow can feel rough compared with commercial CAD.
2. Learning curve is real.
3. Some workflows need patience and validation.

Recommendation:

This should be the first CAD validation target for the Local_LLM workstation.

## LibreCAD

Best fit when:

1. You need 2D drafting.
2. The work is primarily plans, layouts, or line drawings.
3. You do not need full 3D parametric modeling.

Tradeoffs:

1. Not a substitute for 3D mechanical CAD.
2. Scope is narrower than FreeCAD.

Recommendation:

Use this if the real requirement is 2D drafting rather than 3D CAD.

## Blender

Best fit when:

1. The work is artistic modeling, rendering, or animation.
2. Precision engineering constraints are not the main requirement.

Tradeoffs:

1. It is not a full CAD replacement.
2. Modeling success does not imply engineering-CAD suitability.

Recommendation:

Do not use Blender as the primary answer if the requirement is truly CAD.

## Decision Rule

Start with:

1. FreeCAD for 3D engineering-style work.
2. LibreCAD for 2D drafting work.

Only revisit the host-OS decision if both fail to meet the actual design requirement and a Windows-only CAD product becomes necessary.