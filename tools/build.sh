#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p builds/windows builds/linux
./tools/godot.sh --headless --editor --import --quit
./tools/godot.sh --headless --export-release "Windows Desktop" builds/windows/MNKISWAN_Cozy_World.exe
./tools/godot.sh --headless --export-release "Linux Desktop" builds/linux/MNKISWAN_Cozy_World.x86_64
python3 tools/package_release.py
