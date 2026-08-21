# Wiring in the native + backend code

This covers everything native/backend: OS permissions, the core app-blocking
mechanism, real installed-app detection, and the Firebase-based Co-Keeper
backend.

**Steps 1-3 below (scaffolding + copying native files + manifest merge) are
now automated** by `tool/wire_native.py`, and `.github/workflows/build-apk.yml`
runs the whole thing -- including step 1 -- on every push, or on demand from
the Actions tab ("Run workflow"). If you're building via that workflow (or
`codemagic.yaml`, also updated to call the same script), you can skip
straight to "4. Set up Firebase" below; there's nothing left to do by hand
for the native side. The manual steps are kept here for local development
without CI, and because that's what `tool/wire_native.py` itself is
mechanically doing -- useful if something needs debugging.

## 1. Generate the native scaffolding (one-time)

```
flutter create . --platforms android --org com.oneir --project-name app
flutter pub get
```

Safe to run on an existing project -- fills in missing platform folders
without touching `lib/` or `pubspec.yaml`. The `--org`/`--project-name`
values matter: together they're what makes the generated Android
`applicationId` come out as `com.oneir.app`, matching the `package
com.oneir.app` line at the top of every file under `android_native_files/`.
Using different values here means those files need their package
declarations (and folder placement in step 2) updated to match instead.

## 2. Copy in the native Kotlin files

All paths below are relative to `android/app/src/main/`.

| From (this folder)                              | To                                                                 |
|---------------------------------------------------|---------------------------------------------------------------------|
| `kotlin/MainActivity.kt`                          | `kotlin/<your/package/path>/MainActivity.kt` (replace the generated one) |
| `kotlin/OneirAccessibilityService.kt`             | same `kotlin/<your/package/path>/` folder                          |
| `kotlin/InterruptionActivity.kt`                  | same `kotlin/<your/package/path>/` folder                          |
| `xml/oneir_accessibility_service_config.xml`      | `res/xml/oneir_accessibility_service_config.xml` (create the `xml` folder) |

Check the `package com.oneir.app` line at the top of each `.kt` file matches
whatever package `flutter create .` actually used -- update all three if
different.

## 3. Update AndroidManifest.xml and strings.xml

- Add everything in `AndroidManifest_additions.xml` into
  `android/app/src/main/AndroidManifest.xml`, in the places commented
  (permissions, `<queries>`, the service, the activity, the Dart-entrypoint-args
  meta-data).
- Add the string from `xml/strings_additions.xml` into
  `android/app/src/main/res/values/strings.xml`.

## 4. Set up Firebase (needed for the real Co-Keeper backend)

1. Create a project at [console.firebase.google.com](https://console.firebase.google.com)
   if you don't have one.
2. Install the FlutterFire CLI and run it from the project root:
   ```
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
   This generates `lib/firebase_options.dart` and wires up the Android app
   automatically -- pick the project you just created, and Android as the
   platform.
3. In the Firebase Console, enable **Firestore** (start in production mode)
   and **Cloud Messaging**.
4. Deploy the security rules and the Cloud Function:
   ```
   npm install -g firebase-tools
   firebase login
   firebase init firestore functions   # point it at the existing firestore.rules and functions/ folder in this project
   firebase deploy --only firestore:rules,functions
   ```
   The Cloud Function requires the Blaze (pay-as-you-go) plan -- the free
   Spark plan doesn't support Cloud Functions. Firestore itself has a free
   tier that's plenty for testing.
5. `lib/main.dart` already calls `Firebase.initializeApp()` and registers
   the device for push on startup -- once `firebase_options.dart` exists,
   it'll just work.

**If you're building via GitHub Actions or Codemagic (no local
`flutterfire configure`)**, there's a lighter path that doesn't require
running the FlutterFire CLI at all: in the Firebase Console, under Project
settings -> General -> "Your apps", add an Android app with package name
**exactly `com.oneir.app`**, download the `google-services.json` it gives
you, and commit it to this repo at:

```
android_native_files/google-services.json
```

`tool/wire_native.py` looks for it at exactly that path. If it's there, the
script automatically copies it to `android/app/google-services.json` and
adds the Google Services Gradle plugin to `android/settings.gradle(.kts)`
and `android/app/build.gradle(.kts)` -- both the plain-Groovy and
Kotlin-DSL flavors of those files are handled, and re-running the script is
safe (it skips wiring that's already there). If the file isn't committed
yet, the script just skips this step and prints a note -- the app still
builds fine, Firebase features stay off until you add it. You still need
Firestore + Cloud Messaging enabled and the Blaze plan active per steps 3-4
above; `google-services.json` alone only gets the Android app registered
with the project.

## 4b. Set up Vanya's real AI backend (decideIntervention)

Vanya's conversation -- both during a real protected-app interruption and
in the onboarding "Try it now" demo -- is driven by an actual LLM call,
not a keyword list or fixed script. Every free-text reply the user types
or speaks is sent through this pipeline and gets a fresh, specific
response. There are two ways to wire the model call up; use the first one
for anything you intend to actually ship:

**Option A -- Cloud Function proxy (recommended).** The API key never
touches the compiled app.

1. Get an Anthropic API key from [console.anthropic.com](https://console.anthropic.com).
2. Store it as a Firebase secret (not in any committed file):
   ```
   firebase functions:secrets:set ANTHROPIC_API_KEY
   ```
3. Deploy the function (same Blaze-plan requirement as the Co-Keeper
   push-notification function above):
   ```
   cd functions && npm install && cd ..
   firebase deploy --only functions:decideIntervention
   ```
4. Build/run the app with:
   ```
   flutter run --dart-define=AI_PROVIDER=cloud
   ```
   That's the only flag needed -- no key goes on the client side at all.
   See `functions/intervention.js` for the function itself and
   `lib/intervention/ai/cloud_function_provider.dart` for the Dart side
   that calls it.

   `.github/workflows/build-apk.yml` and `codemagic.yaml` already pass
   `--dart-define=AI_PROVIDER=cloud` on their build step, so a CI-built APK
   is wired for this automatically -- you only need to do steps 1-3 above
   (get the key, set the secret, deploy the function) for it to actually
   start working. Until the function is deployed, those CI builds still run
   fine; the callable call just fails per-message and
   `CloudFunctionInterventionProvider` falls back to its own honest
   "having trouble thinking" clarify reply instead of a real model answer.

**Option B -- direct provider call, for quick local testing only.** Skips
deploying anything, but the key ships inside whatever build you run this
on, which is not safe beyond your own device:
```
flutter run --dart-define=AI_PROVIDER=anthropic --dart-define=AI_API_KEY=sk-ant-...
```
`AI_PROVIDER` also accepts `openai` and `gemini` the same way (see
`lib/intervention/ai/ai_provider_config.dart`). Leaving `AI_PROVIDER`
unset (or setting nothing) falls back to `OfflineHeuristicProvider` --
the app still runs and the onboarding demo still works, just with a much
simpler non-AI decision rule instead of a real model call.

## 4c. On-device Gemma 4 E2B (proof-of-concept, separate from 4b)

Independent from everything in section 4b: `lib/local_ai/` is a from-scratch
proof-of-concept that Vanya could eventually run *entirely on the device*,
via Google's Gemma 4 E2B model through the LiteRT-LM runtime, with **no
cloud AI call, no API key, and no server** at inference time -- the only
network traffic involved is the one-time ~2.6GB model file download.

This is not wired into the real intervention pipeline
(`lib/intervention/`) or the `decideIntervention` Cloud Function from 4b --
those are unrelated and unaffected. It's reachable from a standalone dev
screen: Settings -> "Vanya AI (on-device, dev)".

**Setup required:** none, by design -- no account, no key, no secret to
set. Open the app, go to that Settings entry, tap "Load model". The first
load downloads `gemma-4-E2B-it.litertlm` (~2.6GB) from
`litert-community/gemma-4-E2B-it-litert-lm` on Hugging Face, a mirror that
doesn't gate the download behind a login/click-through -- see
`lib/local_ai/model_info.dart` for the license caveat on that (short
version: treat it as still governed by Google's Gemma Terms of Use even
though this particular mirror's own page doesn't force a click-through).

**Device requirements** (hard requirement, not a suggestion):
Android 11 (API 30) or newer, 64-bit CPU (arm64-v8a). `tool/wire_native.py`
raises the generated `android/app/build.gradle(.kts)`'s `minSdk` to 30
automatically (`wire_gemma_min_sdk()`) -- below that, the native
`libLiteRtLm.so` library flutter_gemma_litertlm depends on can't load at
all. 6GB+ total device RAM is recommended, not enforced (Flutter has no
built-in cross-device RAM-detection API without another native plugin, so
this is guidance shown in the test screen, not a runtime check).

**Architecture**, if you want to extend or swap the model later:
```
Vanya UI (VanyaAiTestScreen today)
   |
VanyaAiService     -- lib/local_ai/vanya_ai_service.dart (status tracking,
   |                   one shared loaded-once model instance)
VanyaAiProvider     -- lib/local_ai/vanya_ai_provider.dart (interface)
   |
LocalGemmaProvider  -- lib/local_ai/local_gemma_provider.dart (the ONE file
   |                    that calls flutter_gemma directly)
Gemma 4 E2B
```
Everything above `LocalGemmaProvider` only knows about the
`VanyaAiProvider` interface -- swapping Gemma 4 E2B for a different local
model means writing one new class, not touching the UI or the service.

**Verification status -- read this before trusting the code compiles.**
This was written in a sandboxed environment with no network path to
pub.dev and no `flutter`/`dart` binary installed, so `flutter pub get`,
`flutter analyze`, and `flutter build` could **not** be run against it here.
The `flutter_gemma`/`flutter_gemma_litertlm` API calls in
`local_gemma_provider.dart` were pieced together from that package's
current pub.dev listing, changelog, and official docs site (fluttergemma.dev)
rather than verified by compiling against it. Every call into that package
is isolated in that one file specifically so that if a method name or
parameter turns out slightly different once you actually run
`flutter pub get`, the fix is small and localized. **First thing to do on
a machine with real Flutter tooling:** `flutter pub get && flutter analyze
lib/local_ai lib/screens/vanya_ai_test_screen.dart` and fix whatever the
compiler flags -- treat this as researched-but-uncompiled code, not
verified-working code.

## 5. Rebuild

```
flutter pub get
flutter run
```

## What's real now

- **`OneirAccessibilityService`** detects protected-app opens system-wide
  (event-driven) and launches a real interruption screen on top of them.
- **The interruption screen is graduated**, per the Co-Keeper philosophy
  doc: 1st same-day attempt on an app shows a simple check-in, 2nd shows an
  intention/five-more-minutes check, 3rd+ escalates to the full Co-Keeper
  gate. Attempt counts and today's intention (pulled from your first
  unchecked Widgets task) are both real and persisted.
- **"Request Key" sends a real Firestore request** to your paired Co-Keeper,
  who gets a real push notification and can Approve/Decline from the
  `CoKeeperInboxScreen` (not yet wired into app navigation -- see below) on
  their own device. The requester's screen updates live when they respond.
- **Protected Apps** now shows your phone's actual installed, launchable
  apps (with real icons) via `PackageManager`, not a hardcoded list.
- **Persistence**: your name, Widgets task check-state, and onboarding
  completion all survive an app restart -- a returning user goes straight to
  Home instead of sitting through onboarding again.
- **Display Over Apps / Notifications** trigger real OS permission dialogs.
- **Accessibility** sends you to real Settings and auto-detects when enabled.

## What's still not fully finished

- **On-device Gemma 4 E2B (`lib/local_ai/`) is a proof-of-concept only,
  and unverified by compilation** -- see section 4c above. It's isolated
  behind `VanyaAiService`/`VanyaAiProvider` and reachable from a dev
  screen in Settings, but it is NOT wired into the real intervention
  pipeline (`lib/intervention/`) -- protected-app interruptions still use
  the cloud/offline providers from section 4b, unchanged. Run
  `flutter pub get && flutter analyze` first and fix any compile errors
  the `flutter_gemma`/`flutter_gemma_litertlm` calls surface before
  relying on this for anything beyond the test screen.
- ~~`CoKeeperInboxScreen` isn't reachable from anywhere yet~~ **Done.**
  Added as a Settings entry ("Co-Keeper Requests"). Proper deep-linking
  (tapping the invite link opening straight to an Accept screen) is still
  not implemented -- that's a separate, larger addition (route parsing +
  a real hosted domain, see below) -- but the screen is no longer a
  dead end reachable only by editing `main.dart`'s `home:` by hand.
- **The invite link uses a placeholder domain** (`oneir.app`) that doesn't
  exist -- needs either a real hosted page or a Firebase Dynamic Link before
  it does anything for whoever receives it. Left as-is: this needs real
  hosted infrastructure, not a code fix.
- ~~No reason picker (Homework/Urgent/Other) on the request~~ **Done.**
  Tapping "Request Key" now shows a Homework/Urgent/Other picker
  (`lib/interruption/interruption_main.dart`, reusing the existing
  `OneirSelectionRow` pattern) before actually sending the request --
  `CoKeeperBackend.sendKeyRequest` gets a real reason instead of `''`.
- ~~The interruption screen's art is still placeholder~~ **Done.** Real
  Vanya mouth-shape photos now live in `assets/images/vanya_face/` and
  are wired into both lip-sync implementations: `VanyaTalkingCharacter`
  (`lib/intervention/lipsync/`, the one actually used by
  `intervention_conversation_screen.dart`) via `MouthCueShapeAsset`, and
  the unused `VanyaFaceWidget` prototype (`lib/intervention/animation/`)
  via `MouthShapeAsset` -- both replaced a vector `CustomPainter` that
  had explicitly documented itself as a stand-in for exactly this swap.
  Two honest gaps from the swap: there's no idle blink anymore (the
  source photos don't include a separate blink frame -- eyes are baked
  into the same image as the mouth, so faking a blink would look wrong),
  and `MouthCueShape.ef` ("tight rounded/puckered") reuses the `d`
  ("oh") photo since the source set has no distinct puckered shot. Two
  extra photos came with the same upload but aren't wired to anything --
  `vanya_mouth_extra_sad.jpg` and `vanya_mouth_extra_neutral_expression.jpg`
  in the same folder, sitting there for whoever picks the next spot for
  a "concerned" Vanya (the interruption/check-in flow seems like a
  natural fit, but that's a product call this pass didn't make). Not
  verified on a real device, same caveat as everything else in this
  doc -- worth a visual check that `BoxFit.contain` on a full-body photo
  reads well at the ~130px size `intervention_conversation_screen.dart`
  uses, since the source art is a full standing-bunny illustration, not
  a cropped headshot the way the old vector painter was.
- **This all relies on each device's self-generated local ID as if it were
  a user account** (see the note at the top of `firestore.rules`) -- there's
  no real login, so anyone who has (or guesses) a request/pairing document ID
  could theoretically read or interfere with it. Fine for trusted use among
  people who already know each other; would need real Firebase Auth before
  handling anything more sensitive.
- **Battery-optimization exemption** (the 5th permission from the original
  Permissions spec) still isn't requested anywhere.
- ~~The onboarding "Interruption Demo" step played back three fixed lines
  and one canned question no matter what the user typed~~ **Done.** It's
  now `AiInterventionDemoScreen` (`lib/screens/`), which opens the real
  `InterventionConversationScreen` against a demo package name
  (`com.oneir.onboarding_demo`, isolated from the user's actual protected
  apps) and runs the genuine AI decision pipeline -- see "4b. Set up
  Vanya's real AI backend" above for what needs deploying before this (or
  the real interruption flow) gives real model replies instead of falling
  back to `OfflineHeuristicProvider`. Honest gaps: not verified on a real
  device or against a live-deployed Cloud Function (no way to deploy or
  run either from this environment); the offline heuristic fallback is
  intentionally simple (keyword matching, not real language understanding)
  so a reply outside its known phrasing may ask a clarifying question
  where a real model call would have understood it immediately -- that's
  expected until `AI_PROVIDER=cloud` (or a direct provider key) is
  actually configured.

## Android App Widgets (3 concepts) -- setup steps

After running `flutter create .`:

1. **Copy layouts**: everything in `android_native_files/widgets/layout/`
   -> `android/app/src/main/res/layout/`
2. **Copy drawables**: everything in `android_native_files/widgets/drawable/`
   -> `android/app/src/main/res/drawable/`
3. **Copy widget-info XML**: everything in `android_native_files/widgets/xml/`
   -> `android/app/src/main/res/xml/` (alongside `oneir_accessibility_service_config.xml`)
4. **Copy Kotlin providers**: everything in `android_native_files/widgets/kotlin/`
   -> the same package folder as `MainActivity.kt`
   (`android/app/src/main/kotlin/com/oneir/app/`)
5. **Merge `strings_additions.xml`** (now includes 3 new widget description
   strings) into `android/app/src/main/res/values/strings.xml`
6. **Merge `AndroidManifest_additions.xml`** (now includes 3 `<receiver>`
   entries) into `android/app/src/main/AndroidManifest.xml`
7. `flutter pub get` (picks up the new `home_widget` dependency)

## What's still not fully finished (widgets)

- **Not tested on a real device** (no Flutter/Android SDK in this
  environment) -- the Kotlin/XML follows standard, well-established
  `AppWidgetProvider` patterns, but the usual "would this actually work"
  check still means: install it, add each widget to a real home screen,
  and confirm before trusting it. This applies doubly to the launch-Uri
  wiring below, since it depends on exactly how `home_widget` v0.7.0's
  native plugin (`HomeWidgetPlugin.kt`, auto-registered via
  `GeneratedPluginRegistrant` -- not something this project's own
  `MainActivity.kt` needs to call directly) hands the launch `Uri` back
  to `HomeWidget.widgetClicked` / `initiallyLaunchedFromHomeWidget()` on
  cold start vs. warm start; verified against the package's own 0.7.0
  source and its example app, not against a running build.

### Previously-open items, now addressed (still unverified per above)

- **Widget tap routing is wired end-to-end.** Widgets 2 and 3 used to
  launch the app with a raw `putExtra("ONEIR_WIDGET_ACTION", ...)` intent
  extra that nothing on the Dart or native side ever read -- effectively
  dead. They now build their `PendingIntent` via `home_widget`'s own
  `HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java,
  Uri.parse("oneir://widget/..."))` (see `QuickFocusWidgetProvider.kt` /
  `VanyaCheckInWidgetProvider.kt`), which is the mechanism
  `HomeWidget.widgetClicked` and `HomeWidget.initiallyLaunchedFromHomeWidget()`
  actually listen for -- no custom MethodChannel or `MainActivity`
  intent-reading code needed. `OneirWidgetService.consumeInitialLaunch()`
  and `.registerLaunchListener()` decode that Uri into an
  `OneirWidgetLaunch` enum, and `HomeScreen` (in
  `widgets_and_home_screens.dart`) calls both at startup and routes to
  `FocusTimeScreen` or `TasksScreen(autoFocusAdd: true)` accordingly, for
  both the cold-start (tap launched the app) and warm-start (app was
  already open) cases.
- **Widget 1 ("Today's Focus") is now tappable.** It previously had no
  `setOnClickPendingIntent` at all -- the whole widget was inert. It now
  opens the app via the same `HomeWidgetLaunchIntent` helper, with no
  `Uri` (there's no specific action to carry, just "open the app").
- **The earlier `home_widget's background callback registration isn't
  wired into main.dart` gap was based on a misreading of the API** --
  `registerBackgroundCallback` (renamed `registerInteractivityCallback`
  as of home_widget 0.4.0) runs Dart in a background isolate to update
  widget data *without* opening the app, which isn't what either widget
  needs here (both are meant to open the app and land somewhere). Nothing
  needed to be wired for that; the doc comment in `OneirWidgetService`
  that pointed at it has been corrected in place rather than deleted, so
  the correction isn't silently lost.
- **The "Focus Time" session screen this list said didn't exist,
  actually already did** (`lib/screens/focus_time_screen.dart`, already
  linked from Home's "Focus Time" card and streak card) -- this list
  hadn't been updated to reflect it. It's now also where Widget 2's tap
  lands.
