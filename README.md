# Gully Cricket

Android-first Flutter app for local cricket tournaments. Guests follow live matches, squads, scorecards and standings. Temporarily, all signed-in users have full management access: tournaments, teams, squads, fixtures, scoring, deletion and user/role management. Guests browse read-only. Stored account roles are preserved.

## Connected live project

This workspace is configured for **Gully Score** (`gully-score-20261103`), Android package `com.gullyscore.app`. Select **Gully Score - Firebase** in VS Code, or run `flutter run --dart-define-from-file=firebase-config.json`.

The project already had another match schema. This app stores its collections under `gullyCricket/main` using `FIRESTORE_ROOT`; existing root collections and their security rules are preserved. For example, app accounts live at `gullyCricket/main/users/{uid}`. Promote the first registered app user there by setting `role` to `admin`.

Email/password authentication is enabled. Emulator demo accounts and demo fixtures are not copied to production.

Deploy updates for this live project with `npx.cmd firebase deploy --config firebase.production.json --only firestore:rules --project gully-score-20261103`. Keep the retained legacy rules in `firestore.production.rules`. The default `firestore.rules` remains the root-layout ruleset for local emulator tests and new standalone projects.

## Local demo

Requires Flutter/Dart (tested with Flutter 3.44.2 / Dart 3.12.2), Node.js 22+, Chrome, and Java 21+ on PATH for Firebase emulators.

```powershell
flutter pub get
npm.cmd ci
npm.cmd run emulators
```

In another terminal:

```powershell
npm.cmd run seed
flutter run -d chrome --dart-define=USE_EMULATORS=true
```

The seed script only targets localhost and creates live, upcoming and completed fixtures, squads, ball histories and an emulator-only admin: **admin@gully.local / Cricket123!**. Re-running it preserves existing match histories.

For an Android emulator, add `--dart-define=EMULATOR_HOST=10.0.2.2`. For a USB-connected Android phone, first run `adb reverse tcp:8080 tcp:8080` and `adb reverse tcp:9099 tcp:9099`, then use `flutter run --dart-define=USE_EMULATORS=true`. Debug builds allow local HTTP traffic. Live Firebase uses HTTPS.

## Firebase project

1. Create a Firebase project; enable **Authentication ? Email/Password** and create a **Cloud Firestore** database.
2. Register the Android app using the application ID in `android/app/build.gradle.kts`. Choose your own package ID before publishing. Register a web app separately if needed.
3. Copy `firebase-config.example.json` to `firebase-config.json` and fill all four fields from your Firebase app settings. Use the app ID for the platform you are running. The local file is ignored by Git.
4. Deploy the included rules: `npx.cmd firebase deploy --only firestore --project YOUR_PROJECT_ID` (Firebase login/project access required).
5. Run `flutter run --dart-define-from-file=firebase-config.json`. With no configuration, the app displays setup instructions.

To create the **first admin**, register in the app, then change that account's `users/{uid}.role` from `user` to `admin` in the Firebase console. The role change appears live. Existing admins can promote other accounts through **Manage Users**. Users cannot promote themselves.

## Scoring and validation

Select a fixture from **Live Scoring**, enter the toss and opening players, then record deliveries. Completed overs require a different next bowler. Innings close automatically at ten wickets, the overs limit or a successful chase; admins can also end an innings or abandon a match. Undo restores the last delivery, including a winning delivery, but cannot cross into a previous innings after the chase starts.

Points are two for a win, one for a tie/no result and zero for a loss. NRR uses legal balls and the full innings quota when all out; abandoned matches do not affect NRR. Rain-adjusted targets and super overs are outside this version.

```powershell
dart format --output=none --set-exit-if-changed lib test tools/scoring_probe.dart
flutter analyze
flutter test
npm.cmd run test:rules
flutter build apk --debug
```

Stop an already running Firestore emulator before `test:rules`, which starts its own instance. See [docs/testing.md](docs/testing.md) for browser integration checks.

The app uses handwritten Riverpod providers, Firestore streams, role-guarded routes, and transactional ball-plus-summary writes with revision checks. Fonts and their licenses are bundled. Light and dark themes follow the pitch-green palette.

Production configuration is saved locally in the ignored `firebase-config.json`. Physical two-device scoring still needs manual testing. Before store release, set the final application ID and release signing credentials; the current Android release configuration uses the template's debug signing.


## Temporary access policy

The owner has enabled full management access for every signed-in account. To restore the stored admin roles and prior ownership limits, set temporaryFullUserAccess to false in lib/features/auth/providers/auth_providers.dart and in both Firestore rulesets, then rebuild and redeploy firestore.production.rules. Existing account roles are preserved.

## App navigation

Use the bottom tabs for Home, Matches, Teams and Tournaments. Home offers a setup guide for the first match. Tournament pages have Add team and Schedule match actions; team pages have Add player, and tapping a player edits or removes them. The points table is the Points tab of each tournament, and scoring starts from a match's page. Optional form details are collapsed. New teams and tournaments open their own page after saving, with the next action ready. Scoring keeps run buttons visible and groups innings/end controls under Match options. Editing and deletion are in each record's More options menu; user management is in the main menu.
