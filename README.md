# Car Back

<p align="center">
  <img src="docs/images/hero.png" alt="Car Back on an iPhone, the screen edges glowing red for a car closing in at 46 km/h, and the same car alert on an Apple Watch Ultra">
</p>

An iPhone and Apple Watch app for riding with a Garmin Varia™ rear radar (RTL515/516). Formerly called Varia Radar.

<p align="center">
  <a href="https://apps.apple.com/app/id6821264126"><img src="https://toolbox.marketingtools.apple.com/api/badges/download-on-the-app-store/black/en-us?size=250x83" alt="Download on the App Store" height="56"></a>
</p>

Get it on the [App Store](https://apps.apple.com/app/id6821264126), or build it yourself – the code is open source under the MIT license.

- **Radar screen** – cars behind you, coloured by how soon they'd reach you, with their closing speed
- **Apple Watch rides** – live heart rate, zone and cadence on the phone; the ride is saved to Fitness with route, climb and effort
- **Alerts** – a tap on the wrist, a beep, a red glow around the screen edges, and a Live Activity in the Dynamic Island and on the Lock Screen
- **Settings** – radar-only mode, alert timing, sound, glow and auto-dim
- **Demo** – no radar with you? Simulated cars show how it all works

Built with [Claude Code](https://claude.com/claude-code) by a first-time iOS developer – see [How it was built](#how-it-was-built).

An independent project, not affiliated with or endorsed by Garmin. Garmin and Varia are trademarks of Garmin Ltd. or its subsidiaries.

## Screenshots

<table>
  <tr>
    <td align="center"><img src="docs/images/iphone-radar.png" width="250" alt="Radar screen with three cars: green far back, amber in the middle, and a red one 40 m behind closing at 46 km/h, with the screen edges glowing red"><br><sub>A car closing in fast</sub></td>
    <td align="center"><img src="docs/images/iphone-dynamic-island.png" width="250" alt="Expanded Dynamic Island showing heart rate 148 in zone 3, speed, the three cars on a strip, distance and ride time"><br><sub>Dynamic Island, from any app</sub></td>
    <td align="center"><img src="docs/images/iphone-settings.png" width="250" alt="Settings: Apple Watch, heart rate and cadence switches, alert timing, alert sound, red edge glow and auto-dim"><br><sub>Settings</sub></td>
  </tr>
</table>

<table>
  <tr>
    <td align="center"><img src="docs/images/watch-ride.png" width="300" alt="Apple Watch ride screen: ride time, heart rate 148 in zone 3, 18.40 km and 88 rpm cadence"><br><sub>The ride on the Watch</sub></td>
    <td align="center"><img src="docs/images/watch-car-alert.png" width="300" alt="Apple Watch car alert: a car 40 m behind, closing at 46 km/h"><br><sub>Car alert on the wrist, with a tap</sub></td>
  </tr>
</table>

The screenshots are from the iOS and watchOS simulators, using the app's demo data (see [Making the screenshots](#making-the-screenshots)).

## How it was built

I built this app with [Claude Code](https://claude.com/claude-code), Anthropic's AI coding agent, without having written an iOS app before. The whole project was a conversation:

- **I described what I wanted** – the radar as the hero of the screen, heart rate and zone from the Watch, alerts that still work when the phone is showing something else – and later, what went wrong on real rides.
- **Claude Code did the engineering** – it designed the app and wrote the Swift code for all three parts, generated the Xcode project, ran the builds and fixed the compiler errors, and checked its own UI work in the iOS and watchOS simulators by taking screenshots and tapping through the app.
- **I tested on real hardware** – rides with a Varia RTL515, an Apple Watch Ultra 2 and a Coospo BK467 cadence sensor – and fed back console logs, screenshots and bug reports for the next round of fixes.

Some examples of that loop:

- The Varia's radar data over Bluetooth isn't officially documented. The format was worked out from a console log of a real car passing, from 86 m down to 1 m.
- After the first test ride, the ride's distance and time kept running on the phone after the ride had ended on the Watch. Later the phone sometimes claimed it had lost the Watch after a normal finish. Both came down to how the phone followed the Watch's workout, and were fixed.
- The app icons, the alert sounds and the images in this README are drawn by Swift scripts in `Design/`, written the same way.

The result is about 2,800 lines of Swift in 35 files: an iPhone app, a watchOS app and a Live Activity extension, using SwiftUI, Core Bluetooth, HealthKit, ActivityKit, WidgetKit, Core Location and Core Motion.

## Building

Needs Xcode 27 (iOS 27 and watchOS 27). Open `VariaRadar.xcodeproj` and run the **VariaRadar** scheme on an iPhone.

The Xcode project is generated from `project.yml` by [XcodeGen](https://github.com/yonaskolb/XcodeGen). After changing `project.yml` or adding files, regenerate it:

```sh
brew install xcodegen
xcodegen generate
```

To build under your own Apple account, set `DEVELOPMENT_TEAM` in `project.yml`.

### Making the screenshots

Debug builds have a screenshot mode. Launched with `-demo` (in Xcode: Product › Scheme › Edit Scheme › Arguments), the iPhone app in the simulator holds three cars still, one of them closing in fast, with a Watch ride in progress; `-noRadar` shows the screen you get before a radar connects. The Watch app shows a ride; add `-demoAlert` for the car alert. The README screenshots are then framed with:

```sh
swift Design/render-readme-images.swift <screenshots folder> docs/images
```

## Layout

| Folder | What's in it |
|---|---|
| `VariaRadar/` | iPhone app: radar, Bluetooth, GPS, settings |
| `VariaRadarWatch/` | Watch app: records the ride and taps your wrist |
| `VariaRadarWidgets/` | Live Activity for the Dynamic Island and Lock Screen |
| `Shared/`, `LiveActivity/` | Code shared between the targets |
| `Design/` | Scripts that render the app icons, the alert sounds and the README images |
| `docs/images/` | The README images |
| `docs/app-store/` | The App Store listing: texts, review notes and screenshots |
| `PRIVACY.md` | The privacy policy (the app collects no data) |

The Varia's Bluetooth protocol is documented at the top of `VariaRadar/Radar/VariaBluetoothProvider.swift`.

## License

MIT – see [LICENSE](LICENSE). The app comes with no warranty: treat it as an extra pair of eyes, not a replacement for looking behind you.
