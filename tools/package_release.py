"""Package desktop exports and a clean project; verify ZIP CRCs and record hashes."""
from pathlib import Path
import hashlib
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'downloads'
OUT.mkdir(exist_ok=True)
names = []
instructions = '''MNKISWAN: Cozy World — Days Together v0.4.0
Built with Godot 4.7.2. Extract the full ZIP before running the executable.
C switches Mnki / Swan on the ground. As Swan: F takeoff / landing, Space rise,
Ctrl descend, WASD steer, Shift fly faster. Release the controls to hover.
E interact, H Our days together / Village day, Tab inventory, J journal, M map.
Esc pause or finish a shared moment. Controls are remappable.
Children play, elders rest, farmers work and neighbours sleep at home.
Night market: 18:00-midnight. Vendor counters: 07:00-midnight.
Settings: 12/24/36/60-minute days (default 36), quiet HUD, quiet conversations.
Six gold sky-feather rings are marked on the map. No timer or stamina penalty.
13 gathering places, 39 activities, and 31 villagers. Teal diamonds on the map
mark gathering places. Journal > Village life tracks memories and friendship.
Stand quietly together for 35 seconds to hear Mnki and Swan chat. Moving or
opening a menu ends the conversation. Toggle quiet conversations in Settings.
Save in the pause menu. Airborne saves resume at the last safe ground position.
Linux: chmod +x MNKISWAN_Cozy_World.x86_64 if needed, then run it.
Windows: run MNKISWAN_Cozy_World.exe. Godot is not needed to play.
Source and updates: https://github.com/mnkiswan/mnkiswan_cozy_world
'''
for platform, executable, label in [('windows', 'MNKISWAN_Cozy_World.exe', 'Windows'), ('linux', 'MNKISWAN_Cozy_World.x86_64', 'Linux')]:
    binary = ROOT / 'builds' / platform / executable
    if not binary.is_file() or binary.stat().st_size < 10_000_000:
        raise RuntimeError(f'Missing or incomplete export: {binary}')
    name = f'MNKISWAN_Cozy_World_{label}_x64.zip'
    with zipfile.ZipFile(OUT / name, 'w', zipfile.ZIP_DEFLATED, compresslevel=8) as z:
        z.write(binary, executable)
        z.writestr('START_HERE.txt', instructions)
        for license_name in ['GODOT-LICENSE.txt', 'GODOT-COPYRIGHT.txt']:
            z.write(ROOT / 'docs' / license_name, license_name)
    names.append(name)

source = 'MNKISWAN_Cozy_World_Source_0.4.0.zip'
excluded = {'.git', '.godot', 'builds', 'downloads', 'export', '__pycache__'}
with zipfile.ZipFile(OUT / source, 'w', zipfile.ZIP_DEFLATED, compresslevel=8) as z:
    for path in sorted(ROOT.rglob('*')):
        rel = path.relative_to(ROOT)
        if path.is_file() and not excluded.intersection(rel.parts) and path.suffix not in {'.tmp', '.log'}:
            z.write(path, Path('MNKISWAN_Cozy_World_0.4.0') / rel)
names.append(source)
hashes = []
for name in names:
    path = OUT / name
    with zipfile.ZipFile(path) as z:
        if z.testzip() is not None:
            raise RuntimeError(f'ZIP integrity failed: {name}')
    hashes.append(f'{hashlib.sha256(path.read_bytes()).hexdigest()}  {name}')
    print(f'{name}: {path.stat().st_size / 1048576:.2f} MiB; ZIP integrity OK')
(OUT / 'SHA256SUMS.txt').write_text('\n'.join(hashes) + '\n')
