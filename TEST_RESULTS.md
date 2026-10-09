# Test results

Engine: Godot 4.6.3 Standard (official), Linux x86_64. Date: 2026-10-09.

## Executed checks

| Check | Observed result |
|---|---|
| `bash tools/cloud_setup.sh` | Completed successfully: editor import followed by isolated test scene |
| `godot --headless --path . res://tests/runner.tscn` | **57 passed, 0 failed** |
| Graphics scene capture | Village and boss arena rendered through Xorg/Mesa Compatibility renderer; screenshots under `docs/` |
| macOS export | Universal standalone app ZIP generated with official matching templates |
| Template integrity | Official SHA-512 checksum matched the downloaded template archive |
| Exported content pack launch | Packaged `.pck` launched in headless Godot on Linux without script/resource errors |
| Version 0.1.1 ad hoc signatures | Both native slices passed all CodeDirectory page-hash checks; Info.plist, CodeResources and six sealed resource hashes verified using `tools/verify_macos_bundle.py` |
| ZIP integrity | macOS and source archives passed ZIP integrity checks |
| App architecture | Mach-O contains ARM64 (`0x100000c`) and x86_64 slices; external `.pck` present |

The suite covers content counts, damage floors/blocking, invalid quantities, stacking, equipment ownership/stat effects, sales and purchases, insufficient currency, upgrades, consumables, XP, attributes, skills, quest reward uniqueness, save restoration/schema checks/backup recovery, input-driven movement, world collisions, NPC menus/fallback/memory, validated shopping intents, actual enemy damage and directional player attacks, crypt gate checks, sigil drops, duplicate chests, all three elite encounters, boss phase transitions/defeat/reward, shrine unlocking, chapter quest completion, persisted ending, death interface and absent-Ollama timeout fallback.

The automated chapter test uses controlled positioning and direct damage to accelerate progression and inspect phases. It is an integration test of progression and state, **not** evidence of encounter balance, a full human playthrough, intended duration or controller usability. No tests were disabled or reported as passed without execution.

## Not yet verified

Native Apple Silicon launch, Gatekeeper behavior, real CoreAudio playback, physical gamepad input, real Ollama model responses, Retina readability, 60 FPS frame-time performance, Apple codesign/Gatekeeper validation, Developer ID signing/notarization and a complete unassisted playthrough. Follow `docs/SMOKE_TEST.md` on a Mac before treating the build as a release candidate.

The software-display capture logs report that V-Sync cannot be changed. This does not validate V-Sync or performance on macOS. Continuous sound is intentionally skipped for the Dummy-audio screenshot run. No known blocking script/runtime errors were observed in the final automated suite; untested behavior can still contain defects.
