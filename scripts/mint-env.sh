#!/usr/bin/env bash

NODE_VERSION="${NODE_VERSION:-16.20.2}"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  echo "NVM wurde nicht gefunden unter $NVM_DIR. Bitte zuerst scripts/mint-bootstrap.sh ausfuehren." >&2
  return 1 2>/dev/null || exit 1
fi

# shellcheck disable=SC1090
. "$NVM_DIR/nvm.sh"
nvm use "$NODE_VERSION" >/dev/null

export DOTNET_ROOT="${DOTNET_ROOT:-$HOME/.dotnet}"
export PATH="$DOTNET_ROOT:$HOME/.dotnet/tools:$PATH"
export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
export LD_LIBRARY_PATH="$HOME/.local/compat-libs/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH:-}"
export PaketExePath="${PaketExePath:-$HOME/.dotnet/tools/paket}"

unset ELECTRON_RUN_AS_NODE || true
