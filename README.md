# Frank Energie Widget for macOS

A native macOS desktop widget that displays real-time dynamic electricity prices from [Frank Energie](https://www.frankenergie.nl). Shows hourly and quarter-hourly prices in an interactive step-line chart, matching the style of the Frank Energie website.

## Features

- **Step-line chart** showing 24-hour electricity prices with dynamic scaling
- **Interactive toggles**: switch between Marktprijs/All-in prijs and Per uur/Per kwartier
- **Current time marker** showing where you are in the day
- **Current price display** with color-coded indicator (green=cheap, orange=normal, red=expensive)
- **Small widget**: current electricity price at a glance
- **Medium widget**: full chart with current and average price
- **Dark mode primary** with automatic light mode support
- **Auto-refresh** every 15 minutes

## Installation

Building from source is required because macOS only registers WidgetKit extensions that are properly code-signed with a development certificate.

> **Building it? See [AGENTS.md](AGENTS.md)** for the exact, verified build/install sequence and the signing gotchas (the widget only registers when App-Sandboxed — empty entitlements or ad-hoc signing make it silently disappear from the gallery).

### Requirements

- macOS 15 (Sequoia) or later
- Xcode 16.0+ (required for code signing)
- An Apple ID (free account, no paid developer program needed)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

### Steps

```bash
# Install XcodeGen
brew install xcodegen

# Clone the repo
git clone https://github.com/NicolaivdSmagt/frank-energie-macos-widget.git
cd frank-energie-macos-widget

# Set your Apple Developer Team ID. project.yml reads it from the
# environment so it never gets committed. Find your Team ID at
# https://developer.apple.com/account (Membership details), then:
cp .env.example .env        # then edit .env and set DEVELOPMENT_TEAM

# Generate the Xcode project (loads DEVELOPMENT_TEAM from .env)
set -a; source .env; set +a
xcodegen generate

# Open in Xcode
open FrankEnergieWidget.xcodeproj
```

Then in Xcode:

1. Select the **FrankEnergieWidget** scheme in the toolbar
2. Press **Cmd+R** (or Product > Run) to build and launch

Signing (automatic management, your Personal Team, App Sandbox) is already
configured in `project.yml`, so no manual Signing & Capabilities changes are needed.
On the first build Xcode creates your free development certificate automatically.

After the app launches:

3. Right-click your desktop > **Edit Widgets...** > search for **"Frank Energie"**
4. Drag the widget (Small or Medium) to your desktop

> **The widget only appears if its extension is App-Sandboxed.** This is already set
> in `project.yml` and the `.entitlements` files. Note that `xcodegen generate` can
> strip the entitlements back to empty — if the widget stops showing up after a
> regenerate, see [AGENTS.md](AGENTS.md) for the one-line restore and full
> troubleshooting.

### Why can't I just download a pre-built binary?

macOS requires widget extensions to be code-signed with a valid development certificate to register with the system. Pre-built binaries from GitHub Releases are ad-hoc signed and won't show up in the widget gallery. You need to build from source with your own Apple ID to get a local signing certificate.

## How It Works

The widget fetches electricity prices from the Frank Energie public GraphQL API (`frank-graphql-prod.graphcdn.app`). No authentication or Frank Energie account is required - market prices are publicly available.

### Data Source

- **Electricity prices**: Updated hourly or quarter-hourly, available for today (and tomorrow after ~15:00 CET)
- **Refresh interval**: Every 15 minutes (WidgetKit may refresh less frequently to save battery)
- **API calls**: ~96 per day maximum (one per 15-minute refresh)

### Widget Sizes

| Size | Content |
|------|---------|
| Small | Current electricity price with color-coded price level indicator |
| Medium | Step-line chart + interactive toggles + current price + average price |

## Privacy

This widget:
- Only connects to `frank-graphql-prod.graphcdn.app` to fetch public market prices
- Stores your toggle preferences (price type, resolution) locally in UserDefaults
- Does not collect any personal data
- Does not require a Frank Energie account

## License

MIT License - see [LICENSE](LICENSE) for details.

## Credits

- Price data provided by [Frank Energie](https://www.frankenergie.nl)
- Inspired by the price chart on the [Frank Energie dynamic prices page](https://www.frankenergie.nl/nl/dynamisch-energiecontract/dynamische-energieprijzen)
