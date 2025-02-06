//
//  PlayerModel.swift
//  MelodicStamp
//
//  Created by KrLite on 2024/11/20.
//

import Accelerate
import CAAudioHardware
import Combine
import Defaults
import os.log
import SFBAudioEngine
import SwiftUI

// MARK: - Definition

extension PlayerModel: TypeNameReflectable {}

extension PlayerModel {
    static let interval: TimeInterval = 0.1
    static let bufferSize: AVAudioFrameCount = 2048
}

@Observable final class PlayerModel: NSObject {
    // MARK: Player, Library & Analyzer

    private var player: any Player
    private weak var library: LibraryModel?
    private weak var playlist: PlaylistModel?

    // MARK: Audio Visualizer

    private var fftSize: Int {
        Int(PlayerModel.bufferSize)
    }

    private var fftSetup: FFTSetup?
    private var frequencyBands: Int = 80 // Number of bands
    private var startFrequency: Float = 80 // Initial frequency
    private var endFrequency: Float = 18000 // Cutoff frequency
    private var spectrumBuffer = [[Float]]()

    private var spectrumSmooth: Float = 0.5 {
        didSet {
            spectrumSmooth = max(0.0, spectrumSmooth)
            spectrumSmooth = min(1.0, spectrumSmooth)
        }
    }

    // MARK: Output Devices

    // Do not use computed variables for the sake of correctly updating view data
    private(set) var outputDevices: [AudioDevice] = []
    private(set) var defaultOutputDevice: AudioDevice?
    private(set) var defaultSystemOutputDevice: AudioDevice?

    private(set) var isUsingSystemOutputDevice: Bool = false
    private var _selectedOutputDevice: AudioDevice?

    // Exposed value, `nil` for system output device
    var selectedOutputDevice: AudioDevice? {
        get { isUsingSystemOutputDevice ? nil : _selectedOutputDevice }
        set {
            if let newValue {
                isUsingSystemOutputDevice = false
                _selectedOutputDevice = newValue
            } else {
                isUsingSystemOutputDevice = true
            }

            updateOutputDevices(forceUpdating: true)
        }
    }

    // MARK: Publishers

    private var cancellables = Set<AnyCancellable>()
    private let timer = TimerPublisher(interval: PlayerModel.interval)

    private var visualizationDataSubject = PassthroughSubject<[[Float]], Never>()
    var visualizationDataPublisher: AnyPublisher<[[Float]], Never> { visualizationDataSubject.eraseToAnyPublisher() }

    // MARK: Playback

    private(set) var playbackState: PlaybackState = .stopped
    private(set) var playbackTime: PlaybackTime?
    var unwrappedPlaybackTime: PlaybackTime { playbackTime ?? .init() }

    // MARK: Responsive Fields

    var progress: CGFloat {
        get { unwrappedPlaybackTime.progress }

        set {
            player.seekProgress(to: newValue)
            updatePlaybackState()
            updateNowPlayingInfo(with: playbackState)
        }
    }

    var time: TimeInterval {
        get { unwrappedPlaybackTime.elapsed }

        set {
            player.seekTime(to: newValue)
            updatePlaybackState()
            updateNowPlayingInfo(with: playbackState)
        }
    }

    private var _volume: CGFloat = .zero
    var volume: CGFloat {
        get { _volume }

        set {
            _volume = newValue
            player.seekVolume(to: newValue)
        }
    }

    private var _isPlaying: Bool = false
    var isPlaying: Bool {
        get { _isPlaying }

        set {
            _isPlaying = newValue
            if isCurrentTrackPlayable {
                player.setPlaying(isPlaying)
            } else {
                guard isPlaying else { return }

                Task { @MainActor in
                    play()
                }
            }
        }
    }

    private(set) var isRunning: Bool = false

    private var _isMuted: Bool = false
    var isMuted: Bool {
        get { _isMuted }

        set {
            _isMuted = newValue
            player.setMuted(newValue)
        }
    }

    // MARK: Playlist

    private var currentTrack: (any Track)? {
        get { playlist?.currentTrack }
        set { playlist?.currentTrack = newValue }
    }

    var hasCurrentTrack: Bool {
        guard let playlist else { return false }
        return playlist.hasCurrentTrack
    }

    var hasNextTrack: Bool {
        guard let playlist else { return false }
        return playlist.hasNextTrack
    }

    var hasPreviousTrack: Bool {
        guard let playlist else { return false }
        return playlist.hasPreviousTrack
    }

    var isCurrentTrackPlayable: Bool {
        isRunning && hasCurrentTrack
    }

    // MARK: Initializers

    init(_ player: some Player, library: LibraryModel, playlist: PlaylistModel, fftSize: Int = 2048) {
        self.player = player
        self.library = library
        self.playlist = playlist
        self.fftSetup = vDSP_create_fftsetup(vDSP_Length(Int(round(log2(Double(fftSize))))), FFTRadix(kFFTRadix2))
        super.init()

        self.player.delegate = self
        setupRemoteTransportControls()
        setupEngine()

        timer
            .receive(on: DispatchQueue.main)
            .sink { _ in
                self.updateRunning()
                self.updatePlaying()
                self.updatePlaybackState()
                self.updatePlaybackTime()
                self.updateVolume()
                self.updateMuted()

                self.updateOutputDevices()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Functions

extension PlayerModel {
    private func updateRunning() {
        let updated = player.isRunning

        guard isRunning != updated else { return }
        isRunning = updated
    }

    private func updatePlaying() {
        let updated = player.isPlaying

        guard _isPlaying != updated else { return }
        _isPlaying = updated
    }

    private func updatePlaybackState() {
        let updated = player.playbackState
        guard playbackState != updated else { return }
        playbackState = updated
    }

    private func updatePlaybackTime() {
        if let updated = player.playbackTime {
            guard playbackTime != updated else { return }
            playbackTime = updated
        } else {
            playbackTime = nil
        }
    }

    private func updateVolume() {
        let updated = player.playbackVolume

        guard _volume != updated else { return }
        _volume = updated
    }

    private func updateMuted() {
        let updated = player.isMuted

        guard _isMuted != updated else { return }
        _isMuted = updated
    }
}

extension PlayerModel {
    // MARK: Play

    func play(_ url: URL) async {
        guard let track = await playlist?.play(url) else { return }
        play(track)
    }

    func play(_ track: (any Track)?) {
        if let track {
            currentTrack = track
            player.play(track)
        } else {
            stop()
        }
    }

    // MARK: Convenient Functions

    func play() {
        if isRunning {
            player.play()
        } else if let currentTrack {
            play(currentTrack)
        }
    }

    func pause() {
        player.pause()
    }

    func stop() {
        volume = .zero
        isPlaying = false
        isMuted = false

        player.stop()
    }

    func togglePlayPause() {
        player.togglePlaying()
    }

    func playNextTrack() {
        guard let nextTrack = playlist?.nextTrack else {
            stop()
            return
        }

        play(nextTrack)
    }

    func playPreviousTrack() {
        guard let previousTrack = playlist?.previousTrack else {
            stop()
            return
        }

        play(previousTrack)
    }

    // MARK: Engine

    private func setupEngine() {
        player.withEngine { [weak self] engine in
            guard let self else { return }

            // Audio visualization
            let inputNode = engine.mainMixerNode
            let bus = 0
            let format = inputNode.outputFormat(forBus: bus)

            inputNode.removeTap(onBus: bus)

            inputNode.installTap(onBus: bus, bufferSize: AVAudioFrameCount(PlayerModel.bufferSize), format: format) { [weak self] buffer, _ in
                guard let strongSelf = self else { return }
                if !strongSelf.player.isPlaying { return }

                buffer.frameLength = AVAudioFrameCount(Self.bufferSize)

                Task { @MainActor in
                    let spectra = strongSelf.analyze(with: buffer)
                    strongSelf.visualizationDataSubject.send(spectra)
                }
            }
        }
    }
}

// MARK: - Auxiliary Functions

extension PlayerModel {
    /*
         func analyzeFiles(urls: [URL]) {
             do {
                 let rg = try ReplayGainAnalyzer.analyzeAlbum(urls)
                 os_log("Album gain %.2f dB, peak %.8f; Tracks: [%{public}@]", log: OSLog.default, type: .info, rg.0.gain, rg.0.peak, rg.1.map { url, replayGain in
                     String(format: "\"%@\" gain %.2f dB, peak %.8f", FileManager.default.displayName(atPath: url.lastPathComponent), replayGain.gain, replayGain.peak)
                 }.joined(separator: ", "))
                 // TODO: Notice user we're done
             } catch {}
         }

         func exportWAVEFile(url: URL) {
             let destURL = url.deletingPathExtension().appendingPathExtension("wav")
             if FileManager.default.fileExists(atPath: destURL.path) {
                 // TODO: Handle this
                 return
             }

             do {
                 try AudioConverter.convert(url, to: destURL)
                 try? AudioFile.copyMetadata(from: url, to: destURL)
             } catch {
                 try? FileManager.default.trashItem(at: destURL, resultingItemURL: nil)

             }
         }
     */

    // MARK: Output Devices

    private func selectOutputDevice(_ device: AudioDevice) {
        do {
            try player.selectOutputDevice(device)
        } catch {}
    }

    func updateOutputDevices(forceUpdating: Bool = false) {
        do {
            outputDevices = try player.availableOutputDevices()
            defaultOutputDevice = try player.defaultOutputDevice()
            defaultSystemOutputDevice = try player.defaultSystemOutputDevice()

            if isUsingSystemOutputDevice {
                if let defaultSystemOutputDevice, forceUpdating || defaultSystemOutputDevice != _selectedOutputDevice {
                    selectOutputDevice(defaultSystemOutputDevice)
                    _selectedOutputDevice = defaultSystemOutputDevice

                    logger.info("Setting output device to system: \("\(defaultSystemOutputDevice)")")
                }
            } else {
                if let device = _selectedOutputDevice, try forceUpdating || device != player.selectedOutputDevice() {
                    selectOutputDevice(device)

                    logger.info("Setting output device to \("\(device)")")
                }
            }
        } catch {}
    }
}

// MARK: - Delegates

extension PlayerModel: PlayerDelegate {
    nonisolated func playerDidFinishPlaying(_: some MelodicStamp.Player) {
        Task { @MainActor in
            if let playlist, playlist.playbackLooping {
                if let currentTrack = self.currentTrack {
                    // Plays again
                    self.play(currentTrack)
                }
            } else {
                // Jumps to next track
                self.playNextTrack()
            }
        }
    }
}

extension PlayerModel: AudioPlayer.Delegate {
    nonisolated func audioPlayer(_: AudioPlayer, nowPlayingChanged nowPlaying: (any PCMDecoding)?) {
        Task { @MainActor in
            // Updates track, otherwise keeps it
            if let nowPlaying,
               let audioDecoder = nowPlaying as? AudioDecoder,
               let url = audioDecoder.inputSource.url {
                currentTrack = playlist?.getTrack(at: url)
            }

            updatePlaybackState()
            updateNowPlayingMetadataInfo(from: currentTrack)
            updateNowPlayingState(with: playbackState)
            updateNowPlayingInfo(with: playbackState)
        }
    }

    nonisolated func audioPlayer(_: AudioPlayer, playbackStateChanged playbackState: AudioPlayer.PlaybackState) {
        Task { @MainActor in
            updatePlaybackState()
            updateNowPlayingMetadataInfo(from: currentTrack)
            updateNowPlayingState(with: .init(playbackState))
            updateNowPlayingInfo(with: .init(playbackState))
        }
    }

    nonisolated func audioPlayer(_: AudioPlayer, encounteredError error: Error) {
        Task { @MainActor in
            stop()
            logger.error("\(error)")
        }
    }
}

// MARK: - Audio Visualizer

extension PlayerModel {
//    func createFFTSetup(fftSize: Int) -> FFTSetup? {
//        let fftLength = vDSP_Length(Int(round(log2(Double(fftSize)))))
//        let setup = vDSP_create_fftsetup(fftLength, FFTRadix(kFFTRadix2))
//        return setup
//    }

    func generateFrequencyBands(startFrequency: Float, endFrequency: Float, frequencyBands: Int) -> [(lowerFrequency: Float, upperFrequency: Float)] {
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
    }

    func analyze(with buffer: AVAudioPCMBuffer) -> [[Float]] {
        let channelsAmplitudes = fft(buffer)
        let aWeights = createFrequencyWeights()

        let frequencyBands = generateFrequencyBands(startFrequency: startFrequency, endFrequency: endFrequency, frequencyBands: frequencyBands)

        if spectrumBuffer.isEmpty {
            for _ in 0 ..< channelsAmplitudes.count {
                spectrumBuffer.append([Float](repeating: 0, count: frequencyBands.count))
            }
        }
        for (index, amplitudes) in channelsAmplitudes.enumerated() {
            let weightedAmplitudes = amplitudes.enumerated().map { index, element in
                element * aWeights[index]
            }
            var spectrum = frequencyBands.map {
                findMaxAmplitude(for: $0, in: weightedAmplitudes, with: Float(buffer.format.sampleRate) / Float(self.fftSize)) * 5
            }
            spectrum = highlightWaveform(spectrum: spectrum)

            let zipped = zip(spectrumBuffer[index], spectrum)
            spectrumBuffer[index] = zipped.map { $0.0 * spectrumSmooth + $0.1 * (1 - spectrumSmooth) }
        }
        return spectrumBuffer
    }

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
