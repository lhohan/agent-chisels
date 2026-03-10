---
name: modeling-c4-diagrams
description: Use when creating, revising, or reviewing C4 architecture diagrams from a real codebase, especially when deciding system, container, and component boundaries or writing Structurizr DSL.
---

# Modeling C4 Diagrams

## Overview

Model the codebase that exists. Do not invent architecture to make the diagram look cleaner.

Start from the repository and runtime behavior, not from abstract layers. Keep the container view strict. If a shared "core" feels missing, that usually means you need a component view, not another container.

## When to Use

Use when:
- A user asks for C4 diagrams, system context, container diagrams, or component diagrams
- You need to write or revise Structurizr DSL
- A first-pass architecture diagram feels correct but too flat
- You need to decide whether something is a container or a component

Do not use this skill for:
- Sequence diagrams
- Infrastructure-only deployment diagrams
- UML class modeling

## Workflow

1. Inspect the codebase first.
   Use `rg`, `README`, entry points, routing, runtime flags, and tests to identify real system boundaries and runtime modes.

2. Find the software system in scope.
   Ask: what is the product or executable the user actually cares about?

3. Model the system context.
   Add people and external software systems or datastores the system actually interacts with.

4. Model the container view strictly.
   Containers are running applications or datastores. Shared modules, packages, libraries, and "core engines" are not containers unless they are deployed or run separately.

5. If the container view feels like it skips important processing, add a component view.
   Decompose a specific container into components that match the real code structure.

6. Write the DSL before worrying about export.
   Get the model right first. Styling and static generation come later.

## Boundary Rules

### System context

Show:
- people
- the software system in scope
- external systems and external datastores

Do not show:
- internal modules
- implementation details

### Container view

Show:
- runtime applications
- datastores
- major externally visible responsibilities

Do not show:
- folders
- crates/modules/packages that are not independently running or deployed
- "core", "engine", or "shared library" as containers unless they are actually separate runtime units

### Component view

Use this when the missing architectural story is inside a container.

Good signs you need a component view:
- the container view looks too direct, such as "web app -> files"
- there is meaningful shared processing logic
- the user explicitly wants to see parsing, domain, reporting, adapters, or renderers

## Naming Rules

Prefer names that track the codebase closely.

Good examples:
- `http handlers`
- `request router`
- `report builder`
- `domain reporting`

Avoid vague labels unless the codebase itself uses them:
- `Core Engine`
- `Business Logic`
- `Processing Layer`

If a friendlier display name helps, keep it close to the code, for example:
- `HTML templates`
- `CLI entry point and argument parser`
- `background job worker`

## Structurizr DSL Guidance

- Keep authored DSL in source-controlled files.
- If components are shared across multiple containers, factor them into an included DSL fragment instead of duplicating them.
- Add styles after the model is stable.
- Keep generated output out of source directories. Export into an ignored directory such as `target/c4` or `build/c4`.

## Common Mistakes

- Inventing a container to represent shared code
- Naming a datastore after computation it does not perform
- Starting from styling before the boundaries are correct
- Using abstract labels that do not map back to real code
- Committing generated static/export files alongside authored DSL

## Quick Decision Test

Ask these questions in order:

1. Does this thing run separately or store data?
   If yes, it may be a container.

2. Is this thing just shared code inside an app?
   If yes, it is probably a component.

3. Does the diagram feel like it jumps from external input straight to an app with no meaningful middle?
   If yes, add a component view for that container.

4. Can an engineer find the diagram element in the codebase quickly?
   If not, rename it.
