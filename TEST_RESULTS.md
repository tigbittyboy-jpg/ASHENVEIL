# Test results

Engine: Godot 4.6.3 Standard (official), Linux x86_64. Date: 2026-10-09.

## Executed checks

| Check | Observed result |
|---|---|
| `bash tools/cloud_setup.sh` | Completed successfully: editor import followed by isolated test scene |
| `godot --headless --path . res://tests/runner.tscn` | **100 passed, 0 failed** |
| Graphics scene capture | Village and boss arena rendered through Xorg/Mesa Compatibility renderer; screenshots under `docs/` |
| macOS export | Universal standalone app ZIP generated with official matching templates |
| Template integrity | Official SHA-512 checksum matched the downloaded template archive |
| Exported content pack launch | Packaged `.pck` launched in headless Godot on Linux without script/resource errors |
| Version 0.2.0 ad hoc signatures | Both native slices passed all CodeDirectory page-hash checks; Info.plist, CodeResources and six sealed resource hashes verified using `tools/verify_macos_bundle.py` |
| ZIP integrity | macOS and source archives passed ZIP integrity checks |
| App architecture | Mach-O contains ARM64 (`0x100000c`) and x86_64 slices; external `.pck` present |

The suite covers content counts, damage floors/blocking, invalid quantities, stacking, equipment ownership/stat effects, sales and purchases, insufficient currency, upgrades, consumables, XP, attributes, skills, quest reward uniqueness, save restoration/schema checks/backup recovery, input-driven movement, world collisions, NPC menus/fallback/memory, validated shopping intents, actual enemy damage and directional player attacks, crypt gate checks, sigil drops, duplicate chests, all three elite encounters, boss phase transitions/defeat/reward, shrine unlocking, chapter quest completion, persisted ending, death interface and absent-Ollama timeout fallback.

The automated chapter test uses controlled positioning and direct damage to accelerate progression and inspect phases. It is an integration test of progression and state, **not** evidence of encounter balance, a full human playthrough, intended duration or controller usability. No tests were disabled or reported as passed without execution.

## 0.2.0 playtest regression evidence

The checked setup script also completed the starter-sword boss simulation: 22.9 simulated seconds, 34 sword attacks, no potions used. It uses real collision-driven movement and normal stamina/cooldowns, then enters the shrine; it does not set boss HP or grant player health. Reactive automated dodging is more consistent than a human player, so this proves a viable avoidance strategy rather than comfortable human balance. The original accelerated chapter test still uses shortcuts to inspect persistence.

Additional tests exercise actual LineEdit Enter submission and NPC delivery button signals, visible reward receipts, exact material consumption, both charm outcomes with equipment integrity, duplicate prevention across save/load, late main/elite acceptance, stun expiration/resistance/dodge escape, accessible map interactions and blocked flooded terrain. The final run printed no script/runtime errors.

Waveform tests passed for all seven tracks/effects: music and ambient loops are 32 seconds with zero boundary discontinuity; maximum adjacent sample changes are 100 and 37 respectively (16-bit PCM). This detects waveform clicks, not listening quality or playback behavior on the Mac.

## Not yet verified

Version 0.2.0 native Apple Silicon launch, Gatekeeper behavior, real CoreAudio playback, physical gamepad input, real Ollama model responses, Retina readability, 60 FPS frame-time performance, Apple codesign/Gatekeeper validation, Developer ID signing/notarization and a complete unassisted playthrough. Follow `docs/SMOKE_TEST.md` on a Mac before treating the build as a release candidate.

The software-display capture logs report that V-Sync cannot be changed. This does not validate V-Sync or performance on macOS. Continuous sound is intentionally skipped for the Dummy-audio screenshot run. No known blocking script/runtime errors were observed in the final automated suite; untested behavior can still contain defects.
