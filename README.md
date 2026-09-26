# Varia Radar

An iPhone and Apple Watch app for riding with a Garmin Varia rear radar (RTL515/516).

- **Radar screen** – cars behind you, coloured by how soon they'd reach you, with their closing speed
- **Apple Watch rides** – live heart rate, zone and cadence on the phone; the ride is saved to Fitness with route, climb and effort
- **Alerts** – a tap on the wrist, a beep, a red glow around the screen edges, and a Live Activity in the Dynamic Island and on the Lock Screen
- **Settings** – radar-only mode, alert timing, sound, glow and auto-dim

An independent project, not affiliated with or endorsed by Garmin. Varia is a trademark of Garmin Ltd.

## Building

Needs Xcode 27 (iOS 27 and watchOS 27). Open `VariaRadar.xcodeproj` and run the **VariaRadar** scheme on an iPhone.

The Xcode project is generated from `project.yml` by [XcodeGen](https://github.com/yonaskolb/XcodeGen). After changing `project.yml` or adding files, regenerate it:

```sh
brew install xcodegen
xcodegen generate
```

To build under your own Apple account, set `DEVELOPMENT_TEAM` in `project.yml`.

## Layout

| Folder | What's in it |
|---|---|
| `VariaRadar/` | iPhone app: radar, Bluetooth, GPS, settings |
| `VariaRadarWatch/` | Watch app: records the ride and taps your wrist |
| `VariaRadarWidgets/` | Live Activity for the Dynamic Island and Lock Screen |
| `Shared/`, `LiveActivity/` | Code shared between the targets |
| `Design/` | Scripts that render the app icons and the alert sounds |

The Varia's Bluetooth protocol is documented at the top of `VariaRadar/Radar/VariaBluetoothProvider.swift`.
