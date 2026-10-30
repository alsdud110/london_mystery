---
name: run-iphone
description: Run World Mystery on the user's wirelessly connected iPhone (device 00008150-00091D481EC0401C) via ./run_iphone.sh and keep the debug session alive. Use when the user types /run-iphone or asks to run/launch the game on their iPhone or real device ("아이폰에서 실행해", "실기기 실행").
---

# Run on iPhone

Launch the game on the user's iPhone with the project script. Do not edit
source code or assets, do not commit or push, and never kill other
processes (tests, Factory, the IDE's Flutter daemon, an existing run).

## Steps

1. From the project root `/Users/myhwang/flutter-workspace/world_mystery`,
   run `./run_iphone.sh` with the Bash tool **in the background**
   (`run_in_background: true`). `flutter run` stays attached for the whole
   debug session, so a foreground call would time out.
2. Read the background output once the build has had time to progress
   (an iOS build usually takes 1–3 minutes). Report one of:
   - `이미 ... 세션이 있습니다` → a session is already running; say so and stop.
     Do not start another and do not kill the existing one.
   - `오류: 아이폰 ... 찾지 못했습니다` → the phone was not found; relay the
     script's checklist (unlock the phone, same Wi-Fi, Xcode "Connect via
     network") and stop.
   - `Flutter run key commands` / `A Dart VM Service ... is available` → the
     app is running; tell the user the session is live.
   - Build or signing errors → report only the relevant error lines.
3. Leave the session running. When the user asks later:
   - hot reload: `kill -USR1 "$(cat .dart_tool/run_iphone.pid)"`
   - hot restart: `kill -USR2 "$(cat .dart_tool/run_iphone.pid)"`
   - stop: only on the user's request, stop that background task.

Reply in Korean.
