#!/usr/bin/env bash

set -euo pipefail

project_directory="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
database_name="trigo.sqlite3"
temporary_database="$project_directory/$database_name.tmp"
exported_database="$project_directory/$database_name"
adb_command="$(command -v adb || true)"

if [[ -z "$adb_command" && -x "$HOME/Library/Android/sdk/platform-tools/adb" ]]; then
  adb_command="$HOME/Library/Android/sdk/platform-tools/adb"
fi

if [[ -z "$adb_command" ]]; then
  echo "adb was not found. Add Android platform-tools to PATH and try again." >&2
  exit 1
fi

trap 'rm -f "$temporary_database"' EXIT

"$adb_command" exec-out run-as com.example.trigo cat "databases/$database_name" > "$temporary_database"
mv "$temporary_database" "$exported_database"
trap - EXIT

echo "Database exported to $exported_database"
