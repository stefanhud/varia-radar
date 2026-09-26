import AVFoundation

// Renders the app's alert sounds:
//   CarAlert.caf — a short rising two-tone beep for a car turning red
//   Silence.caf  — a silent clip; Live Activity alerts must play *a* sound, so
//                  "Alert sound" off plays this one
//
//   swift Design/render-alert-sounds.swift VariaRadar/Sounds

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
let sampleRate = 44_100.0
let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: sampleRate, channels: 1, interleaved: false)!

func write(_ samples: [Float], to name: String) throws {
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
    buffer.frameLength = buffer.frameCapacity
    for (index, sample) in samples.enumerated() {
        buffer.floatChannelData![0][index] = sample
    }
    let settings: [String: Any] = [
        AVFormatIDKey: kAudioFormatLinearPCM,
        AVSampleRateKey: sampleRate,
        AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsFloatKey: false,
        AVLinearPCMIsBigEndianKey: false,
    ]
    let url = URL(fileURLWithPath: outDir).appendingPathComponent(name)
    let file = try AVAudioFile(forWriting: url, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
    try file.write(from: buffer)
}

/// One beep: a tone plus a touch of its octave so it cuts through wind noise, with
/// soft edges so it doesn't click.
func beep(frequency: Double, duration: Double) -> [Float] {
    (0..<Int(duration * sampleRate)).map { index in
        let t = Double(index) / sampleRate
        let attack = min(1, t / 0.006)
        let release = min(1, (duration - t) / 0.04)
        let tone = sin(2 * .pi * frequency * t) + 0.25 * sin(4 * .pi * frequency * t)
        return Float(0.7 * tone / 1.25 * attack * release)
    }
}

let gap = [Float](repeating: 0, count: Int(0.05 * sampleRate))
try FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
try write(beep(frequency: 880, duration: 0.11) + gap + beep(frequency: 1320, duration: 0.16), to: "CarAlert.caf")
try write([Float](repeating: 0, count: Int(0.2 * sampleRate)), to: "Silence.caf")
print("Wrote CarAlert.caf and Silence.caf to \(outDir)")
