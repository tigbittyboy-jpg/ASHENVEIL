# Development log — 2026-10-09

## Repository and tools

The selected GitHub repository was verified empty: unborn local branch, no remote refs, no `main` and no source files. The user subsequently supplied the full game implementation brief, authorizing creation of the project. No pre-existing application files were overwritten. Godot 4.6.3 Standard, Python and Pillow were discovered. The cloud sandbox required XDG data/config/cache directories under `/workspace`; no secret values were requested.

## Implemented milestones

1. Created a Compatibility-renderer Godot project, main scene, CharacterBody2D controller, runtime InputMap, camera, world collision and pause/title screens.
2. Added stamina attacks, directional melee, bows/staves, Ember magic, blocking, dodge immunity, knockback, damage, statuses, death/respawn and enemy state machines.
3. Added Hollowmere, Weeping Forest, partitioned Crypt and Shrine layouts, gates, checkpoints, herbs, containers and hazards. Added six enemy types, three persistent elite encounters and the Bellkeeper's phases, telegraphs, summons and radial projectiles.
4. Implemented stable JSON content IDs, inventory, equipment, validated purchase/sale confirmation, upgrades, XP, five attributes, six skill upgrades and journal.
5. Added eight named NPCs, five quests, a branching charm outcome, memory flags, boss reactions and a shrine chapter conclusion.
6. Added optional asynchronous Ollama requests, four-second timeout, cancellation, response bounds, history bounds, authored fallback and deterministic purchase-intent proposals. No generated text mutates game state.
7. Created original reproducible pixel terrain, actors, props, houses and synthesized effects/music. Added volume controls, HUD bars, menu styling, simple facing/bobbing and environmental fog/halos.
8. Implemented versioned JSON saves, atomic replacement, backups, strict basic schema checks and four save slots.

## Validation and corrections

- Fixed a GDScript inferred-type parse error during editor import.
- Fixed the initial unwritable default Godot data/config paths with supported XDG overrides.
- First integration suite: 48 passed, two failures. Fixed a repeated direct chest interaction; changed a serialization test to compare semantic dictionaries instead of integer/float JSON string spelling.
- Expanded malformed-save validation, corruption fallback without noisy parser errors, merchant-intent guards and NPC history handling.
- Fixed the unavailable-Ollama test to expect the boss-completion contextual response rather than the pre-boss forest response; HTTP parsing now handles an empty/error body without printing a JSON parser error.
- Final `tools/cloud_setup.sh`: editor import clean; 57 assertions passed, zero failed. Tests include scripted progression, not an unassisted human playthrough.
- Used an Xorg dummy screen with Mesa software rendering to run the scene and capture village/boss screenshots. Dummy/headless audio skips continuous WAV playback to avoid shutdown playback-resource warnings. The V-Sync warning is a software-display limitation. Real audio-device output remains untested.
- Downloaded matching official 4.6.3 export templates over verified TLS and checked their official SHA-512 checksum. Corrected the ARM export texture setting. The official macOS template contains a universal executable, so the preset uses universal with native ARM64 included.
- Export succeeded. App structure, external content pack and Mach-O native ARM64 slice were inspected. The exported content pack also launched in headless Linux Godot without script/resource errors; both ZIP archives passed integrity checks. Native macOS execution/signing/notarization remain outstanding.

## Scope still outstanding

This is an early first playable, not a full polished 30–60 minute release. Required follow-up includes a real macOS playthrough and performance test, richer map/NPC content, full directional animation and feedback, deeper enemy navigation/behaviors, stronger boss presentation, elemental combat details, reusable UI scenes and expanded quest resources. Detailed limitations and exact launch instructions are in README.md.

## macOS damaged-app report and 0.1.1 correction

The user reported macOS's “damaged and can't be opened” dialog on the original download. The initial export had signing disabled. Enabled Godot's documented built-in ad hoc signing, bumped the bundle version to 0.1.1, excluded download archives from future exports, and rebuilt the app. Independently checked the ARM64 and x86_64 CodeDirectory page hashes, ad hoc flags, Info.plist seal, CodeResources seal and all six resource hashes. ZIP integrity also passed. Updated START_HERE.md with app-specific recovery guarded by Apple's signature verification. Ad hoc signatures do not grant Developer ID trust or notarization; actual macOS launch/Gatekeeper validation remain outstanding.

## 0.2.0 user playtest response

Addressed clicking music, bright/bland maps, incoherent town placement, heavy damage/stun chains, typed dialogue and quest rewards, and oversized boss attacks. Found every player status used a four-second duration, while immunity expired after 0.55 seconds. Shortened stun and added repeat-stun resistance, longer hit immunity and dodge escape. Reworked encounter tuning, map data/art/lighting and audio. Added real UI Enter and quest-button regressions, late objective reconciliation, equipped-charm integrity checks, and exact reward receipts. Fixed a freed-object signal error in menu rebuilding. Audio now uses smooth 32-second loops and independent effects; automated waveform checks pass. Continuous audio and SFX are skipped under the actual Dummy driver in QA, resolving its shutdown playback warnings. A starter-sword boss bot uses collision-driven movement, normal stamina/cooldowns and reactive dodging rather than teleporting or forced damage. It defeated the boss in 22.9 simulated seconds with 34 sword attacks and no potions, then reached the shrine. This is an automated avoidance strategy, not proof of comfortable human balance. Expanded regression suite: 100 passed, zero failed.
