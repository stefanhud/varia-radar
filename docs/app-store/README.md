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

**Header and search results images** (optional, in `creative/`, made with `Design/render-readme-images.swift --store`):

- Product page header (21:9, 3840 × 1646): `creative/header.png` – no text, everything important in the middle, since each device shows a different slice.
- Search results (3:2, 3840 × 2560): `creative/search-results.png` – shown instead of the screenshots in search.

## App Review information

- Sign-in required: **No**
- Contact: your name, phone and email (only Apple sees these)
- Attachment: a screen recording from your iPhone (Control Center → Screen Recording). It must start with launching the app; see "Review video" below.
- Notes (Apple asked for exactly these six points on the first submission – keep them here):

```
1. SCREEN RECORDING
Attached: recorded on iPhone with the latest iOS. It starts by launching the app, connects to a Garmin Varia radar, goes through Settings, records a ride with the Apple Watch, and shows the built-in demo with simulated cars (car alerts, red edge glow, beep, Dynamic Island). The app has no accounts, no user-generated content and no in-app purchases; it is a paid app with all features included.

2. PURPOSE AND AUDIENCE
Car Back is for cyclists who use a rear-view bike radar (Garmin Varia) with an iPhone mounted on the handlebar. It shows the cars approaching from behind – their distance, closing speed and how soon they would reach the rider – and warns about fast ones with a red glow, a beep and a tap on the Apple Watch. Riders with an Apple Watch can also record the ride to Apple Health and Fitness and see heart rate, zone and – with a Bluetooth cadence sensor paired to the Watch – cadence on the phone, so they don't need a separate bike computer.

3. HOW TO USE IT
- No account or login is needed.
- With a Garmin Varia radar: switch it on and open the app; it connects automatically over Bluetooth ("RADAR connected"), and cars appear as dots.
- Without a radar: on the main screen, tap "No radar with you? Try the demo". Simulated cars approach; fast ones turn red, make the screen edges glow and beep. Tap "End" at the top to leave the demo. Go to the Home Screen during the demo to see the Live Activity in the Dynamic Island and on the Lock Screen.
- Apple Watch (optional): with a paired Apple Watch, "Ride with Apple Watch" is on in Settings. Tap "Start ride" – the Car Back Watch app starts a cycling workout, and heart rate and zone appear on the phone (cadence too, when a Bluetooth cadence sensor is paired to the Watch; otherwise it shows "–"). "Hold to end" finishes the ride, which is saved to Apple Health and Fitness.
- Settings: alert timing, alert sound, red edge glow, auto-dim, and links to the privacy policy and support.
- No sample files are needed.

4. EXTERNAL SERVICES
None. The app has no servers, accounts, analytics, advertising, AI or payment services of its own and sends no data anywhere. It uses Apple frameworks on the device only: Core Bluetooth (to connect to the user's own radar), HealthKit (to save and read the ride), Core Location (speed and route), ActivityKit/WidgetKit (Live Activity) and WatchConnectivity. While the radar, the demo or a ride is active, the iPhone app keeps location updates running in the background, so the speed and the cars in the Live Activity stay current while the rider uses another app (for example maps); iOS shows the blue location indicator. When none of these is active, the app stops using location in the background. The only external hardware is the user's own Garmin Varia radar, which the app connects to directly over Bluetooth Low Energy; no Garmin account or online service is involved.

5. REGIONAL DIFFERENCES
None. The app works the same in all regions (English, metric units).

6. REGULATED INDUSTRY / THIRD-PARTY MATERIAL
The app is not in a regulated industry and is not a medical device; heart rate is shown for fitness only. It contains no third-party content or Garmin logos, artwork or software. The name "Garmin Varia" appears only in the App Store description to state which radars the app works with, together with a notice that Garmin and Varia are trademarks of Garmin Ltd. and that the app is not affiliated with or endorsed by Garmin.
```

### Review video

About two minutes on the iPhone, with the latest iOS, the Varia switched on and the Watch on your wrist:

1. Start Screen Recording, then tap Car Back on the Home Screen (the video must start with the launch).
2. Wait for "RADAR connected" and the battery level.
3. Open Settings, scroll through everything, tap Done.
4. Tap Start ride; wait for the heart rate (cadence stays "–" without a cadence sensor); go to the Home Screen and long-press the Dynamic Island; come back and Hold to end until "Saved to Fitness".
5. Switch the Varia off; tap "No radar with you? Try the demo"; wait for a red car (glow and beep); show the island from the Home Screen; come back and tap End.
6. Stop recording.

## Before you submit (your part)

1. **Business** in App Store Connect: accept the **Paid Apps Agreement**, add your bank account and fill in the tax forms. Without these, a paid app can't go on sale.
2. Join the **App Store Small Business Program** (developer.apple.com/app-store/small-business-program) so Apple takes 15% instead of 30%.
3. **EU trader status:** a paid app makes you a trader. Mark this app as a trader app; Apple then shows an address (a P.O. box is allowed), a phone number and an email on its EU App Store page. Your other app can keep its own status.
4. **Create the app:** Apps → + → New App, with the name, bundle ID, SKU and language above.
5. Fill in the fields above, upload the screenshots and record the review video.
6. Optional but wise: request access to Garmin's **Radar Data BLE Program** (developer.garmin.com/radar-data-ble).

Then the build: upload it, test it yourself through TestFlight on a ride, pick it on the version page and press **Submit for Review**.
