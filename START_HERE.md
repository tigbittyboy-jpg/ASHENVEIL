# Play ASHEN VEIL

## Mac app — easiest download

1. [Download the macOS game ZIP](https://github.com/tigbittyboy-jpg/ASHENVEIL/raw/refs/heads/main/downloads/AshenVeil-macOS.zip).
2. Double-click the ZIP to extract **Ashen Veil.app**.
3. Move the app to **Applications**, then open it.
4. Choose **New Adventure**. Find **Captain Ilya** in the village's southern row of houses; accept **The Silent Bell**.

The app includes native Apple Silicon support. It needs no terminal, Godot installation, internet or Ollama. It is an unsigned/unnotarized development build, and native Mac launch has not yet been tested. macOS may ask for approval: after attempting to open it, check **System Settings → Privacy & Security → Open Anyway**, if macOS offers that option and you trust this project. Do not disable system-wide security. If macOS reports the app damaged or refuses it, use the Godot method below and report the exact message.

## Run with Godot — development fallback

1. Install [Godot 4.6.3 Standard for macOS](https://godotengine.org/download/macos/). Choose Standard, not .NET.
2. On this GitHub repository, choose **Code → Download ZIP** and extract it.
3. Open Godot, choose **Import**, and select `project.godot` inside the extracted `ASHENVEIL-main` folder.
4. Open the project and press **F5**, then **New Adventure**.

## Controls

**WASD** move · **Left click** attack toward cursor · **Space** dodge · **Right click** block · **Shift** sprint · **E** interact · **Q** healing potion · **F** magic · **I** inventory · **J** quests · **C** attributes/skills · **Esc** pause/save.

Speak to Mara to buy equipment, use I to equip it, and visit blue crystals to heal and autosave. Defeat the forest sentinel for the crypt key, then the Bellkeeper in the crypt. Enter the shrine to finish Chapter I. Use **Esc → Save and Return to Title** before exiting; choose **Continue Autosave** next time.

This is the first playable, with 57 passing automated checks. It is not yet the finished polished 30–60 minute release. See [README](README.md) for the walkthrough and limitations, and [TEST_RESULTS](TEST_RESULTS.md) for what was actually tested.
