# MTM Front-Back — Claude working guide

This repository contains the Flutter frontend for Medical Teams Management. Work within the existing application; do not replace it with a web, React, React Native, Swift, or new-package implementation.

## First reads for frontend and visual work

1. Read [frontend design steps](docs/FRONTEND-DESIGN-STEPS.md).
2. Read [frontend design notes](docs/FRONTEND-DESIGN-NOTES.md).
3. Inspect the affected feature, `flutter_app/lib/core/theme/`, `flutter_app/lib/core/motion/`, and `design_references/` before editing.
4. Use the appropriate skill in `.claude/skills/` before changing a screen, interaction, or animation.

## Project rules

- Preserve the current architecture, dependencies, files, and user changes unless the request explicitly asks to change them.
- Do not fix, suppress, reformat around, or remove existing errors merely because they are present. Address errors only when the user requests that work.
- Build UI with the existing Flutter theme, palette, typography, widgets, and motion primitives. Do not introduce a package for a visual or motion effect without explicit approval.
- The app is Arabic-first. Use `Directionality`, `AlignmentDirectional`, and `EdgeInsetsDirectional`; test every horizontal layout and transition in RTL.
- Treat loading, empty, offline, failure, conflict, authentication, and permission states as designed screens—not afterthoughts.
- Respect `MediaQuery.disableAnimations` and accessible navigation. Motion must clarify an interaction, never delay it.
- Keep changes small, focused, and consistent with the existing design language. Verify with the relevant Flutter checks when the requested work includes code changes.

## Available frontend/design skills

- `frontend-design` — intentional visual direction and design planning.
- `impeccable` — static UI craft and design-system quality.
- `emil-design-eng` — interaction and design-engineering principles.
- `animate`, `apple-design`, `animation-vocabulary`, `find-animation-opportunities`, `improve-animations`, `review-animations` — motion design, terminology, planning, and review.

The copied skills are guidance. Translate web-oriented examples into Flutter using the project’s current primitives; do not paste CSS, JSX, Framer Motion, or web-only code into this app.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
