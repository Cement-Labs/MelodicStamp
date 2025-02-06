//
//  RealtimeAnalyzer.swift
//  MelodicStamp
//
//  Created by Xinshao_Air on 2025/1/21.
//

import Accelerate
import AVFoundation
import Foundation

class RealtimeAnalyzer {
    private var fftSize: Int
    private lazy var fftSetup = vDSP_create_fftsetup(vDSP_Length(Int(round(log2(Double(fftSize))))), FFTRadix(kFFTRadix2))

    public var frequencyBands: Int = 80 // Number of bands
    public var startFrequency: Float = 80 // Initial frequency
    public var endFrequency: Float = 18000 // Cutoff frequency

    @MainActor
    private lazy var bands: [(lowerFrequency: Float, upperFrequency: Float)] = {
        var bands = [(lowerFrequency: Float, upperFrequency: Float)]()

        // 1: Determine the growth factor according to the start and end spectrum and the number of frequency bands: 2^n

        let n = log2(endFrequency / startFrequency) / Float(frequencyBands)
        var nextBand: (lowerFrequency: Float, upperFrequency: Float) = (startFrequency, 0)
        for i in 1...frequencyBands {
            // 2: The upper frequency point of a frequency band is 2^n times the lower frequency point

            let highFrequency = nextBand.lowerFrequency * powf(2, n)
            nextBand.upperFrequency = i == frequencyBands ? endFrequency : highFrequency
            bands.append(nextBand)
            nextBand.lowerFrequency = highFrequency
        }
        return bands
    }()

    private var spectrumBuffer = [[Float]]()
    public var spectrumSmooth: Float = 0.5 {
        didSet {
            spectrumSmooth = max(0.0, spectrumSmooth)
            spectrumSmooth = min(1.0, spectrumSmooth)
        }
    }

    init(fftSize: Int) {
        self.fftSize = fftSize
    }

    @MainActor
    func analyze(with buffer: AVAudioPCMBuffer) -> [[Float]] {
        let channelsAmplitudes = fft(buffer)
        let aWeights = createFrequencyWeights()
        if spectrumBuffer.isEmpty {
            for _ in 0 ..< channelsAmplitudes.count {
                spectrumBuffer.append([Float](repeating: 0, count: bands.count))
            }
        }
        for (index, amplitudes) in channelsAmplitudes.enumerated() {
            let weightedAmplitudes = amplitudes.enumerated().map { index, element in
                element * aWeights[index]
            }
            var spectrum = bands.map {
                findMaxAmplitude(for: $0, in: weightedAmplitudes, with: Float(buffer.format.sampleRate) / Float(self.fftSize)) * 5
            }
            spectrum = highlightWaveform(spectrum: spectrum)

            let zipped = zip(spectrumBuffer[index], spectrum)
            spectrumBuffer[index] = zipped.map { $0.0 * spectrumSmooth + $0.1 * (1 - spectrumSmooth) }
        }
        return spectrumBuffer
    }

    @MainActor
    private func fft(_ buffer: AVAudioPCMBuffer) -> [[Float]] {
        var amplitudes = [[Float]]()
        guard let floatChannelData = buffer.floatChannelData else { return amplitudes }

        // 1: Extract sample data from the buffer
        var channels: UnsafePointer<UnsafeMutablePointer<Float>> = floatChannelData
        let channelCount = Int(buffer.format.channelCount)
        let isInterleaved = buffer.format.isInterleaved

        if isInterleaved {
            // Deinterleave
            let interleavedData = UnsafeBufferPointer(start: floatChannelData[0], count: fftSize * channelCount)
            var channelsTemp: [UnsafeMutablePointer<Float>] = []

            for i in 0 ..< channelCount {
                var channelData = stride(from: i, to: interleavedData.count, by: channelCount).map { interleavedData[$0] }
                channelData.withUnsafeMutableBufferPointer { ptr in
                    channelsTemp.append(ptr.baseAddress!)
                }
            }

            channelsTemp.withUnsafeBufferPointer { ptr in
                channels = ptr.baseAddress!
            }
        }

        for i in 0 ..< channelCount {
            let channel = channels[i]
            // 2: Add a Hanning window
            var window = [Float](repeating: 0, count: Int(fftSize))
            vDSP_hann_window(&window, vDSP_Length(fftSize), Int32(vDSP_HANN_NORM))
            vDSP_vmul(channel, 1, window, 1, channel, 1, vDSP_Length(fftSize))

            // 3: Package the real numbers into the complex numbers fftInOut required by FFT
            // It is both input and output
            var fftInOut: DSPSplitComplex!
            var realp = [Float](repeating: 0.0, count: Int(fftSize / 2))
            realp.withUnsafeMutableBufferPointer { realpPtr in
                var imagp = [Float](repeating: 0.0, count: Int(fftSize / 2))
                imagp.withUnsafeMutableBufferPointer { imagpPtr in
                    fftInOut = DSPSplitComplex(realp: realpPtr.baseAddress!, imagp: imagpPtr.baseAddress!)
                }
            }

            channel.withMemoryRebound(to: DSPComplex.self, capacity: fftSize) { typeConvertedTransferBuffer in
                vDSP_ctoz(typeConvertedTransferBuffer, 2, &fftInOut, 1, vDSP_Length(fftSize / 2))
            }

            // 4: Perform FFT
            vDSP_fft_zrip(fftSetup!, &fftInOut, 1, vDSP_Length(round(log2(Double(fftSize)))), FFTDirection(FFT_FORWARD))

            // 5: Adjust the FFT result and calculate the amplitude
            fftInOut.imagp[0] = 0

            let fftNormFactor = Float(1.0 / Float(fftSize))
            vDSP_vsmul(fftInOut.realp, 1, [fftNormFactor], fftInOut.realp, 1, vDSP_Length(fftSize / 2))
            vDSP_vsmul(fftInOut.imagp, 1, [fftNormFactor], fftInOut.imagp, 1, vDSP_Length(fftSize / 2))

            var channelAmplitudes = [Float](repeating: 0.0, count: Int(fftSize / 2))
            vDSP_zvabs(&fftInOut, 1, &channelAmplitudes, 1, vDSP_Length(fftSize / 2))
            channelAmplitudes[0] = channelAmplitudes[0] / 2
            amplitudes.append(channelAmplitudes)
        }
        return amplitudes
    }

    private func findMaxAmplitude(for band: (lowerFrequency: Float, upperFrequency: Float), in amplitudes: [Float], with bandWidth: Float) -> Float {
        let startIndex = Int(round(band.lowerFrequency / bandWidth))
        let endIndex = min(Int(round(band.upperFrequency / bandWidth)), amplitudes.count - 1)
        return amplitudes[startIndex...endIndex].max()!
    }

    private func createFrequencyWeights() -> [Float] {
        let Δf = 44100.0 / Float(fftSize)
        let bins = fftSize / 2

        var f: [Float] = (0 ..< bins).map { Float($0) * Δf }
        f = f.map { $0 * $0 }

        let c1 = powf(12194.217, 2.0)
        let c2 = powf(20.598997, 2.0)
        let c3 = powf(107.65265, 2.0)
        let c4 = powf(737.86223, 2.0)

        let num: [Float] = f.map { c1 * $0 * $0 }
        let den: [Float] = f.map { ($0 + c2) * sqrtf(($0 + c3) * ($0 + c4)) * ($0 + c1) }

        let weights = zip(num, den).map { numValue, denValue in
            1.2589 * numValue / denValue
        }

        return Array(weights)
    }

    private func highlightWaveform(spectrum: [Float]) -> [Float] {
        let weights: [Float] = [1, 2, 3, 5, 3, 2, 1]
        let totalWeights = Float(weights.reduce(0, +))
        let startIndex = weights.count / 2
        var averagedSpectrum = Array(spectrum[0 ..< startIndex])
        for i in startIndex ..< spectrum.count - startIndex {
            let zipped = zip(Array(spectrum[i - startIndex...i + startIndex]), weights)
            let averaged = zipped.map { $0.0 * $0.1 }.reduce(0, +) / totalWeights
            averagedSpectrum.append(averaged)
        }
        averagedSpectrum.append(contentsOf: Array(spectrum.suffix(startIndex)))
        return averagedSpectrum
    }
}
