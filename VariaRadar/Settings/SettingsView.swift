import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettings.Key.rideWithWatch) private var rideWithWatch = true
    @AppStorage(AppSettings.Key.showHeartRate) private var showHeartRate = true
    @AppStorage(AppSettings.Key.showCadence) private var showCadence = true
    @AppStorage(AppSettings.Key.alertTiming) private var alertTiming = AlertTiming.normal
    @AppStorage(AppSettings.Key.alertSound) private var alertSound = true
    @AppStorage(AppSettings.Key.edgeGlow) private var edgeGlow = true
    @AppStorage(AppSettings.Key.autoDim) private var autoDim = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Ride with Apple Watch", isOn: $rideWithWatch)
                    if rideWithWatch {
                        Toggle("Heart rate and zone", isOn: $showHeartRate)
                        Toggle("Cadence", isOn: $showCadence)
                    }
                } header: {
                    Text("Apple Watch")
                } footer: {
                    Text(rideWithWatch
                         ? "Start rides here and your Watch records them to Fitness."
                         : "Just the radar and your speed. Turn this on if you ride with an Apple Watch.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Alert timing")
                        Picker("Alert timing", selection: $alertTiming) {
                            ForEach(AlertTiming.allCases) { timing in
                                Text(timing.title).tag(timing)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    .padding(.vertical, 4)
                    Toggle("Alert sound", isOn: $alertSound)
                    Toggle("Red edge glow", isOn: $edgeGlow)
                } header: {
                    Text("Car alerts")
                } footer: {
                    Text("Cars turn amber \(Int(alertTiming.amberBelowSeconds)) seconds and red "
                         + "\(String(format: "%g", alertTiming.redBelowSeconds)) seconds before they'd reach you. "
                         + "A red car beeps (even with the phone on silent) and makes the screen edges glow.")
                }

                Section {
                    Toggle("Auto-dim screen", isOn: $autoDim)
                } header: {
                    Text("Screen")
                } footer: {
                    Text("Dims after 15 seconds without approaching cars to save battery, and wakes up "
                         + "the moment one appears or you tap the screen. Only while the radar is connected.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
