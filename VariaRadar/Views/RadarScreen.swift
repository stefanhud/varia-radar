import SwiftUI
import UIKit

/// The whole ride screen: a thin status bar, the Watch ride controls, the radar
/// strip (the hero), and the slim metrics band underneath.
struct RadarScreen: View {
    @StateObject private var vm = RideViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showingSettings = false
    @AppStorage(AppSettings.Key.rideWithWatch) private var rideWithWatch = true
    @AppStorage(AppSettings.Key.showHeartRate) private var showHeartRate = true
    @AppStorage(AppSettings.Key.showCadence) private var showCadence = true
    @AppStorage(AppSettings.Key.edgeGlow) private var edgeGlow = true

    private var glowing: Bool { edgeGlow && vm.hasFastCar }

    var body: some View {
        VStack(spacing: 0) {
            StatusBar(connection: vm.connection, battery: vm.radarBattery) {
                showingSettings = true
            }
            if rideWithWatch {
                RideControlBar(link: vm.workout)
            }
            RadarStripView(vehicles: vm.vehicles)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    if vm.connection != .connected && vm.vehicles.isEmpty {
                        VStack(spacing: 10) {
                            ProgressView().tint(Palette.label)
                            Text(vm.connection == .scanning ? "Searching for Varia radar…" : "Radar offline")
                                .font(.system(size: 13))
                                .foregroundColor(Palette.label)
                        }
                    }
                }
            DataBandView(metrics: vm.metrics,
                         showHeartRate: rideWithWatch && showHeartRate,
                         showCadence: rideWithWatch && showCadence,
                         showRideTotals: rideWithWatch)
        }
        .background(Palette.background.ignoresSafeArea())
        .overlay {
            // Only in the view tree while needed, so the animation costs nothing otherwise.
            ZStack {
                if glowing {
                    ThreatEdgeGlow().transition(.opacity)
                }
            }
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.35), value: glowing)
        }
        // Any tap wakes a dimmed screen, without getting in the way of the buttons.
        .simultaneousGesture(TapGesture().onEnded { vm.screenTouched() })
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .onChange(of: showingSettings) { _, open in
            vm.dimmingPaused = open
            if open { vm.screenTouched() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { vm.appMovedToBackground() }
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true   // keep the screen awake
            vm.start()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            vm.stop()
        }
    }
}

/// Top strip: radar connection on the left; radar battery and the Settings button on
/// the right (the iPhone already shows the time).
struct StatusBar: View {
    let connection: ConnectionState
    let battery: Int?
    let onSettings: () -> Void

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 8, height: 8)
                Text("VARIA")
                    .font(.system(size: 12))
                    .tracking(1)
                    .foregroundColor(.white.opacity(0.9))
                Text(stateText)
                    .font(.system(size: 11))
                    .foregroundColor(Palette.label)
            }
            Spacer()
            if let battery {
                HStack(spacing: 4) {
                    Image(systemName: batterySymbol(battery))
                    Text("\(battery)%")
                }
                .font(.system(size: 12))
                .foregroundColor(batteryColor(battery))
            }
            Button(action: onSettings) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Palette.label)
                    .frame(width: 40, height: 32)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Settings")
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }

    private var dotColor: Color {
        switch connection {
        case .connected:    return Palette.threatNone
        case .scanning:     return Palette.threatApproaching
        case .disconnected: return Palette.threatFast
        }
    }

    private var stateText: String {
        switch connection {
        case .connected:    return "connected"
        case .scanning:     return "scanning…"
        case .disconnected: return "offline"
        }
    }

    private func batterySymbol(_ percent: Int) -> String {
        switch percent {
        case ..<13: return "battery.0percent"
        case ..<38: return "battery.25percent"
        case ..<63: return "battery.50percent"
        case ..<88: return "battery.75percent"
        default:    return "battery.100percent"
        }
    }

    private func batteryColor(_ percent: Int) -> Color {
        if percent <= 15 { return Palette.threatFast }
        if percent <= 30 { return Palette.threatApproaching }
        return Palette.label
    }
}
