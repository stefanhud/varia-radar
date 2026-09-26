import SwiftUI

struct WatchRootView: View {
    @EnvironmentObject private var workout: WorkoutManager

    var body: some View {
        switch workout.phase {
        case .idle, .failed:
            StartView()
        case .starting:
            ProgressView("Starting…")
        case .running, .paused:
            ActiveRideView()
        case .saving:
            ProgressView("Saving to Fitness…")
        case .finished:
            SummaryView()
        }
    }
}

struct StartView: View {
    @EnvironmentObject private var workout: WorkoutManager

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "bicycle")
                .font(.system(size: 30))
                .foregroundStyle(.green)
            Button("Start ride") { workout.startFromWatch() }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            Text("or tap Start ride on your iPhone")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if case .failed(let message) = workout.phase {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear { workout.requestPermissions() }
    }
}

struct ActiveRideView: View {
    var body: some View {
        TabView {
            RideMetricsView()
            RideControlsView()
        }
        .tabViewStyle(.verticalPage)
    }
}

struct RideMetricsView: View {
    @EnvironmentObject private var workout: WorkoutManager

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 2) {
                Text(RideFormat.duration(workout.elapsed(at: context.date)))
                    .font(.system(size: 28, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.yellow)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(workout.heartRate.map(String.init) ?? "--")
                        .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                    if let zone = workout.zone {
                        Text("Z\(zone)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 6)
                            .background(ZoneColor.color(for: zone), in: Capsule())
                    }
                }
                Text(String(format: "%.2f km", workout.distanceMeters / 1000))
                    .font(.system(size: 22, weight: .semibold, design: .rounded).monospacedDigit())
                Text(workout.cadence.map { "\($0) rpm" } ?? "-- rpm")
                    .font(.system(size: 22, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.cyan)
                if workout.phase == .paused {
                    Text("PAUSED")
                        .font(.headline)
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay {
            if let alert = workout.carAlert {
                CarAlertBanner(alert: alert)
            }
        }
    }
}

struct RideControlsView: View {
    @EnvironmentObject private var workout: WorkoutManager
    @State private var confirmingEnd = false

    var body: some View {
        VStack(spacing: 10) {
            Button {
                workout.togglePause()
            } label: {
                Label(workout.phase == .paused ? "Resume" : "Pause",
                      systemImage: workout.phase == .paused ? "play.fill" : "pause.fill")
            }
            .tint(.yellow)

            Button(role: .destructive) {
                confirmingEnd = true
            } label: {
                Label("End ride", systemImage: "xmark")
            }
        }
        .confirmationDialog("End and save this ride?", isPresented: $confirmingEnd) {
            Button("End and save", role: .destructive) { workout.end() }
        }
    }
}

/// Full-screen red warning, shown for a few seconds along with a wrist tap.
struct CarAlertBanner: View {
    let alert: CarAlert

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "car.rear.fill")
                .font(.system(size: 30))
            Text("\(alert.distanceMeters) m")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text("+\(alert.closingKmh) km/h")
                .font(.headline)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.red)
    }
}

struct SummaryView: View {
    @EnvironmentObject private var workout: WorkoutManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Label("Saved to Fitness", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                if let summary = workout.summary {
                    SummaryRow(label: "Time", value: RideFormat.duration(summary.duration))
                    SummaryRow(label: "Distance", value: String(format: "%.2f km", summary.distanceMeters / 1000))
                    SummaryRow(label: "Avg HR", value: summary.averageHeartRate.map { "\($0) bpm" } ?? "--")
                    SummaryRow(label: "Climb", value: "\(Int(summary.elevationGainMeters)) m")
                    SummaryRow(label: "Effort",
                               value: summary.effort.map { "\($0) · \(RideFormat.effortLabel($0))" } ?? "--")
                    SummaryRow(label: "Active", value: "\(Int(summary.activeEnergyKcal)) kcal")
                }
                Button("Done") { workout.reset() }
                    .padding(.top, 6)
            }
        }
    }
}

private struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).monospacedDigit()
        }
    }
}
