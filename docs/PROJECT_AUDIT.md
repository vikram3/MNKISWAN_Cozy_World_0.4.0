# Project audit — Days Together 0.4.0

Audit date: 23 October 2026. Engine: Godot 4.7.2 stable, official build `ed1daf0bf`.

## Assessment

The project has a playable foundation: thirteen connected regions, both playable protagonists, Swan's flight, farming, fishing, animal care, trading, quests, decoration and saving. Its greatest weakness was that the daily-life fantasy was mostly described in dialogue rather than acted out. Villagers wandered between points, furniture was usually scenery, and the couple's activities were mostly solo interactions with rewards.

This revision adds a working daily routine layer and optional shared rituals. It is a stronger playable prototype, **not a finished commercial life simulation**. Final character art, deeper social behavior, accessible UI across devices, production audio and performance work remain substantial.

This report covers source review across gameplay, world construction, characters, UI, save/load, settings, audio and packaging; regression tests; new routine and interaction tests; and rendered scene inspection. It does not establish that every possible input sequence, save file, GPU or Windows configuration is correct. The attached GDD is used as a design reference, not as instructions overriding the owner's requests. Switching and flight remain, even though the GDD originally deferred switching.

## Fixed or implemented in this revision

| Finding | Change | Evidence / practical limit |
| --- | --- | --- |
| Villagers had no home/sleep state | All 31 residents have an assigned home, waking hours, destinations and sleep transitions | Walking-home test exercises all 31; home assignments stay stable on nighttime load; sleeping residents hide and cease blocking paths |
| Direct steering could not plan around the village | Shared collision-sampled A* ground grid; capsule sweeps and occupied-cell detours | Routes use actual static collision, rebuild after gate/bridge changes; complex crowds still need longer playtesting |
| Playground was mostly static | Poppy and Finn play catch, break for lunch, and Poppy uses the animated swing | Ball visibility follows arrival; swing and seated character move together |
| Benches had no everyday occupants | Pearl reads, Rowan and Elder Maple rest on park benches | Seated models use authored seat positions; book and elder spectacles improve readability |
| Flower garden lacked a resident couple | Nila and Arun tend flowers, spend afternoons together, then visit the market | They face each other and use affectionate gestures; their dialogue has distinct voices |
| Farmers did not visibly work/rest | Bao, Sumi, Ren and garden/farm residents have work, lunch and rest phases | Looping work gestures, handheld tools and bowls; decorative work does not secretly harvest the player's crops |
| Night market had no day/night identity | Lantern lighting, gathering residents, music/dance gestures, supper ritual and opening sign | Market hours 18:00–00:00; normal vendor counters 07:00–00:00; player's fruit stall remains self-service |
| Ordinary neighbours remained outdoors overnight | Children retire at 20:00; most adults at 21:00; market residents at midnight | Everyone remains free to walk home; the player is never forced to sleep |
| Activities rarely involved both heroes | Three anywhere rituals, six world locations, plus a children's catch invitation | Both actors animate; movement/Esc/menu cancellation restores control; proximity, ground and clear sight are checked |
| Affection could become another task list | Shared moments cost no coins, have no relationship penalties and can be repeated | A completed kind of moment records at most one memory per day; there is no daily target |
| Important features were hard to find | `H`: Our days together, with Together and Village day tabs; pink hearts on the map | Resident status/location, market hours, shared memories; normal modal focus and remappable controls |
| Pace was rushed | Default day extended from 12 to 36 real minutes | Settings offer 12/24/36/60; menus still pause time |
| HUD competed for attention | Quiet-HUD option, maximum three toasts, persistent Together shortcut and market status | Existing quest and interaction UI remains; large-text and unusual aspect ratios need more coverage |
| Animation interpolation varied with frame rate | Exponential blending for shared pose rig, movement blend, tail, hair, wings and companion turns | Constant-pose convergence checked at 30 and 120 FPS; no claim of artist-quality motion capture |
| Infinite looping actions used a zero-valued action envelope | Separate repeating envelope for continuous gestures | Farming, eating, play and affectionate gestures now keep moving |
| Seated legs bent in the wrong direction | Corrected seated pose direction | Procedural straight legs still lack bent-knee IK |
| Heroes ignored house collision layer 16 | Both hero and companion now include house collision | Upper-floor standing and stair traversal checks added; camera deliberately ignores that layer |
| Stair collision had an obstructing entry edge | Wedge collider joins the ground to the upper deck | Walking ascent tested without a jump |
| Sleeping advanced time without immediately announcing the new hour | Sleep now emits the hour and synchronizes routines under the fade | Existing crop/day behavior retained; loading reconstructs routines from saved time |
| New ritual sites could overlap water/scenery | Moved garden and pond rituals to clear banks | Both standing positions tested at all six locations; rendered inspection caught the initial placements |
| Reading the memory panel could create incomplete default state | Ritual completion reads optional memory fields safely | Panel-before-completion, cancellation, repeat and save round-trip tests |

## A day in the village

| Time | Daily life |
| --- | --- |
| 00:00–06:00 | Market closes; vendors and visitors walk home. Village residents sleep. Mnki and Swan can continue exploring, sit with the sky, or rest when they choose. |
| 06:00–07:00 | Early workers and elders wake; children and late-market residents sleep until 07:00. |
| 07:00–12:00 | Counters open. Children meet in the park, elders use benches, farmers work and Nila/Arun tend flowers. |
| 12:00–14:00 | Children and field workers pause for lunch. The garden couple spends time together. |
| 14:00–16:00 | Poppy takes a turn on the swing; afternoon work continues; benches and garden remain social places. |
| 16:00–18:00 | Field workers stop for rest and conversation. |
| 18:00–20:00 | Lantern market opens; ten designated vendors/visitors gather. Other neighbours have supper near home. |
| 20:00–21:00 | Children head home. The market stays open. |
| 21:00–00:00 | Most adults go home, while market vendors, musicians and visitors stay out until closing. |

The schedule is authored and repeats daily. Travel takes time: a villager can be on the way when the clock changes. Arrival is not an instant teleport during normal play. On load or deliberate overnight sleep, routines are placed at the current hour while the scene loads/fades. Household interiors are abstracted: residents fade at their doorway and sleep offscreen. This is not a simulation of visible beds inside every house.

## Remaining work, ordered by impact

### High priority: trust and usability

1. **Harden nested save validation.** The save manager verifies JSON, top-level structures and finite player positions, and protects a good backup. Nested inventory quantities, quest indices, shop orders and object-state fields remain only partly validated. A structurally valid but malformed edited save can still trigger a script error. Add typed validation/sanitization and malformed-save fixtures before a public release. Keep old-save compatibility explicit.
2. **Improve companion routing.** The partner still uses local follow steering and a recovery reposition, not the new full village A* routing. Tight furniture, stairs and long detours can reveal snapping or hesitation. Add grounded route following, collision-checked recovery destinations and explicit stair tests for the companion. Flying remains a solo ability: the other partner waits below.
3. **Protect unsaved progress on failures.** The pause menu's return-to-title/quit handlers do not stop on `save_game(false)`. Offer retry/stay/leave after a real disk failure. Add rotating save slots and a gentle periodic autosave; current saves are primarily event-triggered/manual/sleep saves.
4. **Finish accessibility and device coverage.** Keyboard/mouse controls are remappable. Full controller navigation, touch, screen-reader support, subtitles for spatial sound, colour-blind distinctions and high text-scale reflow are not complete. Test 16:9, 16:10, ultrawide and a small laptop display at maximum text size.
5. **Long-run routine testing.** A full-village trip home passes in the test scene, but emergent crowd congestion, the player standing in doors, newly obstructed routes, save/load mid-conversation and many consecutive days need soak testing. Ground grid routing is not a replacement for navigation meshes and multi-level links when interiors expand.

### High priority: character and visual finish

6. **Replace hero meshes with production rigs.** Current Mnki/Swan preserve the signature hair, headband, hood/beak/crown, hoodie colours, skirt, shoes, tail and wings, but are code-built component meshes. Use approved turnarounds, retopology, skinning, facial blend shapes, material atlases and distance LODs. Keep the character consistency kit as the review reference.
7. **Author joint interactions.** Current shared rituals are synchronized gestures while standing nearby. They are not precise hand-holding, hugs, kissing, cuddling in bed, seated feeding or hand-to-object animation. Add paired animation clips, contact anchors, foot/hand IK and safe approach/exit paths. Do not label these future actions as already implemented.
8. **Improve environmental composition.** The world is still a flat diorama with repeated primitive trees/buildings, broad empty lanes and simplified water. Add gentle terrain contours, distinct house silhouettes, layered vegetation, textured materials, believable farm work areas and deliberate views between landmarks. Preserve clear walking space; every new prop needs collision/interaction review.
9. **Make the night market more than a gathering.** Present build has open vendors, visitors, lights, supper and dancing gestures. Add actual food stalls, cooking/steam, vendors passing items, queues, busker audio, seating groups and closing/clean-up animation. Menus and scripted gestures alone cannot provide the full sense of commerce.

### Medium priority: depth without pressure

10. **Give residents relationships and continuity.** Names, voices and schedules exist; autonomous conversations, family relationships, remembered gifts/preferences, varied weekday routines and event reactions are limited. Add a small number of well-written relationships before adding more generic residents.
11. **Develop children's play.** Catch and one swing routine exist. The invitation lets the couple join with a short animation/dialogue, not a ball-physics skill game. Add turn-taking, hopscotch, hide-and-seek and a playground gathering with clear safeguards against path congestion.
12. **Build enterable homes and a fuller home life.** Neighbour houses are exterior shells. Mnki/Swan's treehouse has two floors, storage, decoration and sleeping, but cooking, washing dishes, tending indoor plants, changing clothes and getting into bed together need distinct interactions/animations.
13. **Broaden peaceful shared activities.** Add cooperative planting/watering/harvesting, picnic placement, choosing meals, gifting found objects, sitting side by side, watching weather, photographs and a memory album. Keep all optional; no affection meter that decays when the player rests or leaves.
14. **Vary conversations.** Idle dialogue covers love, kindness, wisdom and places; it remains a finite authored set. Add time/weather/quest/memory-aware selection and longer repeat avoidance. Keep lines character-specific and interruptible. No need for an online language model.
15. **Review economy after the slower clock.** Crop growth remains tied to mornings, and activity rewards remain once per day. A 36-minute day changes progression speed. Test whether seeds, stall tiers and repairs feel generous without making every lovely moment a currency source. Do not add debt or loss pressure.
16. **Diversify requests.** Existing quests exercise multiple systems, but much interaction is button/dialogue driven. Add a few social quests with visible village consequences and fewer repeated fetch steps. New everyday residents do not each have an authored quest arc yet.

### Medium priority: production engineering

17. **Budget scene complexity.** All thirteen regions are constructed together. There are many individual procedural mesh nodes, character parts and always-active updates. Add distance-based animation updates, mesh batching, shared materials/atlases, LODs and regional streaming after profiling a target laptop. The startup navigation bake is synchronous; move to authored/cached navigation for larger worlds.
18. **Replace placeholder sound.** Music, ambience and effects are synthesized placeholders. Add authored day/night stems, footstep surfaces, local birds/water, market crowds and interaction cues. The musician currently dances without a dedicated instrument performance track.
19. **Improve content workflow.** Region geometry and routines are largely GDScript-authored. Designers need editable scenes/resources, visual schedule/seat/path tools and validation for unreachable interactions. Separate content data from presentation as the cast grows.
20. **Release qualification.** Linux execution is tested here; Windows is exported but not executed in this environment. Add real Windows testing, hardware performance captures, controller tests, install/uninstall/save-location instructions, crash reporting policy, accessibility review and Steam packaging when distribution is planned. Code signing and store release are not part of this revision.
21. **Retain teardown coverage.** The v0.3 native renderer smoke produced ObjectDB leak warnings at shutdown. The final v0.4 graphical smoke did not reproduce that warning. Keep repeated world/title transitions and longer-run leak testing on the release checklist; one clean exit is not proof of leak-free teardown.

## Systems reviewed

| Area | Present state | Primary files |
| --- | --- | --- |
| Character ownership / movement / flight | One input owner; model swap; grounded switching; controlled flight, ceiling/bounds/landing checks | `scripts/player/mnki_controller.gd`, `scripts/player/camera_rig.gd` |
| Partner / quiet dialogue / rituals | Follow/wait/recover; nonmodal idle conversations; cancellable shared rituals | `scripts/companion/` |
| NPC life / navigation | 31 residents, home schedules, local collision checks, shared A* ground routes | `scripts/interactables/npc_character.gd`, `scripts/world/daily_life.gd`, `scripts/world/village_navigation.gd` |
| World / environment | 13 regions, shared scenery kit, gathering areas, day/night lighting and atmosphere | `scripts/world/`, `scripts/art/env_kit.gd`, `scripts/art/village_decor.gd` |
| Farming / gathering / animals / fishing | Existing playable systems retained; daily growth/care and fishing state tested | `scripts/interactables/`, `scripts/data/game_data.gd` |
| Economy / stock / quests | Inventory, storage, transactions, stall upgrades/orders, data-driven quest definitions | `scripts/systems/`, `data/quests/` |
| Persistence / clock | Versioned JSON, temporary-file verification, good-save backup, explicit day/hour signals | `scripts/core/save_manager.gd`, `scripts/core/time_manager.gd` |
| UI / settings | HUD, inventory, journal, map, dialogue, pause, shops, storage, new Together/Village day panel | `scripts/ui/`, `scripts/core/settings.gd` |
| Characters / animation | Procedural chibi meshes and pivot animation; revised smoothing and daily poses | `scripts/art/` |
| Audio | Original synthesized placeholder music/ambience/SFX, separate volume buses | `scripts/core/audio_manager.gd` |
| Build / testing | Exact engine wrapper, headless regression runner, Windows/Linux embedded-PCK exports, ZIP/hash verification | `tools/`, `tests/`, `export_presets.cfg` |

## Design reference gaps

The GDD's Appendix A explicitly calls for production-ready rigged hero models, polished animation and portrait sets. The current procedural characters do **not** satisfy that final-art requirement. Its scope includes a coherent opening arc and bounded crop/fish/animal/quest content; the project has implementations of those systems, but content count alone does not establish release quality. The new eight residents were added to fulfil concrete everyday roles, rather than to claim completion through a larger NPC count.

The original video attachment could not be inspected because the transfer tool rejected its size. No visual fidelity claim is made about scenes from that video. The character canon files and the existing thirteen-region design were available as references.

## Recommended next production slice

Finish one excellent shared evening: walk home together through a lively closing market, make a meal, sit on the sofa, talk naturally, and go to bed together. Use final-quality Mnki/Swan rigs and one polished home/market route. Validate camera, companion routing, contact animation, UI, sound, saving and performance there before expanding the same quality across all thirteen regions.

See [validation](VALIDATION.md) for commands and results, [daily-life controls](DAYS_TOGETHER.md), and [rendered screenshots](screenshots/DAYS_TOGETHER.md).
