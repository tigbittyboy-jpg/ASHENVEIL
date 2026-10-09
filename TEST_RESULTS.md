# Test results — 0.3.0

Godot 4.6.3 Standard (official), Linux x86_64, 2026-10-09.

| Executed check | Observed result |
|---|---|
| `bash tools/cloud_setup.sh` | Editor import, isolated gameplay/UI/boss tests and audio checks completed without script/runtime errors |
| `tests/runner.tscn` | **125 passed, 0 failed** |
| `tests/ui_layout.tscn` | **166 passed, 0 failed** |
| `tests/boss_playtest.tscn` | Starter sword won in 22.9 simulated seconds / 34 attacks; 100 HP and three potions remaining; shrine reached |
| `tools/check_audio.py` | All seven loops/effects passed sample and boundary checks |
| Software-rendered screenshots | Actual village, forest, crypt, shrine, dialogue, journal and inventory renders inspected; 800×450, 1152×648 and 1600×900 captures |
| macOS export | Universal standalone development app, version 0.3.0, 64,493,947-byte ZIP |
| `tools/verify_macos_bundle.py` | x86_64 and ARM64 ad hoc CodeDirectories verified (23,123 / 21,622 code pages), Info.plist/CodeResources seals and six resource hashes verified; ZIP integrity passed |
| Exported content pack | Packaged `.pck` launched in headless Linux Godot without script/resource errors |
| Repository checks | `git diff --check` passed |

The gameplay suite covers inventory/transaction validation, equipment and upgrades, stats/skills/XP, exact quest consumption and reward uniqueness, both charm outcomes, legacy save restoration with relationships/progress intact, backup recovery, input movement, world collision, actual enemy damage, melee, sigil gates, chests, elites, boss phases/reward, shrine completion, death, stun resistance and dodge escape. It exercises authored dialogue links for every NPC, contextual greetings, quest acceptance/delivery, explicit purchases, forge/heal/inn services and returning to dialogue. No HTTP or typed-input controls remain in the runtime conversation path.

UI tests check 13 major interfaces at 800×450, 1152×648, 1600×900 and 1024×768: panel bounds, unclipped headings and button widths. They also check HUD bar separation, keyboard focus, arrow/Enter branch navigation, real mouse input, scrolling, Escape Back/close without reopening pause, and HUD/menu separation. Screenshots come from Xorg/Mesa software rendering with Dummy audio, not a mockup. The display logs the expected unsupported V-Sync-setting warning. Export logs missing desktop folder-opener helpers (`gio`/`kioclient5`/`gvfs-trash`); export and bundle verification nevertheless complete successfully.

The accelerated chapter integration test deliberately uses direct damage/positioning to inspect progression. The separate boss test uses collision-driven movement, real stamina and cooldowns with reactive dodging. It proves a viable strategy, not comfortable human balance, intended duration or a full unassisted playthrough.

Waveform measurements show zero boundary discontinuity for the 32-second music and ambience loops, with maximum adjacent sample differences of 100 and 37 (16-bit PCM). This checks clicks, not musical preference or actual CoreAudio output.

Native macOS launch, Gatekeeper acceptance, Apple's own `codesign` validation, CoreAudio listening, physical gamepad use, Retina readability, Apple Silicon frame times and a complete human playthrough remain unverified. The app is ad hoc signed, not Developer ID signed or notarized. Follow [the Mac smoke procedure](docs/SMOKE_TEST.md) for those device checks. Automated output is preserved in [docs/automated-test-output.txt](docs/automated-test-output.txt).
