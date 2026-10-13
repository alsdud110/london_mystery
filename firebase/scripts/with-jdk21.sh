#!/bin/sh
# Runs a command with a JDK 21+ (the Firestore emulator needs it), without
# changing the machine's default Java. Order: JAVA_HOME if it is 21+, the
# macOS java_home registry, then Homebrew's openjdk@21.
set -e
major() { "$1/bin/java" -version 2>&1 | sed -n 's/.*version "\([0-9]*\).*/\1/p' | head -1; }
ok() { [ -x "$1/bin/java" ] && [ "$(major "$1")" -ge 21 ] 2>/dev/null; }
if [ -n "$JAVA_HOME" ] && ok "$JAVA_HOME"; then :
elif h=$(/usr/libexec/java_home -v 21+ 2>/dev/null) && ok "$h"; then JAVA_HOME=$h
elif command -v brew >/dev/null && h="$(brew --prefix openjdk@21 2>/dev/null)/libexec/openjdk.jdk/Contents/Home" && ok "$h"; then JAVA_HOME=$h
else echo "Need JDK 21+ for the Firestore emulator (e.g. brew install openjdk@21)." >&2; exit 1
fi
export JAVA_HOME PATH="$JAVA_HOME/bin:$PATH"
# No update check: it writes to the user config dir after the run and can
# fail the exit code where that dir is not writable.
export NO_UPDATE_NOTIFIER=1
# The emulator run needs no login: firebase-tools keeps its settings in a
# throw-away folder, so a read-only or sandboxed home never fails the run.
XDG_CONFIG_HOME=$(mktemp -d)
export XDG_CONFIG_HOME
exec npx --no-install "$@"
