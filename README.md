# Oneir — Flutter port

This is a real Flutter/Dart port of the approved React prototype, structured as
an actual buildable app (not another mockup), now with real native Android
functionality and a Firebase-based Co-Keeper backend layered in.

## Running it

```
flutter pub get
flutter run
```

For the full native + backend setup (permissions, the app-blocking service,
Firebase), see `android_native_files/SETUP.md` -- that's the real starting
point, since this project only has `lib/` and `pubspec.yaml` until you run
`flutter create .` and follow it through.

(Needs a connected device or emulator, and Firebase set up per SETUP.md, to
be fully functional -- this sandbox couldn't build/run or deploy any of it
directly, so treat this as a careful manual implementation rather than a
compiled-and-verified one. Run `flutter analyze` first thing to catch
anything a compiler would flag.)

## What's real

- The full onboarding -> home UI flow, all screens, all animations.
- Real OS permission requests (overlay, notifications, accessibility).
- The core app-blocking mechanism: an AccessibilityService that detects
  protected-app opens and launches a real interruption screen over them.
- A graduated, adaptive-by-attempt-count intervention (check-in ->
  intention check -> full Co-Keeper gate), per the Co-Keeper philosophy doc.
- A real Firebase-backed Co-Keeper request/approve/decline flow with push
  notifications.
- Real installed-app detection via PackageManager.
- Persistence across restarts (name, tasks, onboarding status, protected apps).

## What's still not finished

See the "What's still not fully finished" section at the bottom of
`android_native_files/SETUP.md` for the current, specific list -- it covers
things like the Co-Keeper inbox not having a navigation entry point yet and
the invite link using a placeholder domain. (The interruption/conversation
screen's Vanya artwork is no longer a placeholder -- real mouth-shape
photos are wired into `VanyaTalkingCharacter`; see SETUP.md for the small
honest gaps that came with that swap.)

## Structure

```
lib/
  main.dart                    -- app entry, Firebase init, startup gate,
                                   PageView-based onboarding flow
  theme/oneir_theme.dart        -- colors, text styles, design-canvas constants
  widgets/shared.dart           -- OneirScaffold (scales the design canvas to
                                    the real device size), buttons, bottom bar,
                                    idle-breathing animation
  screens/                      -- one file per screen or small group
  native/                       -- MethodChannel wrappers for permissions,
                                    the app-blocking data, and installed apps
  backend/                      -- Firebase-based Co-Keeper request logic and
                                    the local device-identity/pairing scheme
  interruption/                 -- the separate entrypoint + UI shown over a
                                    protected app when it opens
android_native_files/            -- native Kotlin/XML/manifest source to copy
                                    in (see SETUP.md)
functions/                       -- the Cloud Function that sends the
                                    Co-Keeper push notification
firestore.rules                  -- Firestore security rules
assets/images/                   -- all real, polished Vanya artwork/animations
```
