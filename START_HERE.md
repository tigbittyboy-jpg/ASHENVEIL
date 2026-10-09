# Play ASHEN VEIL

## Mac app — easiest download

1. [Download the macOS game ZIP](https://github.com/tigbittyboy-jpg/ASHENVEIL/raw/refs/heads/main/downloads/AshenVeil-macOS.zip).
2. Double-click the ZIP to extract **Ashen Veil.app**.
3. Move the app to **Applications**, then open it.
4. Choose **New Adventure**. Find **Captain Ilya** in the village's central square by the banner; accept **The Silent Bell**.

The app includes native Apple Silicon support. It needs no terminal, Godot installation, internet or Ollama. Version 0.2.0 is an ad hoc signed, unnotarized development build, and native Mac launch has not yet been tested. macOS may ask for approval: after attempting to open it, check **System Settings → Privacy & Security → Open Anyway**, if macOS offers that option and you trust this project. Do not disable system-wide security. If macOS reports the app damaged, use the recovery steps below or the Godot method.

## If macOS says the app is damaged

The original 0.1.0 upload had signing disabled. Replace it with the updated 0.2.0 ZIP above; it now contains verified ad hoc executable signatures and sealed app resources. Move the new app to **Applications**, replacing the old app. Existing saves live separately and are retained.

If you trust this repository's build but macOS still blocks it, open **Terminal** and paste this one-time command:

```sh
codesign --verify --deep --strict "/Applications/Ashen Veil.app" && xattr -dr com.apple.quarantine "/Applications/Ashen Veil.app" && open "/Applications/Ashen Veil.app"
```

The first step checks the signature using Apple's tooling. Only if it passes does the command remove the download quarantine flag from this one app and launch it. It does not disable Gatekeeper system-wide. Terminal can be closed afterward; it does not need to keep running. If signature verification fails, stop and report the displayed error; do not bypass that failure. No `sudo` should be needed for an app installed by your user.

Ad hoc signing is not Apple Developer ID signing or notarization. Actual Mac launch still requires your testing; cross-platform signature checks cannot prove Gatekeeper acceptance.

## Run with Godot — development fallback

1. Install [Godot 4.6.3 Standard for macOS](https://godotengine.org/download/macos/). Choose Standard, not .NET.
2. On this GitHub repository, choose **Code → Download ZIP** and extract it.
3. Open Godot, choose **Import**, and select `project.godot` inside the extracted `ASHENVEIL-main` folder.
4. Open the project and press **F5**, then **New Adventure**.

## Controls

**WASD** move · **Left click** attack toward cursor · **Space** dodge · **Right click** block · **Shift** sprint · **E** interact · **Q** healing potion · **F** magic · **I** inventory · **J** quests · **C** attributes/skills · **Esc** pause/save.

Speak to Mara to buy equipment, use I to equip it, and visit blue crystals to heal and autosave. Defeat the forest sentinel for the crypt key, then the Bellkeeper in the crypt. Enter the shrine to finish Chapter I. Use **Esc → Save and Return to Title** before exiting; choose **Continue Autosave** next time.

This is the first playable, with 100 passing automated checks. It is not yet the finished polished 30–60 minute release. See [README](README.md) for the walkthrough and limitations, and [TEST_RESULTS](TEST_RESULTS.md) for what was actually tested.
