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

# Generate the Xcode project
xcodegen generate

# Open in Xcode
open FrankEnergieWidget.xcodeproj
```

Then in Xcode:

1. Select the **FrankEnergieWidget** project in the navigator
2. For each target (FrankEnergieApp, FrankEnergieWidgetExtension):
   - Go to **Signing & Capabilities**
   - Check **Automatically manage signing**
   - Select your **Personal Team** from the dropdown
3. Press **Cmd+R** (or Product > Run) to build and launch

After the app launches:

4. Right-click your desktop > **Edit Widgets...** > search for **"Frank Energie"**
5. Drag the widget (Small or Medium) to your desktop

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
