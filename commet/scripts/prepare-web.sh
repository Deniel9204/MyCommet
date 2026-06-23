#!/bin/sh -ve

# # Setup vodozemac
git clone https://github.com/famedly/dart-vodozemac.git .vodozemac
cd .vodozemac
git checkout 0.5.0
cargo install flutter_rust_bridge_codegen
# The wasm build uses -Z build-std, which needs the rust-src component on the
# nightly toolchain (build-web sets RUSTUP_TOOLCHAIN=nightly).
rustup toolchain install nightly
rustup component add rust-src --toolchain nightly
flutter_rust_bridge_codegen build-web --dart-root dart --rust-root $(readlink -f rust) --release
cd ..
rm -f ./assets/vodozemac/vodozemac_bindings_dart*
mv .vodozemac/dart/web/pkg/vodozemac_bindings_dart* ./assets/vodozemac/
rm -rf .vodozemac

# Setup livekit web worker
git clone https://github.com/commetchat/livekit-client-sdk-flutter.git .livekit
cd .livekit
git checkout hkdf

dart compile js web/e2ee.worker.dart -o ../web/e2ee.worker.dart.js -m
cd ..

rm -rf .livekit