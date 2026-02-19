#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Führt den vollständigen Mint-Flow in einem Schritt aus:
# 1) Toolchain + Kompat-Libs prüfen/installieren
# 2) Build
# 3) App starten
bash "$ROOT_DIR/scripts/mint-bootstrap.sh"
bash "$ROOT_DIR/scripts/mint-build.sh"
bash "$ROOT_DIR/scripts/mint-launch.sh"
