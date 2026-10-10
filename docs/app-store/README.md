# App Store listing – Car Back

Everything App Store Connect asks for, ready to paste. Screenshots are in `screenshots/`.

## App information

| Field | Value |
|---|---|
| Name | Car Back: Bike Radar |
| Subtitle | Cars behind you, on your wrist |
| Bundle ID | com.stefanhud.CarBack |
| SKU | car-back |
| Primary language | English (U.S.) |
| Primary category | Health & Fitness |
| Secondary category | Sports |
| Content rights | Doesn't contain, show or access third-party content |
| Price | 0.99 € (pick Slovakia as the base country; other countries follow automatically) |
| Availability | All countries. Untick "Apple silicon Mac" and "Apple Vision Pro" – the app needs Bluetooth radar and Apple Health on an iPhone |
| Copyright | 2026 Stefan Hudzik |
| Support URL | https://github.com/stefanhud/varia-radar/issues |
| Marketing URL | https://github.com/stefanhud/varia-radar |
| Privacy policy URL | https://github.com/stefanhud/varia-radar/blob/main/PRIVACY.md |

**App Privacy:** "No, we do not collect data from this app." (Nothing leaves the device: no servers, analytics, ads or accounts.)

**Age rating:** nothing in the app is mature content; answer the questions as they apply and it should come out 4+.

## Version 1.0

**Promotional text** (can be changed any time without review)

> See every car behind you at a glance, feel a tap on your wrist when one comes in fast, and save the ride to Apple Fitness.

**Keywords** (99 of 100 characters – no trademarks, and no words already in the name)

```
rearview,cycling,bicycle,car,alert,commute,safety,heart rate,zone,cadence,ride,road,taillight,watch
```

**Description**

```
Car Back shows the cars behind you while you ride. It connects to your rear-view bike radar and turns the iPhone on your handlebar into a clear, glanceable radar screen – and your Apple Watch taps your wrist when a car comes in fast.

THE RADAR
• Every car behind you as a dot, placed by its distance
• Coloured by how soon it would reach you, not just how close it is: green, amber, red
• The closing speed next to each car
• A red glow around the screen edges and a beep when a car comes in fast – even with the phone on silent
• Choose how early cars turn amber and red

APPLE WATCH (OPTIONAL)
• Start a ride on your iPhone; your Apple Watch records it to Apple Health and the Fitness app, with heart rate, cadence, GPS route, distance, climb and effort
• Live heart rate, heart rate zone and cadence on the phone, next to your speed, distance and ride time
• A tap on your wrist when a car comes in fast

ALWAYS IN VIEW
• A Live Activity in the Dynamic Island and on the Lock Screen, so you still see the cars while using maps or music
• The radar's battery level
• Large, high-contrast numbers made for a quick glance; the screen stays awake
• Optional auto-dim that wakes up the moment a car appears

No radar with you? Try the built-in demo.

COMPATIBILITY
Works with Garmin Varia™ rear-view radars that connect over Bluetooth (tested with the RTL515). Needs iOS 27; the Apple Watch app needs watchOS 27.

PRIVACY
No accounts, no ads, no tracking. Car Back doesn't collect any data, and your rides stay in Apple Health on your devices.

Car Back is an extra pair of eyes, not a replacement for looking behind you. Always ride with care.

Garmin and Varia are trademarks of Garmin Ltd. or its subsidiaries. Car Back is an independent app and is not affiliated with or endorsed by Garmin.
```

**Screenshots**

- iPhone with Dynamic Island, medium display (1206 × 2622): `screenshots/iphone/` in order 01–03.
- Apple Watch (422 × 514, Ultra 4): `screenshots/apple-watch/` in order 01–02.
- No iPad screenshots: the app is iPhone-only.

## App Review information

- Sign-in required: **No**
- Contact: your name, phone and email (only Apple sees these)
- Attachment: a short screen recording of the app on a real ride with the radar (Control Center → Screen Recording)
- Notes:

```
Car Back needs a Garmin Varia rear-view bike radar, which connects over Bluetooth. A screen recording of the app on a real ride is attached.

To try the app without a radar, tap "No radar with you? Try the demo" on the main screen. Simulated cars approach; fast ones turn red, make the screen edges glow and beep. Tap "End" at the top to leave the demo. The Live Activity appears when you go to the Home Screen during the demo.

The Apple Watch features are optional and switched off when no Watch is paired. With a paired Apple Watch, "Start ride" opens the Watch app, which records a cycling workout to Apple Health.

No account or login is needed. The app doesn't collect any data.
```

## Before you submit (your part)

1. **Business** in App Store Connect: accept the **Paid Apps Agreement**, add your bank account and fill in the tax forms. Without these, a paid app can't go on sale.
2. Join the **App Store Small Business Program** (developer.apple.com/app-store/small-business-program) so Apple takes 15% instead of 30%.
3. **EU trader status:** a paid app makes you a trader. Mark this app as a trader app; Apple then shows an address (a P.O. box is allowed), a phone number and an email on its EU App Store page. Your other app can keep its own status.
4. **Create the app:** Apps → + → New App, with the name, bundle ID, SKU and language above.
5. Fill in the fields above, upload the screenshots and record the review video.
6. Optional but wise: request access to Garmin's **Radar Data BLE Program** (developer.garmin.com/radar-data-ble).

Then the build: upload it, test it yourself through TestFlight on a ride, pick it on the version page and press **Submit for Review**.
