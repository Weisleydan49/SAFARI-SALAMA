#!/usr/bin/env bash
set -euo pipefail

# Pick where Flutter will live
FLUTTER_DIR="${FLUTTER_HOME:-$HOME/flutter}"

# Install Flutter if missing
if [[ ! -x "$FLUTTER_DIR/bin/flutter" ]]; then
  echo "Installing Flutter SDK to $FLUTTER_DIR"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version

# Enable web and cache artifacts
flutter config --enable-web
flutter precache --web

# Dependencies and build
flutter pub get
flutter build web --release
