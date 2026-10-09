# Architecture

Godot 4.6.3 Standard, GDScript, Compatibility renderer. `scenes/main.tscn` is the main scene. The sole autoload is `State`, the shared deterministic game-state service. There are no external runtime dependencies.

| Module | Responsibility |
|---|---|
| `scripts/state.gd` | Content loading, inventory, transactions, equipment, upgrades, stats, XP, skills, quests, JSON save schema and backup writes |
| `scripts/player.gd` | CharacterBody2D movement/collision, facing, dodge, stamina, block, attack intent, hurt response, statuses and death |
| `scripts/enemy.gd` | CharacterBody2D enemy state machine, sight checks, territory, telegraphs, attacks, armor, boss phases and summons |
| `scripts/projectile.gd` | Projectile motion, wall ray checks, target collision and damage delivery |
| `scripts/world.gd` | Four JSON-defined connected map layouts, static collision, props, nearest interaction query, tile drawing and ambience |
| `scripts/dialogue.gd` | Strict local node/choice lookup, bounded conversation history, per-NPC knowledge and validated quest actions |
| `scripts/typography.gd` | Licensed Pixelify Sans resource, 16/24/32 typography and shared font theme |
| `scripts/world_label.gd`, `world_labels.gd` | World-space panels, vicinity visibility, character/UI bounds checks and nearest-label priority |
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

Map layouts live in `data/maps.json`. `data/dialogue_trees.json` contains stable NPC/node IDs, text, conditional variants, choices, next IDs and optional actions. `data/dialogue_trees.json` is the canonical hand-authored source; `tools/validate_dialogue.py` checks IDs, reachability, conditions, exits and action ownership. The older `data/dialogue.json` is retained as historical writing material and is not used at runtime. `State` owns objective validation, once-only rewards and reconciliation. Save version 1 remains compatible; loading removes the obsolete dialogue-service preference without erasing player progress or memory.

## Conversation context, knowledge and labels (0.4.0)

`Dialogue.context` holds NPC, current/previous node, topic, navigation history (maximum 24), selected question IDs, recently revealed facts and snapshots of quests/story flags. History trims cycles. `@back`, `@main` and `@exit` are explicit navigation targets. Service windows preserve context; Goodbye resets it. Every choice ID is scoped to its NPC and node. UI callbacks also retain their owning NPC/node, rejecting callbacks from a replaced panel. Missing nodes never fall back to root.

Entering a node records only its authored `reveals` keys under `State.s.memory.dialogue_knowledge[npc]`. Conditions can require knowledge or its absence, existing quest status, world flags or relationship memory. This additive save field needs no schema-version change. Narrative conditions are evaluated deterministically; story completion and relationships have explicit written variants.

World labels are ordinary world-space Controls under a Node2D, at z-index 100 below the screen UI CanvasLayer. Roof/entrance anchors derive from building rectangles; the market uses its existing prop position. The label manager compensates camera zoom for a steady logical text size. It tries attached world-space placements that avoid HUD, viewport, interaction prompt and character bounds, then resolves competing labels by player distance. Unsafe labels hide immediately; distance visibility fades. The existing world layout/collisions are untouched. Exposed manager properties configure visibility and building/NPC ranges.

`Typography.theme()` supplies Pixelify Sans to every screen interface and world label. The original font and full SIL OFL are bundled; the license is included in exported content. Font import uses no antialiasing, no hinting/subpixel positioning, oversampling 1 and no system-font fallback. The unsupported diamond selector was replaced with an ASCII chevron. Practical fractional window scaling still depends on Godot and display pixels; native Retina inspection remains outstanding.
