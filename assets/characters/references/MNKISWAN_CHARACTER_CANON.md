# MNKISWAN — OFFICIAL VISUAL CONSISTENCY REFERENCE

**Reference version:** 1.0 · Reviewed 22 October 2026

**Primary source:** User-provided `MNKISWAN_Sticker_Pack.zip` (`CHARACTER_GALLERY.jpg`, `STICKER_GALLERY.jpg`, transparent `characters/mnki/`, `characters/swan/`, `couples/`).

**Purpose:** Lock the visual identity of MNKI and Swan across Godot/Unity, stickers, UI portraits, game scenes, posters, storybooks, and AI-assisted art.
**Important:** This file is a durable reference document, **not** ChatGPT persistent Memory. ChatGPT Memory is disabled in this Project.

## Source inventory

- 22 numbered poses each for MNKI and Swan, plus mood aliases (`happy`, `calm`, `worried`).
- 53 numbered couple stickers.
- Two galleries and a manifest with pose sources and crop regions.
- The extracted WebP individual sprites contain alpha transparency and can be used as `Sprite2D`/`TextureRect` source references.
- The source files are the authority for *visual details*; previously supplied MNKISWAN written bibles remain references for personality, story, and values.

## 1 — MNKI / Monkey King (default everyday form)

**MUST KEEP**
- Enormous playful *chibi* silhouette: big rounded head, short body/limbs, expressive posture, warm rosy cheeks.
- Very full tousled, slightly spiky/fluffy dark brown hair, prominent bangs and flyaway tufts.
- **Golden double-curl/spiral headband** worn across the forehead, partly nestled into hair. Do not replace with a generic crown, plain band, or random jewelry.
- Big soft brown eyes and round friendly facial features. Warm tan/peach-brown skin shading as seen in sticker art; written descriptions say warm brown skin, so final palette should be manually approved rather than inferred from a verbal label.
- **Vivid red hoodie** with dangling dark drawstrings and the small **monkey-face chest emblem** visible in many standard stickers.
- Dark nearly black loose trousers with cargo-style pockets; chunky **red-and-white laced sneakers** with white toe caps and broad soles.
- Long **brown monkey tail with a conspicuous curved or curled tip**; keep its anatomy, position and visibility consistent unless hidden plausibly by staging.

**PERSONALITY VISIBLE IN POSE:** curious, kind, playful, mischievous-but-gentle, freely adventurous. Expressions may include bashful, happy, worried, sleepy, surprised, triumphant, crying, excited. The clothing/face/headband/tail should not morph to express emotion.

**Best everyday pose references:** `characters/mnki/mnki_pose_01.webp`, `mnki_pose_10.webp`, plus poses 02–17 and 19–22. `mnki_pose_18.webp` shows a sleep-themed variation (not standard daytime costume).

## 2 — SWAN / Swan Princess (default everyday form)

**MUST KEEP**
- Matching playful **chibi** proportions: oversized head, petite body, rosy cheeks, large expressive brown eyes and gentle features.
- **Very long, voluminous, thick, wavy/curly chestnut-to-dark-brown hair**, with bangs; reaches around or below her skirt in many stickers. This substantial hair volume is a key identifying silhouette. Avoid making it short, straight, blonde, or thin.
- **White swan-shaped hood** with a **bright orange beak on top**, dark simple swan-eye marks and **small golden crown** perched at the upper side/back. Crown and beak must be distinct and legible.
- **Small white feather wings** behind her shoulders/back, sometimes fanning outward. Wings may be partly hidden but should never vanish without staging reason.
- Cozy **white hoodie/top** with decorative drawstrings and round fluffy pom-pom ends in many normal illustrations; **short pleated pastel-pink skirt**.
- White socks and thick-soled **blue-and-white lace-up sneakers** with white toes.

**PERSONALITY VISIBLE IN POSE:** compassionate, thoughtful, observant, strategic, playful in safe moments, confident and individually motivated. She is not merely MNKI's guide or reward.

**Best everyday pose references:** `characters/swan/swan_pose_01.webp`, `swan_pose_10.webp`, plus poses 02–17 and 19–22. `swan_pose_18.webp` is a sleep-themed special outfit (not daytime costume).

## 3 — Couple identity and physical interactions

- When together, **both are equally prominent**. Keep relative chibi scale believable and consistent, and retain every key silhouette cue (his tail and headband; her hood, beak, crown, wings, and hair).
- Their interaction palette includes holding hands, shy smiles, laughter, hugging, cheek kisses, sitting together, cheering, comfort, sleep, surprise, and shared adventure. Avoid forced, submissive, or generic couple poses that reduce agency.
- Hand placement, foot perspective, tail path, hair overlapping wings, and contact points must look physically possible. Keep characters visually distinct even when hugging.
- Recommended couple references for default outfits: `couples/couple_001.webp` and most of `couple_002`–`couple_050`; check outfit and rendering consistency individually. `couple_051.webp` is wedding attire; `couple_052.webp` a different stylized romantic close-up; `couple_053.webp` a more detailed day-out design. They are **special scenes/style variations**, not authorization to redesign default characters.

## 4 — Approved visual language from THIS sticker pack

- **Illustrated 2D chibi sticker aesthetic**, not photorealistic, not generic anime characters, not 3D.
- Warm cream/white or transparent background, textured soft pastel fills, subtle painterly highlights, dark warm brown ink-like outlines and rosy blush.
- Large readable emotions, tidy face shapes, cohesive rendering of hair and cloth folds. Decorative hearts/sparkles/stars only when appropriate.
- For actual videogame sprites, simplify internal shading if necessary, **but retain silhouette / accessories / outfit / palette / hair mass / face structure**. Never let AI change their identities between sprite frames.

## 5 — Do / don't examples

**DO:** Use the same hair silhouette and headband for every MNKI expression; preserve Swan's enormous wavy hair and crowned beak-hood; show tail and wings; match outfit colors; use pose-specific expressions without changing anatomy.

**DON'T:** Swap the hoodie colors; give MNKI a generic monkey muzzle or Swan an actual long swan neck; remove tail or wings; shrink Swan's hair to shoulder length; move beak onto her face; turn her crown into MNKI's crown; drop monkey-face emblem where visible; invent extra companions; introduce inconsistent sneakers; use special wedding/sleep outfits as defaults.

## 6 — Conflicts or details that need owner approval

- Earlier written canon called MNKI's skin “warm brown”, while the sticker pack often shades it light warm tan/peach. **Do not silently repaint or rewrite character ethnicity/skin palette.** Match selected official sticker references pending an approved master color sheet.
- Earlier prose sometimes says Swan has a white top with a swan motif; these stickers more often depict a white hoodie with pom-pom tie ends, with no consistent large chest motif. Use the **sticker hoodie** for this pack's base design.
- Earlier canon describes the gold headband as curled; sticker pack distinctly depicts **two inward spirals**. Adopt this visual shape for sticker-matched assets.
- Some stickers vary outfit, hairstyle rendering, shading and detail density. Treat those as **variants**; never blend contradictory visual traits into a new default without approval.

## 7 — Game development integration

**Godot 4.x:** Keep full-resolution WebPs in `res://assets/characters/` (or convert losslessly to PNG if required); reference `Sprite2D` or `TextureRect`, preserve alpha, set `expand_mode`/scaling without stretching body ratios. Define a base sprite rig with reference anchors (top of head, eyes, shoulders, feet, tail and wing roots) and animate expressions by swapping equivalent-scale pose assets. Keep per-character pivots stable. Use original source or approved redraws, not random AI placeholders in final exports.

**Artwork generation:** Start every prompt with each character's locked visual spec. Supply `MNKI_reference_01.webp` and `SWAN_reference_01.webp` as image references whenever the generation tool supports that. Generate a neutral lineup first; compare against refs; only then generate poses/expressions/scene compositions. Review manual changes before import.

**QA before approving any image:**
1. Both identities instantly recognizable at mobile icon size?
2. MNKI gold **double swirl**, red monkey-emblem hoodie, curled brown tail present?
3. MNKI dark cargo pants and red-white sneakers match reference?
4. Swan orange-beak white swan hood and separate small gold crown present?
5. Swan long, dense wavy brown hair and white wings present?
6. Swan white pom-pom hoodie, pink pleated skirt, blue-white sneakers present?
7. Facial proportions, eye shapes, warm blush and outlines consistent?
8. Good hands, wings, tail attachment, hair overlap and physical contact?
9. Pose and mood support both characters' dignity and agency?
10. Is any alternate outfit or art style **explicitly marked as a variant**?

## 8 — Canonical AI art prompt (reference-lock template)

> Create an original warm 2D chibi-storybook illustration of the established characters MNKI and Swan using the **attached approved MNKISWAN sticker art** as visual source of truth. MNKI is a playful monkey-boy with huge tousled dark-brown hair, gold **double spiral** headband, warm tan-brown skin, brown eyes, rosy cheeks, red hoodie with small monkey-face chest emblem, loose dark cargo-style trousers, red-white sneakers and brown curled monkey tail. Swan is a thoughtful winged girl with oversized soft brown eyes, rosy cheeks, **very long and thick wavy chestnut-brown hair**, white swan hood with orange beak and small gold crown, visible white feather wings, cozy white pom-pom hoodie, pleated pastel pink skirt, white socks and blue-white sneakers. Match their chibi proportions, silhouettes, costume details and warm brown line work exactly. Keep them independent and equally important in the scene. [INSERT ACTION/SCENE]. Never redesign face, hair, clothing, headband, hood, crown, wings, tail or shoes. No extra protagonists, no realistic 3D, no unrelated visual style.

## Reference files in this kit

- `visual_references/MNKI_reference_01.webp` and `_10.webp`
- `visual_references/SWAN_reference_01.webp` and `_10.webp`
- `visual_references/Couple_reference_001.webp` and `_053.webp`
- `MNKISWAN_CONSISTENCY_CONTACT_SHEET.png` (quick side-by-side glance)
- `MNKISWAN_CHARACTER_LOCK.json` (machine-readable checklist)

For production, retain the original complete `MNKISWAN_Sticker_Pack.zip`; this smaller kit is a guide, not a replacement for the complete art archive.
