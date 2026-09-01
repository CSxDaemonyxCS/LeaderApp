# Frontend design notes

Adapted from MTM-PRO’s frontend-design guidance and Flutter translation rules.

## Visual direction

- Make deliberate choices that reflect the actual medical-team task and its Arabic-first audience. Avoid generic “AI dashboard” defaults.
- Typography carries much of the app’s personality. Preserve the supplied IBM Plex Sans Arabic fonts and established type scale unless a request explicitly changes the system.
- Use layout structure, labels, dividers, and grouping to communicate real information—not as empty decoration.
- Reuse the palette and tokens in `flutter_app/lib/core/theme/`; a one-off literal color, radius, font, or spacing value should be a deliberate design-system decision.

## Flutter translation

| Design guidance | Flutter implementation |
| --- | --- |
| Simple visual transition | `AnimatedContainer`, `AnimatedOpacity`, `AnimatedAlign`, `AnimatedSwitcher`, or `TweenAnimationBuilder` |
| Timed or coordinated transition | `AnimationController` with `AnimatedBuilder`, `FadeTransition`, `SlideTransition`, or `ScaleTransition` |
| Spring / physical response | `SpringDescription` and `SpringSimulation`; no additional animation package |
| Smooth performant movement | Prefer `Transform` and opacity; avoid animating layout properties every frame when possible |
| Reduced motion | Check `MediaQuery.disableAnimations` and `accessibleNavigation` |
| Shared route element | Use `Hero` and a deliberate route transition where appropriate |

## RTL and interaction

- Prefer `AlignmentDirectional` and `EdgeInsetsDirectional` over non-directional alternatives.
- Explicitly invert any horizontal `Offset` used by `SlideTransition` when direction requires it; Flutter does not do this automatically.
- Motion should explain hierarchy, confirmation, pending/offline work, conflict, or recovery. It should be interruptible and should not block a critical task.
- A professional operational app benefits from crisp, restrained motion. Do not add decorative animation merely to make a screen feel active.
