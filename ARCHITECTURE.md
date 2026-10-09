# Architecture

Godot 4.6.3 Standard, GDScript, Compatibility renderer. `scenes/main.tscn` is the main scene. The sole autoload is `State`, the shared deterministic game-state service. There are no external runtime dependencies.

| Module | Responsibility |
|---|---|
| `scripts/state.gd` | Content loading, inventory, transactions, equipment, upgrades, stats, XP, skills, quests, JSON save schema and backup writes |
| `scripts/player.gd` | CharacterBody2D movement/collision, facing, dodge, stamina, block, attack intent, hurt response, statuses and death |
| `scripts/enemy.gd` | CharacterBody2D enemy state machine, sight checks, territory, telegraphs, attacks, armor, boss phases and summons |
| `scripts/projectile.gd` | Projectile motion, wall ray checks, target collision and damage delivery |
| `scripts/world.gd` | Four JSON-defined connected map layouts, static collision, props, nearest interaction query, tile drawing and ambience |
| `scripts/dialogue.gd` | Offline authored node lookup, world/quest/memory conditions and validated quest actions |
| `scripts/interface.gd` | Shared bronze/charcoal theme, screen HUD, responsive containers, headings, scrolling and focus |
| `scripts/game.gd` | Scene composition, input registration, menu builders, transitions, encounter spawning, interaction orchestration and presentation |
| `data/*.json` | Stable item, NPC, enemy and quest IDs and definitions |

Player emits `attacked` and `died`; enemies emit `killed`, `projectile` and `summon`; State emits `changed`, `notice` and `cleansed`. The coordinator subscribes and dispatches. Dialogue has no HTTP, free-text evaluation or executable-string path. Stable authored action dictionaries delegate to State transactions; service actions are restricted by NPC. Shop purchases require an explicit confirmation.

All menus reuse `Interface.open`, `text`, `button` and `item_title`. A CenterContainer positions their PanelContainer, with a heading outside a scroll body. Journal/inventory/shop have independent left and right scroll columns. Replaced panels are detached, hidden and queue-freed; deferred focus searches the current panel instead of holding a stale control. Dialogue and services lock player input and disable enemy/projectile processing. Escape guards prevent a closing menu from reopening pause in the same frame.

## Content schemas

- Items: stable key, `name`, `slot`, `price`, `rarity`, `description`; optional weapon `kind/attack/speed/reach/cost`, armor `defense`, consumable `effect`.
- NPCs: stable key, `name`, `role`, `line`. Structured relationship flags live in save `memory`.
- Enemies: stable key, `hp`, `attack`, `speed`, `xp`, `behavior`; pattern dispatch currently uses archetype IDs in the controller.
- Quests: stable key, `name`, `text`, `reward`; status is absent, `active` or `complete`. Coordinator validates individual objective deliveries before invoking the once-only reward function.
- Saves: version 1 JSON dictionary with player location, statistics, attributes, skills, inventory counts, equipped IDs, upgrades, quests, persistent entity flags, NPC memory, checkpoint and settings. No Godot objects are serialized. Unknown versions fall back to backup or reject.

Position and checkpoint coordinates are validated inside map boundaries. Item IDs, positive integral quantities, equipment ownership, stat types, settings ranges and quest IDs/statuses are checked on load. Save writes use a temporary file, retain the previous primary as `.bak`, then rename the temporary file. This guards common corruption; it is not a transactional database or an anti-cheat boundary.

## Rendering and performance

Detailed terrain materials are 48×48; decorative ritual inlays are 192×192. Player frames and NPC/enemy sprites are 64×64; boss is 128×128; portraits are 128×128; buildings are 256×192. Nearest sampling preserves discrete pixels. Original generated source atlases are committed under `assets/source/` and excluded from app exports. `tools/import_art.py` extracts them reproducibly; player textures are cached once instead of loaded each physics frame.

A 960×540 logical UI canvas scales independently of the world camera's 1.2× zoom. Physical window tests include 800×450, 1152×648, 1600×900 and 1024×768. The camera remains within the existing 1440×960 maps; their collision layout and interaction IDs remain unchanged. NPC labels appear only nearby and avoid the HUD's screen region. World tint and local lamps never tint UI. Static world effects redraw at roughly 7 Hz; physics runs at Godot's regular rate. Real Apple Silicon frame-time measurements remain outstanding.

Map layouts live in `data/maps.json`. `data/dialogue_trees.json` contains stable NPC/node IDs, text, conditional variants, choices, next IDs and optional actions. `data/dialogue.json` supplies authored history text during tree generation; it is not an AI adapter. `State` owns objective validation, once-only rewards and reconciliation. Save version 1 remains compatible; loading removes the obsolete dialogue-service preference without erasing player progress or memory.
