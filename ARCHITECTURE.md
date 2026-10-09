# Architecture

Godot 4.6.3 Standard, GDScript, Compatibility renderer. `scenes/main.tscn` is the main scene. The sole autoload is `State`, the shared deterministic game-state service. There are no external runtime dependencies.

| Module | Responsibility |
|---|---|
| `scripts/state.gd` | Content loading, inventory, transactions, equipment, upgrades, stats, XP, skills, quests, JSON save schema and backup writes |
| `scripts/player.gd` | CharacterBody2D movement/collision, facing, dodge, stamina, block, attack intent, hurt response, statuses and death |
| `scripts/enemy.gd` | CharacterBody2D enemy state machine, sight checks, territory, telegraphs, attacks, armor, boss phases and summons |
| `scripts/projectile.gd` | Projectile motion, wall ray checks, target collision and damage delivery |
| `scripts/world.gd` | Four JSON-defined connected map layouts, static collision, props, nearest interaction query, tile drawing and ambience |
| `scripts/dialogue.gd` | Authored fallback, bounded optional asynchronous Ollama adapter and authored purchase-intent proposals |
| `scripts/game.gd` | Scene composition, input registration, menus/HUD, transitions, encounter spawning, interaction orchestration and presentation |
| `data/*.json` | Stable item, NPC, enemy and quest IDs and definitions |

Player emits `attacked` and `died`; enemies emit `killed`, `projectile` and `summon`; dialogue emits `reply`; State emits `changed`, `notice` and `cleansed`. The coordinator subscribes and dispatches. AI-generated text has no execution path to State mutations. Purchase proposals contain a stable item ID and lead to an explicit deterministic confirmation.

The coordinator's UI is intentionally constructed programmatically in this first playable. The next refactor should split menus into reusable scenes, move map placement and quest conditions into richer resources, and introduce an independent boss-pattern module. The present boss shares the enemy controller and uses data for baseline statistics; it is not yet a fully data-driven boss framework.

## Content schemas

- Items: stable key, `name`, `slot`, `price`, `rarity`, `description`; optional weapon `kind/attack/speed/reach/cost`, armor `defense`, consumable `effect`.
- NPCs: stable key, `name`, `role`, `line`. Structured relationship flags live in save `memory`.
- Enemies: stable key, `hp`, `attack`, `speed`, `xp`, `behavior`; pattern dispatch currently uses archetype IDs in the controller.
- Quests: stable key, `name`, `text`, `reward`; status is absent, `active` or `complete`. Coordinator validates individual objective deliveries before invoking the once-only reward function.
- Saves: version 1 JSON dictionary with player location, statistics, attributes, skills, inventory counts, equipped IDs, upgrades, quests, persistent entity flags, NPC memory, checkpoint and settings. No Godot objects are serialized. Unknown versions fall back to backup or reject.

Position and checkpoint coordinates are validated inside map boundaries. Item IDs, positive integral quantities, equipment ownership, stat types, settings ranges and quest IDs/statuses are checked on load. Save writes use a temporary file, retain the previous primary as `.bak`, then rename the temporary file. This guards common corruption; it is not a transactional database or an anti-cheat boundary.

## Rendering and performance

Source terrain is 16×16 and actor/prop art 32×32, drawn at consistent whole-number scales with nearest sampling. A 960×540 logical canvas keeps text/UI legible while pixel imagery remains coarse. The camera scrolls within each 1440×960 map. Static tile rendering is redrawn at roughly 7 Hz for ambient effects; CharacterBody2D physics and gameplay run at Godot's regular rate. The slice caps active enemies through fixed map spawns and two boss summons. No Apple Silicon frame-time benchmark is available yet.

The 0.2.0 map layouts are in `data/maps.json`, and NPC background topics in `data/dialogue.json`. State owns `objective_ready`, `turn_in`, `quest_progress` and `reconcile_quests`; reward code rejects unmet objectives. Dialogue emits only text and proposes bounded action IDs. Menus hide and queue-free old controls rather than freeing an emitting button synchronously.
