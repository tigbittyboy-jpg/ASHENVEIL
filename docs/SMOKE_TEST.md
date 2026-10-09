# Manual release smoke procedure

This is the outstanding human playthrough checklist, not a completed test report.

1. On Apple Silicon macOS, extract the exported ZIP; verify it launches independently of Godot. Note Gatekeeper/signature behavior. Alternatively open `project.godot` with Godot 4.6.3.
2. New Adventure: move in all eight directions, block, dodge, sprint, hit village boundaries, pause/resume and try keyboard/mouse menus. Verify audio sliders by listening.
3. Visit all eight NPCs. Accept all five quests. Buy a dagger, equip it, sell an unequipped item, attempt an unaffordable purchase. Choose Mara’s wares, open Purchase, cancel, then confirm. Confirm nothing changes on cancellation.
4. Enter the forest. Fight both melee and ranged enemies, test potion and Ember. Gather three herbs and the Silver Charm; defeat sentinel and lost hound. Verify locked crypt denies entry before acquiring the sigil.
5. Return to town. Complete herb/iron quests and choose either charm outcome. Check changed Tovin dialogue. Upgrade a weapon and compare attack. Spend attributes and learn skills.
6. Enter the crypt, use checkpoint, avoid traps and defeat the elite knight. Fight Bellkeeper through all three phases without test shortcuts. Check readability, fairness and whether the chapter's length meets the intended scope.
7. Equip the boss reward, enter shrine and finish the chapter. Return to NPCs to hear the boss reaction. Revisit chests and quests to check rewards cannot repeat.
8. Save all three manual slots and autosave. Exit the application completely, relaunch and restore equipment, location, quest completion, memories, volume settings and boss defeat. Check death/respawn and backup recovery using a copy of a save, never the only original.
9. Navigate every dialogue with mouse, arrows/Enter and a connected gamepad. Check Back, Goodbye, Escape, service returns, and 800×450/normal/Retina resizing. No dialogue service or typing is required.
10. Record frame-time and memory on real Apple Silicon at normal and Retina resolutions. Sign/notarize a distribution candidate only after blocker-free completion.
