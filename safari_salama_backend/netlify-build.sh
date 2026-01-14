#!/usr/bin/env bash
set -euo pipefail

FLUTTER_DIR="${FLUTTER_HOME:-$HOME/flutter}"

if [[ ! -x "$FLUTTER_DIR/bin/flutter" ]]; then
  echo "Installing Flutter SDK"
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter config --enable-web
flutter precache --web

cd safari_salama

flutter pub get
flutter build web --release
