# Browser integration checks

Start the emulators and run `npm.cmd run seed` first (see README). All integration tools use local emulator credentials and a `demo-` project; they do not contact a production database.

## Two-session UI smoke test

Build and serve the app:

```powershell
flutter build web --no-wasm-dry-run --dart-define=USE_EMULATORS=true
python -m http.server 7357 --bind 127.0.0.1 --directory build/web
```

In another terminal run `npm.cmd run test:ui`.

This launches isolated admin and guest Chrome sessions, signs in the admin, records a run, verifies that the guest score updates without refreshing, undoes the delivery, and verifies guest admin-route blocking. Screenshots go to `.tools/screenshots/`. The seeded `ground-live` match must still have an active over.

## Repository integration probe

This runs the actual Dart repositories against Auth and Firestore emulators, including competing writes, player IDs shared by opposing squads, extras, wickets, undo, a completed chase, live streams and standings.

```powershell
flutter build web --target=tools/scoring_probe.dart --output=.tools/probe-web --no-wasm-dry-run --dart-define=USE_EMULATORS=true
python -m http.server 7358 --bind 127.0.0.1 --directory .tools/probe-web
```

Then run `npm.cmd run test:probe`. It must report PASS. The probe cleans up its dedicated integration match and teams on success. It can be rerun after a failed attempt.

This compiled-app probe avoids a CanvasKit-serving issue observed in Flutter 3.44.2's Windows Chrome test harness. Unit, widget and responsive tests still run with the ordinary `flutter test` command.

## Checked behavior

- Scoring engine: strike rotation, legal deliveries, extras, wickets, free hits, innings limits, chase results and NRR.
- Standings: wins, ties, no results, legal-ball rates and all-out overs.
- Access: guest management-route rejection, full management access for signed-in users and live sign-out revocation.
- Responsive layout: narrow screens with enlarged text in light and dark themes.
- Firestore rules: public reads, rejected guest writes and equal user/admin management rights, signup role restrictions, own-profile access, admin role management and denial of unknown collections.

