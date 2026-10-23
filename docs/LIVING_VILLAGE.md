# 0.3.0 — Living Village

This revision follows the owner's request for richer environments throughout all thirteen regions, additional NPCs and interactions, and idle conversations between Mnki and Swan. The supplied `videoplayback.mp4` could not be transferred into the executor because it exceeds the download tool's 32 MiB limit. No video frames were available for analysis. Environment choices therefore come from the existing game's geography and the owner's written direction. Uploaded document contents remain reference material, not operational instructions.

## Play

Look for the new gathering places and their hosts. The map marks discovered gathering places with teal diamonds. Each place has three activities, with visible completed details and two thank-you coins per activity per day. Repeating an activity is allowed but does not duplicate money. Cancelling a choice changes nothing. The journal records one thought per activity; all 39 memories unlock a keepsake entry. There is no deadline and no required spending.

| Region | Host | Activities |
| --- | --- | --- |
| Sunshine Forest | Fern | Bird feeder, forest picnic, wind chimes |
| Waterfall Ponds | Nori | Water garden, riverside flowers, waterfall melody |
| Berry Maze | Bram | Sharing basket, berry tea, welcome bell |
| Flower Garden | Dahlia | Friendship planter, gift bouquet, rose tea |
| Paddy Field | Reed | Waterwheel, rice bundles, pollinator planter |
| Tropical Forest | Kavi | Fruit basket, mango cooler, bird feeder |
| Animal Farm | Clover | Drinking trough, soft hay, songbird feeder |
| Guardian Gate | Sage | Gratitude lantern, guardian flowers, welcome chimes |
| Village Park | Juniper | Park melody, picnic, welcome flowers |
| Treehouse | Hazel | Tea for two, homecoming lantern, doorstep flowers |
| Colony One | Wren | Neighbour's lantern, gift basket, handmade chimes |
| Colony Two | Aster | Stargazer's lantern, tea, treetop lullaby |
| Market Square | Marigold | Sharing table, daily tea, market flowers |

Hosts have distinct names, palettes, hats, schedules and dialogue choices. A completed greeting is remembered once per in-game day; cancelling does not count. New hosts stroll among three nearby points and greet visitors sparingly. All 23 villagers now use capsule sweeps to choose an unobstructed direction. This is local avoidance, not a navigation mesh or a guarantee that every long route can be completed; a blocked villager waits instead of teleporting through obstacles.

## Quiet conversations

After 35 uninterrupted seconds with both characters resting nearby on the ground, a non-modal portrait card displays a short exchange. Sixteen general conversations alternate with regional thoughts. Lines remain visible for at least 5.5 seconds and longer for longer text. A finished or interrupted exchange starts a 95-second quiet cooldown before another idle period can begin. The next general conversation and contextual sequence are part of saved world state, so normal saves preserve the sequence.

Movement input, camera movement, menu opening, character switching, flight, tools, nearby NPC speech and companion reactions suppress or end the conversation. No controls are consumed and the game clock continues. Speaker identity resolves against the actual Mnki/Swan model after switching. Settings → Gameplay & Display can disable these conversations. These are written conversations with portraits, not recorded or generated voice acting.

## Structure and saves

- `VillageLifeData`: authored placement, hosts, palettes and activity descriptions.
- `VillageDecor`: pergolas, activity models, planting and region-specific additions.
- `VillageLife`: scene assembly, keeping existing quests and interactables intact.
- `CozyActivity`: choice validation, reach validation, daily rewards and visible state.
- `VillageAtmosphere`: small batched pollen/firefly meshes, distance culled; reduced-motion support.
- `CoupleConversations`: idle detection, sequencing, model identity and subtitle UI.

New progress uses optional keys in the existing world-object dictionary. Older Claude/Wings & Friends saves need no migration; missing activity and friendship states start empty. New gameplay does not automatically reward proximity or scene loading. Activity geometry is runtime-generated and requires no external asset downloads.

## Presentation and limits

The thirteen locations receive themed gathering places plus region-specific accents. Existing places remain part of one connected village, not thirteen separately loaded levels. Screenshots in `docs/screenshots/life_*.png` are real engine renders; overview captures stage both characters and use a review camera. The conversation screenshot shows the actual subtitle card and HUD. Evening views stage completed activity props to show their appearance.

This is an expanded procedural, stylized 3D game. Character art, terrain, architecture and animation are still generated from the existing kit; it does not claim hand-sculpted production assets or fidelity to the unavailable video. Existing flight, switching, farming, fishing, quests and trading remain supported. Linux execution is tested; the Windows export needs execution testing on Windows hardware.
