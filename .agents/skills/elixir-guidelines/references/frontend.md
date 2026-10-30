# Project frontend and UI rules

## CSS sources and components

- Use Tailwind utilities and custom CSS for responsive interfaces. Keep the project's Tailwind v4
  CSS-based configuration; adding a JavaScript config file is not required. The current source
  declarations in `assets/css/app.css` are:

      @import "tailwindcss" source(none);
      @source "../css";
      @source "../js";
      @source "../../lib/space_fuel_web";
      @source "../../_build/dev/phoenix-colocated/space_fuel/*/";

- `source(none)` disables automatic detection. Maintain explicit `@source` paths relative to the
  stylesheet, including generated colocated sources used here. Check the actual source/build
  configuration when a path or environment changes; do not copy a placeholder application name.
- Write complete Tailwind class names in source, rather than constructing fragments that the
  scanner cannot recognize. Map variants to complete class strings when needed.
- Use utilities or ordinary CSS declarations instead of `@apply` as a project convention.
- Build new application UI with project-owned components rather than introducing daisyUI styling.
  Existing generated components use daisyUI; this rule does not authorize an unrelated migration.
- Keep application CSS and JavaScript in the existing `app.css` and `app.js` build entrypoints.
  Import vendor code through those bundles rather than adding external script/link dependencies
  to layouts. This is the current project build convention, not a Phoenix platform restriction.
- Put custom JavaScript in bundled modules or supported colocated hooks. Colocated hook script
  tags are compiled into the bundle; they are distinct from ordinary inline runtime scripts.
  Preserve the existing colocated-hook registration when adding external hooks.

Sources: [Tailwind source detection](https://tailwindcss.com/docs/detecting-classes-in-source-files)
and [Phoenix colocated hooks](https://phoenix-live-view.hexdocs.pm/1.2.0/Phoenix.LiveView.ColocatedHook.html).
`assets/css/app.css`, `assets/js/app.js`, and the build configuration define this repository's paths.

## UI acceptance criteria

- Preserve a readable heading hierarchy, consistent spacing, and usable labels at mobile and desktop
  sizes. At a 320 CSS-pixel viewport, avoid page-wide horizontal scrolling except for content that
  inherently requires two-dimensional layout, such as a data table.
- Make controls keyboard-operable with visible focus. Give form inputs associated labels and
  icon-only controls an accessible name; use native controls where possible.
- Target WCAG 2.2 AA contrast: at least 4.5:1 for ordinary text and 3:1 for large text, with the
  standard's exceptions. Check relevant control/state contrast as well; color alone must not carry
  essential information.
- For asynchronous actions, render the applicable loading, success, error, or empty state; keep
  failure recovery available and communicate status changes accessibly.
- Use transitions when they clarify an interaction. Honor `prefers-reduced-motion` for nonessential
  motion as a project requirement, and check keyboard/focus behavior after interactive changes.

Sources: [WCAG 2.2](https://www.w3.org/TR/WCAG22/) (1.4.1, 1.4.3, 1.4.10, 1.4.11, 2.1.1,
2.4.7, 3.3.2, 4.1.2, 4.1.3) and
[Tailwind reduced-motion variants](https://tailwindcss.com/docs/hover-focus-and-other-states#prefers-reduced-motion).
These checks cover relevant UI behaviors; passing them alone does not establish full WCAG conformance.
