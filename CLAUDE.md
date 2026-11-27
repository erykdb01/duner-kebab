
# Project: Rat Kebab

## Game scope
Small, simple, humorous indie game.
Not a full-scale restaurant simulator.

## Engine
Godot. Check actual engine version in project.godot.

## Visual style
- 3D low-poly environment.
- Pixel-art 2D characters.
- First-person gameplay.
- Night atmosphere.

## Design principles
- Keep mechanics simple.
- Prefer existing systems when they work.
- Avoid unnecessary architecture.
- No advanced AI or simulations.
- No unnecessary managers or singletons.
- Focus on a playable core gameplay loop.
- Do not implement speculative features.

## Development rules
- Inspect existing code before changing it.
- Modify only relevant files.
- Never touch `diagramy/` (no edits, moves or deletion, also during cleanup).
- Avoid unnecessary refactoring.
- Do not add dependencies without approval.
- Test only relevant functionality.
- Keep explanations concise.

## Token efficiency
- Never scan .godot/, .git/ or imported assets recursively.
- Avoid reading unrelated scenes and scripts.
- Use targeted searches.
- Summarize findings instead of dumping entire files.
- Do not repeat completed analysis.
- Answer briefly, in Polish. Keep stage summaries short.
- Edit files one by one; no bulk scripts that overwrite existing files.
- Do not generate screenshots or images of the game.
- Do not run tests; the user tests in game. Just say when it is ready and give short steps.

## Plan and progress
- Read `PLAN.md` before starting work; update it after each stage.
- Do one stage at a time, then wait for the user.

## Computer safety (strict)
- Work only inside the project folder. Never read, write or run anything for purposes outside the project.
- Leaving the project folder is FORBIDDEN without the user's explicit prior permission.
- Never install or download anything without asking first and explaining why and how necessary it is.
- Log every download/installation and every exit from the project folder in `DZIENNIK_CLAUDE.md` (git-ignored).
- Using the installed `godot` / `python3` for the project is fine if all their writes stay in the project:
  run Godot with `--headless` and `HOME`, `XDG_DATA_HOME`, `XDG_CONFIG_HOME`, `XDG_CACHE_HOME`
  redirected to `.godot/claude_test/`. Put temporary files there too, not in `/tmp`.
- Do not commit or push unless asked.

