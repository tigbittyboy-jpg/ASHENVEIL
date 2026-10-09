# Original gothic assets

The 0.3.0 art was generated for this project to follow the user's gothic pixel-art reference: worn gunmetal/crimson characters, expressive portraits, chained Bellkeeper, timber-and-stone buildings, warm lamps and dark textured terrain. The reference was used as visual direction; no sprite was cut from the user's reference image. Generated artwork needs future artistic refinement; it is not hand-drawn art.

Three original source atlases are committed under `assets/source/`: `gothic_atlas.png`, `terrain_atlas.png` and `player_animation_atlas.png`. Run `python tools/import_art.py` with Python/Pillow to reproduce game PNGs. The first atlas has manually inspected, unequal row boundaries; the terrain and animation atlases use equal grids. Transparent actor frames preserve a consistent scale and foot anchor, with nearest resampling. Sources are excluded from the standalone export.

- Player: 64×64 frames, eight directions (south, southwest, west, northwest, north, northeast, east, southeast). Eight action rows: idle, walk A/B/C, attack windup/sweep, dodge and hurt. All 64 frames are cached by the player controller. Sprint increases the walking frame rate.
- NPCs/enemies: detailed 64×64 sprites; boss and statue 128×128. Enemy animation remains procedural.
- Portraits: eight named NPCs, 128×128.
- Buildings: 256×192, with distinct inn, forge, chapel, cottage and tower art. Props use 96–128 pixel canvases; world draw sizes differ by function.
- Terrain: sixteen materials normalized to 48×48; a 192×192 ritual floor. Forest moss blends grass and leaf litter. These are textured materials, not a complete terrain edge/autotile set.
- Item icons: sword, dagger, axe, staff, bow, draught, iron and charm, 48×48. UI uses Godot's bundled font and shared charcoal/bronze StyleBoxFlat borders.

Committed PNG/WAV files need no Python or network at runtime. `generate_assets.py` retains the earlier procedural base/audio pipeline, then imports the detailed atlases last so regeneration does not revert the current graphics. The existing `refine_assets.py` retains the smooth 32-second minor-key music and ambient loops, short independent SFX voices and fixed seed. No external song or third-party game sprite was copied.

Audio is mono signed 16-bit PCM at 22,050 Hz. `check_audio.py` verifies adjacent samples and loop boundaries; this detects clicks, not musical preference. Headless/Dummy QA skips playback. Real CoreAudio listening remains a Mac playtest.
