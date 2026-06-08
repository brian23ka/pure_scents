#!/bin/bash

# Exit on error
set -e

# Clone Flutter (depth 1 for speed)
if [ ! -d "flutter" ]; then
  echo "Downloading Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
fi

# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

# Check Flutter version
flutter --version

# Enable Web
flutter config --enable-web

# Build
flutter pub get
flutter build web --release
