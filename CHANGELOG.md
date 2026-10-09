# Changes

## 0.3.0 — Gothic graphics, compact UI and authored dialogue

- Replaced the low-detail actors, terrain and props with original detailed gothic art inspired by the supplied reference; added distinct village buildings, eight portraits, item icons, a chained Bellkeeper and 64 eight-direction player animation frames.
- Added the shared charcoal/bronze UI, compact resource HUD, pause controls/help, two-column quest journal, selectable inventory/equipment comparisons and focused shop confirmations. Headings remain outside scrolling content; menus hide the HUD.
- Removed typing, Send, parsing and all runtime AI/network conversations. Eight NPCs now use authored branching trees with conditional greetings, history, rumors, discoveries, quest choices and separate services that return to dialogue.
- Preserved version-one saves, relationships, once-only quest rewards, gameplay tuning and existing map collision/navigation. Obsolete AI preferences are safely discarded on load.
- Validated 125 gameplay/save/dialogue assertions and 166 UI/input/layout assertions, a starter-sword boss strategy and audio waveform continuity. Visually inspected software-rendered screenshots at three physical sizes; native Mac launch/audio remain outstanding.

## 0.2.0 — playtest fixes

- Replaced the short bass melody/drone with subdued 32-second minor chord and distant-bell loops. Loop boundaries match; effects have smooth attack/release envelopes and separate playback voices, so hits no longer cut off swings or menus.
- Replaced the village's house grid with a road-linked square, market, well, inn, forge, chapel/graveyard, cottage and ruined watchtower. Added darker world lighting with local warm lamps and a readable player halo. Forest trails now branch to ruins, a hound hollow and a flooded edge; crypt and shrine have distinct dressing. Flooded ground blocks movement.
- Fixed four-second stun. Stun now lasts 0.2 seconds, hit protection lasts at least 0.9 seconds, and repeated stuns are resisted for 2.5 seconds. Dodge breaks stun/slow and costs 18 stamina. Damage-over-time no longer applies repeated full hit reactions.
- Reduced normal enemy damage. Bellkeeper health 650 → 390; base attack 22 → 12, scaling to 16. Blast radius 145/100 → 82/64. Warnings remain 0.85–1.05 seconds; recovery remains 1.15–1.5 seconds. Six weaker wave projectiles replace twelve, and boss strikes no longer stun. Warnings stay anchored to their actual damage area.
- Conversation fields receive focus and support Enter or a Send button. Added distinct offline topics and NPC histories, quest/trade/service intent proposals, and confirmation before any proposed state change. Fixed a menu crash risk caused by freeing controls during their own signals.
- Centralized validated quest turn-ins, objective checks, exact item consumption and visible Crowns/XP receipts. Missing materials and completed quests now explain why a claim was rejected. Late main/elite quest acceptance recovers eligible rewards once. Returning an equipped charm safely unequips it; keeping it preserves equipment. Existing save schema remains compatible and unsafe positions relocate to open ground on map load.
- Expanded to 100 regression assertions, a starter-sword boss simulation and waveform boundary checks. Maintained built-in ad hoc signatures for the Mac app. Native Mac testing and subjective audio/encounter feedback remain user playtests.

## 0.1.1

Enabled and independently checked Godot's built-in ad hoc macOS signing after the damaged-app report. Added a guarded, app-specific quarantine recovery procedure.

## 0.1.0

Initial first playable and macOS development export.
