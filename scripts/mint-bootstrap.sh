#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NODE_VERSION="${NODE_VERSION:-16.20.2}"
DOTNET_SDK_LEGACY="${DOTNET_SDK_LEGACY:-2.1.818}"
DOTNET_CHANNEL_MAIN="${DOTNET_CHANNEL_MAIN:-8.0}"
PAKET_VERSION="${PAKET_VERSION:-9.0.0}"
DOTNET_ROOT="${DOTNET_ROOT:-$HOME/.dotnet}"
COMPAT_ROOT="${COMPAT_ROOT:-$HOME/.local/compat-libs}"
REF_DIR="${DOTNET_NET45_REF_DIR:-$HOME/.cache/dotnet-ref/v4.5}"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

install_nvm() {
  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  fi
  # shellcheck disable=SC1090
  . "$NVM_DIR/nvm.sh"
}

install_node_and_yarn() {
  nvm install "$NODE_VERSION"
  nvm alias default "$NODE_VERSION" >/dev/null
  nvm use "$NODE_VERSION" >/dev/null

  if ! command -v yarn >/dev/null 2>&1; then
    npm install -g yarn@1.22.22
  fi
}

install_dotnet_sdks() {
  local installer="/tmp/dotnet-install.sh"
  local dotnet_bin="$DOTNET_ROOT/dotnet"
  if [ ! -x "$installer" ]; then
    curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$installer"
    chmod +x "$installer"
  fi

  if [ ! -x "$dotnet_bin" ] || ! "$dotnet_bin" --list-sdks | grep -q '^8\.'; then
    "$installer" --channel "$DOTNET_CHANNEL_MAIN" --install-dir "$DOTNET_ROOT"
  fi

  if [ ! -x "$dotnet_bin" ] || ! "$dotnet_bin" --list-sdks | grep -q "^$DOTNET_SDK_LEGACY "; then
    "$installer" --version "$DOTNET_SDK_LEGACY" --install-dir "$DOTNET_ROOT"
  fi
}

install_paket_tool() {
  (
    cd "$HOME"
    export DOTNET_ROOT
    export PATH="$DOTNET_ROOT:$HOME/.dotnet/tools:$PATH"
    dotnet tool install -g paket --version "$PAKET_VERSION" >/dev/null 2>&1 || \
      dotnet tool update -g paket --version "$PAKET_VERSION" >/dev/null
  )
}

install_openssl_1_1() {
  if [ -f "$COMPAT_ROOT/usr/lib/x86_64-linux-gnu/libssl.so.1.1" ]; then
    return
  fi

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  (
    cd "$tmp_dir"
    curl -fsSLO http://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.24_amd64.deb
    dpkg-deb -x libssl1.1_1.1.1f-1ubuntu2.24_amd64.deb "$COMPAT_ROOT"
  )
}

install_gconf_compat() {
  if [ -f "$COMPAT_ROOT/usr/lib/x86_64-linux-gnu/libgconf-2.so.4" ]; then
    return
  fi

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  (
    cd "$tmp_dir"
    curl -fsSLO http://archive.ubuntu.com/ubuntu/pool/universe/g/gconf/libgconf-2-4_3.2.6-7ubuntu2_amd64.deb
    dpkg-deb -x libgconf-2-4_3.2.6-7ubuntu2_amd64.deb "$COMPAT_ROOT"
  )
}

install_net45_refs() {
  if [ ! -f "$REF_DIR/System.Runtime.dll" ]; then
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    (
      cd "$tmp_dir"
      curl -fsSLO https://api.nuget.org/v3-flatcontainer/microsoft.netframework.referenceassemblies.net45/1.0.3/microsoft.netframework.referenceassemblies.net45.1.0.3.nupkg
      mkdir -p "$REF_DIR"
      unzip -q microsoft.netframework.referenceassemblies.net45.1.0.3.nupkg "build/.NETFramework/v4.5/*" -d extracted
      cp -a extracted/build/.NETFramework/v4.5/* "$REF_DIR"/
      cp -a extracted/build/.NETFramework/v4.5/Facades/* "$REF_DIR"/
    )
  fi

  ln -sfn "$REF_DIR" "$ROOT_DIR/src/Main/v4.5"
  ln -sfn "$REF_DIR" "$ROOT_DIR/src/Renderer/v4.5"
}

main() {
  install_nvm
  install_node_and_yarn
  install_dotnet_sdks
  install_paket_tool
  install_openssl_1_1
  install_gconf_compat
  install_net45_refs

  # shellcheck disable=SC1091
  . "$ROOT_DIR/scripts/mint-env.sh"
  cd "$ROOT_DIR"
  yarn install
  dotnet restore src/Main/Main.fsproj -v minimal
  dotnet restore src/Renderer/Renderer.fsproj -v minimal

  echo
  echo "Bootstrap abgeschlossen."
  echo "Naechster Schritt:"
  echo "  ./scripts/mint-build.sh"
  echo "  ./scripts/mint-launch.sh"
}

main "$@"
