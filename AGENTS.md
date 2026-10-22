# Repository guidance

## Project

TankGame3D is a Godot 3D tank game written in GDScript. The project declares Godot 4.7, uses the GL Compatibility renderer, and selects Jolt Physics. Use a compatible Godot version; do not upgrade the project format or change rendering/physics backends incidentally.

## Layout

- `project.godot`: engine configuration, main scene UID, and input actions.
- `game/world/main.tscn`: main playable map.
- `game/world/wall.tscn`: reusable wall scene.
- `game/player/`: tank scene and script for movement, firing, and track smoke.
- `game/projectiles/`: missile scene and script for movement, ricochets, owner collision exceptions, and lifetime.
- `assets/tank/`: tank models and textures in FBX, glTF, and OBJ formats.
- `assets/effects/smoke/`: smoke textures and particle resources.

## Development conventions

- Follow existing GDScript style: tabs, snake_case functions/variables, uppercase constants, and types where useful. Existing comments are mainly French; preserve their meaning when editing.
- Keep physics movement in `_physics_process` and use Godot input actions. Movement uses `ui_up`, `ui_down`, `ui_left`, and `ui_right`; `shoot` is mapped to Space.
- Keep script node paths synchronized with scenes. The tank script relies on `Marker3D`, `ParticLeft`, and `ParticRight`, plus the exported `rocket_scene` assignment.
- Preserve resource UIDs, `.gd.uid` files, scene references, and case-sensitive asset paths. Prefer Godot's editor for scene/resource and project-setting changes; keep any text edits narrowly scoped.
- Do not hand-edit generated `.godot/` data or commit import caches. Avoid modifying source art unless the task requires it.
- Inspect `git status` before editing and preserve unrelated local changes.

## Running and validation

Run commands from the repository root:

```sh
# Open the editor and import assets.
godot --editor --path .

# Run the configured main scene.
godot --path .

# Headless import/parse check (writes Godot cache files).
godot --headless --editor --path . --quit

# Brief startup smoke check; not a gameplay test.
godot --headless --path . --quit-after 120
```

There is no dedicated automated test suite or build/lint configuration in the repository. For code or scene changes, run the relevant Godot checks and inspect errors. For gameplay changes, manually check movement, turning, Space firing, wall ricochets, projectile cleanup, and smoke emission as applicable. Headless checks do not validate rendering or interactive behavior. Documentation-only changes need no game run.

Before finishing, inspect `git diff --check` and the diff for accidental scene/resource churn. Report checks performed and any checks that could not run.
