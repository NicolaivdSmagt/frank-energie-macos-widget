# Frank Energie Widget for macOS

A native macOS desktop widget that displays real-time dynamic electricity prices from [Frank Energie](https://www.frankenergie.nl). Shows hourly and quarter-hourly prices in an interactive step-line chart, matching the style of the Frank Energie website.

## Features

- **Step-line chart** showing 24-hour electricity prices
- **Interactive toggles**: switch between Marktprijs/All-in prijs and Per uur/Per kwartier
- **Current time marker** showing where you are in the day
- **Small widget**: shows current electricity price at a glance with color-coded price level
- **Medium widget**: full chart with average price and gas price summary
- **Dark mode primary** with automatic light mode support
- **Auto-refresh** every 15 minutes

## Installation

### Download (recommended)

1. Download the latest `.zip` from [Releases](../../releases)
2. Unzip the file
3. Move `Frank Energie Widget.app` to `/Applications`
4. **Important**: Right-click the app and select "Open" (bypasses Gatekeeper since the app is not notarized)
5. The app will open briefly showing setup instructions - you can close it
6. Right-click your desktop > "Edit Widgets..." > search for "Frank Energie"
7. Drag the widget (Small or Medium) to your desktop

> **Note**: Since this app is not signed with an Apple Developer certificate, macOS will warn you on first launch. This is safe to dismiss - the source code is fully open and the app only makes network requests to the Frank Energie public price API.

### Alternative Gatekeeper bypass

If right-click > Open doesn't work, run this in Terminal:

```bash
xattr -cr "/Applications/Frank Energie Widget.app"
```

## Build from Source

Requires:
- macOS 15.0+
- Xcode 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

```bash
# Install XcodeGen
brew install xcodegen

# Clone and build
git clone https://github.com/NicolaivdSmagt/frank-energie-macos-widget.git
cd frank-energie-macos-widget
xcodegen generate
xcodebuild -scheme FrankEnergieWidget -configuration Release build
```

## How It Works

The widget fetches electricity and gas prices from the Frank Energie public GraphQL API (`frank-graphql-prod.graphcdn.app`). No authentication or Frank Energie account is required - market prices are publicly available.

### Data Source

- **Electricity prices**: Updated hourly or quarter-hourly, available for today (and tomorrow after ~15:00 CET)
- **Gas prices**: Updated daily, split into before/after 06:00
- **Refresh interval**: Every 15 minutes

### Widget Sizes

| Size | Content |
|------|---------|
| Small | Current electricity price with color indicator (green=cheap, orange=normal, red=expensive) |
| Medium | Step-line chart + toggles + average electricity price + gas prices |

## Requirements

- macOS 15 (Sequoia) or later
- Network connection (to fetch prices from Frank Energie API)

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
