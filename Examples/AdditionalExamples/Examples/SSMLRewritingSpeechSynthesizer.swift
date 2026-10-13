//
//  SSMLRewritingSpeechSynthesizer.swift
//  Examples
//
//  Created by Jumpei Togashi on 2026/10/07.
//

import Combine
import Foundation
import MapboxDirections
import MapboxNavigationCore

/// Rewrites `SpokenInstruction.ssmlText` before passing it to the wrapped synthesizer.
@MainActor
final class SSMLRewritingSpeechSynthesizer: SpeechSynthesizing {
    private let base: any SpeechSynthesizing
    private let rewrite: (String) -> String

    init(base: any SpeechSynthesizing, rewrite: @escaping (String) -> String) {
        self.base = base
        self.rewrite = rewrite
    }

    var voiceInstructions: AnyPublisher<VoiceInstructionEvent, Never> { base.voiceInstructions }
    var muted: Bool { get { base.muted } set { base.muted = newValue } }
    var volume: VolumeMode { get { base.volume } set { base.volume = newValue } }
    var isSpeaking: Bool { base.isSpeaking }
    var locale: Locale? { get { base.locale } set { base.locale = newValue } }
    var managesAudioSession: Bool {
        get { base.managesAudioSession }
        set { base.managesAudioSession = newValue }
    }

    func prepareIncomingSpokenInstructions(_ instructions: [SpokenInstruction], locale: Locale?) {
        base.prepareIncomingSpokenInstructions(instructions.map(rewritten), locale: locale)
    }

    func speak(_ instruction: SpokenInstruction, during legProgress: RouteLegProgress, locale: Locale?) {
        base.speak(rewritten(instruction), during: legProgress, locale: locale)
    }

    func stopSpeaking() { base.stopSpeaking() }
    func interruptSpeaking() { base.interruptSpeaking() }

    private func rewritten(_ instruction: SpokenInstruction) -> SpokenInstruction {
        // `ssmlText` is a `let`, so rebuild the instruction and carry over foreign members.
        var copy = SpokenInstruction(
            distanceAlongStep: instruction.distanceAlongStep,
            text: instruction.text,
            ssmlText: rewrite(instruction.ssmlText)
        )
        copy.foreignMembers = instruction.foreignMembers
        return copy
    }
}
