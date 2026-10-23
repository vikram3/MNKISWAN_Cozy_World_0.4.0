# Validation — Days Together 0.4.0

Godot **4.7.2.stable.official.ed1daf0bf**, Compatibility renderer. Audit date: 23 October 2026.

## Automated gameplay

`./tools/test.sh` imports the project, loads every gameplay script/scene, then runs each scene with a temporary save directory. Nonzero exit codes and `SCRIPT ERROR` / `ERROR:` output both fail the runner.

- Parse/load: **93 files, 0 failures**.
- Original gameplay: **54 passed, 0 failed**.
- Flight and switching: **44 passed, 0 failed**.
- UI flow: **passed**.
- Living Village regression: **195 passed, 0 failed**.
- Daily life and shared moments: **117 passed, 0 failed**.

That is **410 gameplay assertions**, plus parse/load and UI-flow verification. See [test-results.txt](test-results.txt).

The new suite checks all 31 home assignments/routes and actual evening-to-home travel; sleeping visibility/collision; morning wake and stable household assignment when loading at night; catch, benches, fields, lunch, garden dates, swing seat height, opening boundaries and late-market activity. It checks both standing positions at all six shared locations, both-actor participation, movement/menu cancellation, switch guards, swapped speaker identity, airborne rejection, repeat-safe memories, panel-before-memory completion, save serialization, upper-floor support, walking all the way up the stairs and 30/120 FPS pose convergence.

Stair regression was checked against both colliders: the original rotated box blocked the walking approach; the replacement wedge allows the character to reach the upper landing without jumping. The test ends at local Z < 0 and Y ≥ 3.18, rather than accepting partial ascent as a pass.

Tests do not guarantee crowd behavior under every player-created blockage, complete malformed-save safety, or long-run performance. Remaining issues are explicit in [PROJECT_AUDIT.md](PROJECT_AUDIT.md).

## Rendered inspection

`tests/daily_gallery.tscn` captures the actual world at 1280×720 using Xorg and Mesa llvmpipe OpenGL. Captures cover park morning, garden couple, field work, 22:00 market, swing, a live shared garden ritual, and both tabs of the new panel. The ritual capture asserts that the interaction actually started. All images are in [the screenshot gallery](screenshots/DAYS_TOGETHER.md).

Visual inspection caught initial ritual positions inside ponds and an obstructed review-camera angle. Rituals were relocated to clear banks, partner-space checks were added, the review angle was changed, and the child's seat height was corrected. Existing character canon features remain; these captures do not claim production-quality art.

## Desktop exports and source archive

`./tools/build.sh` exports Windows x64 and Linux x64 with embedded PCKs, checks ZIP CRCs, and records SHA-256 digests in `downloads/SHA256SUMS.txt`. Matching **4.7.2** export templates are used. Windows execution cannot be tested in this Linux environment.

The packaged Linux `--verify-build` smoke checks actual scene loading, switching, airborne ascent, landing, 31 residents/39 activities, a completed activity, a shared ritual and the late-night sleep/market schedule. Its graphical mode also captures flight using the native exported binary. Source ZIP validation uses a fresh extraction and restored executable permissions; no existing `.godot` import cache is copied.

- Clean source extraction: the full suite passed (93 files, 410 gameplay assertions, UI flow).
- All 226 code, scene, test, tool, data and asset files compared byte-for-byte with the tested extraction; no differences.
- Windows and Linux exports completed with matching templates; ZIP CRC checks passed.
- Packaged Linux headless smoke: all switching, flight, activity, shared-moment and nighttime-schedule checks passed.
- Packaged Linux graphical smoke: **passed**, including all flight/activity/shared-life checks. The native flight screenshot is in the gallery.
- The final graphical log has the software-driver V-Sync warning, with no script errors or ObjectDB shutdown-leak warning in this run.
- Final archives are CRC-checked and accompanied by SHA-256 hashes. Published downloads are verified against these hashes after upload.
