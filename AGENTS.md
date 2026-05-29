# AGENTS.md

Build/install guide for the Frank Energie macOS widget. Follow this exactly — the
ordering and the signing details matter.

## Prerequisites

- Full **Xcode** (not just Command Line Tools). Verify: `xcodebuild -version`.
  If `xcode-select -p` points at `/Library/Developer/CommandLineTools`, switch it:
  `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- **XcodeGen**: `brew install xcodegen`
- An Apple ID signed into **Xcode > Settings > Accounts** with a Personal Team.
  Find your 10-char Team ID at https://developer.apple.com/account (Membership
  details), signed in with the same Apple ID. `project.yml` reads it from the
  `DEVELOPMENT_TEAM` environment variable (it is intentionally NOT committed). Put it
  in a local `.env` file (gitignored) — copy the template and fill in your Team ID:
  ```bash
  cp .env.example .env   # then edit .env and set DEVELOPMENT_TEAM
  ```
  `.env` is loaded into the environment in step 1 below.

## Critical signing facts (why a naive build fails to show the widget)

macOS's widget daemon (`chronod` / `pluginkit`) **silently refuses to register a
widget extension unless it is App-Sandboxed.** A build can succeed, install, and
launch, yet the widget never appears in the gallery. The two settings that make
registration work are already in `project.yml`:

- `ENABLE_APP_SANDBOX: YES` and the `com.apple.security.app-sandbox` entitlement in
  both `FrankEnergieApp/FrankEnergieApp.entitlements` and
  `FrankEnergieWidget/FrankEnergieWidget.entitlements`. Empty (`<dict/>`)
  entitlements => extension is NOT registered.
- `AD_HOC_CODE_SIGNING_ALLOWED: NO`. If ad-hoc signing is allowed, Xcode signs with
  identity `-`, which strips entitlements (including the sandbox) and the widget is
  never registered.
- `com.apple.security.network.client` is also set so the widget can reach the
  Frank Energie API.

Do NOT revert the entitlements files to `<dict/>` or re-enable ad-hoc signing.

## Build + install (the working sequence)

```bash
# 1. Generate the Xcode project from project.yml (loads DEVELOPMENT_TEAM from .env)
set -a; source .env; set +a
xcodegen generate

# 2. Build (signs with the Personal Team; -allowProvisioningUpdates lets the
#    Development cert be created on first build)
xcodebuild -project FrankEnergieWidget.xcodeproj \
  -scheme FrankEnergieWidget -configuration Debug \
  -destination 'platform=macOS' -allowProvisioningUpdates \
  clean build

# 3. Install the built .app into /Applications and launch it
APP="$HOME/Library/Developer/Xcode/DerivedData/FrankEnergieWidget-*/Build/Products/Debug/Frank Energie Widget.app"
APP=$(ls -d $APP | head -1)
osascript -e 'quit app "Frank Energie Widget"' 2>/dev/null
rm -rf "/Applications/Frank Energie Widget.app"
cp -R "$APP" /Applications/
LSREG="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"
"$LSREG" -f -R -trusted "/Applications/Frank Energie Widget.app"
open "/Applications/Frank Energie Widget.app"
```

## Verify the extension registered

```bash
pluginkit -m -v -i nl.frankenergie.widget.app.widget
```

Expected output: a line pointing at the `.appex` inside
`/Applications/Frank Energie Widget.app`. If it prints `(no matches)`, the widget
will NOT be in the gallery — see Troubleshooting.

Then add it: right-click desktop > **Edit Widgets...** > search **"Frank Energie"**
> drag Small or Medium onto the desktop.

## Troubleshooting

- **`xcodegen generate` wipes the entitlements to `<dict/>`**: because
  `ENABLE_APP_SANDBOX: YES` is set, XcodeGen rewrites the `.entitlements` files and
  drops the `com.apple.security.*` keys. This silently un-sandboxes the widget so it
  stops registering. After every `xcodegen generate`, verify the entitlements still
  contain `com.apple.security.app-sandbox`; if not, restore them:
  `git checkout HEAD -- FrankEnergieApp/FrankEnergieApp.entitlements FrankEnergieWidget/FrankEnergieWidget.entitlements`
- **`pluginkit` says `(no matches)`**: the extension isn't sandboxed or was ad-hoc
  signed. Confirm with:
  `codesign -d --entitlements - "/Applications/Frank Energie Widget.app/Contents/PlugIns/FrankEnergieWidgetExtension.appex"` —
  it must contain `com.apple.security.app-sandbox`. If missing, check the entitlements
  files and the two build settings above, regenerate, rebuild.
- **Stale registration shadows the new build**: an old copy in DerivedData can be
  resolved instead of `/Applications`. Unregister it:
  `"$LSREG" -u "<old path>"` and delete the stale `.app`, then re-register
  `/Applications`.
- **Force a re-scan**: `killall chronod` (it relaunches automatically), then re-check
  with `pluginkit`.
- **Debug dylibs** (`__preview.dylib`, `*.debug.dylib`) inside the `.appex` are
  normal for Debug builds and do not prevent registration once the sandbox is set.

## Notes

- Free Personal Team certificates expire after ~7 days. When the widget stops
  updating, just rerun the build + install sequence above.
- `project.yml` is the source of truth; `FrankEnergieWidget.xcodeproj` is generated
  and should not be hand-edited.
