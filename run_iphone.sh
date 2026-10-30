#!/usr/bin/env bash
# Run World Mystery on the wirelessly connected iPhone and keep the debug session attached.
#
# Hot reload / restart from another shell while this runs:
#   kill -USR1 "$(cat .dart_tool/run_iphone.pid)"   # hot reload
#   kill -USR2 "$(cat .dart_tool/run_iphone.pid)"   # hot restart
set -euo pipefail

PROJECT_ROOT="/Users/myhwang/flutter-workspace/world_mystery"
DEVICE_ID="00008150-00091D481EC0401C"
PID_FILE=".dart_tool/run_iphone.pid"

cd "$PROJECT_ROOT"

# 1. Never start a second session. Only `flutter run` counts; the IDE daemon,
#    `flutter test` and other tools are left alone (and never killed).
if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
  echo "[run-iphone] 이미 실행 중인 세션이 있습니다 (pid $(cat "$PID_FILE")). 새로 실행하지 않습니다."
  exit 0
fi
existing="$(pgrep -f 'flutter_tools\.snapshot run' || true)"
if [[ -n "$existing" ]]; then
  echo "[run-iphone] 이미 flutter run 세션이 실행 중입니다 (pid: $(echo "$existing" | tr '\n' ' ')). 새로 실행하지 않습니다."
  exit 0
fi

# 2. Confirm the iPhone is visible (wireless discovery can take a while).
echo "[run-iphone] 아이폰 연결 확인 중 (최대 30초)..."
devices="$(flutter devices --device-timeout 30 2>&1 || true)"
if ! grep -q "$DEVICE_ID" <<<"$devices"; then
  echo "$devices"
  echo "[run-iphone] 오류: 아이폰($DEVICE_ID)을 찾지 못했습니다." >&2
  echo "[run-iphone] 아이폰 잠금 해제, 같은 Wi-Fi, Xcode의 'Connect via network' 설정을 확인하세요." >&2
  exit 1
fi
echo "[run-iphone] 아이폰 연결 확인됨."

# 3. Run and stay attached; the pid file enables duplicate checks and USR1/USR2 reloads.
rm -f "$PID_FILE"
trap 'rm -f "$PID_FILE"' EXIT
flutter run -d "$DEVICE_ID" --pid-file "$PID_FILE"
