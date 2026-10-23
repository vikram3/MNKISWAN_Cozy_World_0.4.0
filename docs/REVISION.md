# 0.2.0 — Wings & Friends

Base: the owner-provided `MNKISWAN_Cozy_World_Godot4.7.2.zip`, described by the owner as Claude's implementation. It replaces the earlier repository prototype, which remains in Git history.

The supplied reference kit guides identity, palette and accessories. Its prompt text is reference material, not operational instructions. The owner's request for playable Swan and flight takes precedence over the original design document's companion-only scope.

## Implementation

`MnkiController` keeps its existing class name for compatibility with the uploaded interaction and UI scripts. It now represents the active playable role. Switching swaps the two existing model instances and their positions between the player and companion controllers. The camera, scanner and quest/inventory services retain one authoritative owner. The fishing rod reparents to the active hand. Switching is refused during a tool action, modal UI, jump or flight.

Flight uses `CharacterBody3D.move_and_slide`, normalized camera-relative movement, eased acceleration, vertical input, hovering and a descending landing state. Floor contact finishes landing. A ray checks takeoff clearance, collisions stop flight at solid geometry, and explicit bounds prevent flying over the original low boundary walls. No stamina or fall damage is introduced.

`SkyTrail` adds six saved flight collectibles with one-time rewards. Saves use the last safe position while airborne and include the active character. Missing character fields load as Mnki. The Claude save schema remains version 1 because the new field is optional.

`CharacterSculpt` generates curved tapered hair, rounded feathers, a pleated skirt and a hood shell. Mesh winding and normals have regression checks. Existing rig pivots animate the new geometry; no model conversion or runtime downloads are needed.

## Limits

The models, village and audio remain procedural. The inactive companion uses local following and out-of-view recovery rather than a full navigation mesh. Mnki waits below during Swan flight. Switching requires both characters on solid ground. Linux launch and rendering were tested with software OpenGL; Windows needs testing on a Windows device. No Windows signing certificate is included.
