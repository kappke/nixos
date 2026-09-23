# Desktop shell

`shell.qml` is the Quickshell entry point. It wires platform services to one panel per screen and should contain composition code only.

## Layout

- `bar/`: panel-only widgets and tooltips.
- `components/`: reusable visual primitives and the shared `Theme` singleton.
- `features/`: self-contained popup, dock, and row implementations grouped by user-facing feature.
- `services/`: process-backed data providers with no presentation responsibilities.

Feature files import shared controls explicitly with `import "../../components" as UI`. This keeps cross-directory dependencies visible. Types in the same feature directory may refer to each other directly.

## Conventions

- Keep colors, fonts, radii, and common dimensions in `components/Theme.qml`.
- Keep subprocesses and parsing out of panel widgets when their data can be exposed by a service.
- Popups receive their anchor window and an `open` value from `shell.qml`; they do not mutate panel state.
- Add a reusable component only when at least two call sites share behavior, not merely similar markup.
- Prefer focused files named after the QML type they export.

The Home Manager module deploys this complete directory to `~/.config/quickshell/desktop-shell`.
