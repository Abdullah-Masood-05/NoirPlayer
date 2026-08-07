#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Creates the .env file that the Flutter build requires.
#
# WHY: pubspec.yaml declares `.env` as a bundled Flutter asset, so the file
#      MUST exist at build time or `flutter build` fails. `.env` is gitignored
#      (never commit API keys), so CI recreates it from GitHub Secrets.
#
#      The keys are optional at runtime — main.dart wraps dotenv.load() in a
#      try/catch — so empty values are perfectly fine. Fill the secrets below
#      to give the Discover/download module live API keys.
# ---------------------------------------------------------------------------
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

: > .env

for key in LASTFM_API_KEY YOUTUBE_API_KEY RAPIDAPI_KEY; do
  val="${!key:-}"
  printf '%s=%s\n' "$key" "$val" >> .env
done

echo "Wrote .env for the iOS build."
