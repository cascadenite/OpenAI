//
//  SpeechStore.swift
//
//
//  Created by Ihor Makhnyk on 20.11.2023.
//

import OpenAI
import SwiftUI
import AVFAudio

public final class SpeechStore: ObservableObject {
    public var openAIClient: OpenAIProtocol
    
    @Published var audioObjects: [AudioObject] = []
    
    public init(
        openAIClient: OpenAIProtocol
    ) {
        self.openAIClient = openAIClient
    }
    
    struct AudioObject: Identifiable {
        let id = UUID()
        let prompt: String
        let audioPlayer: AVAudioPlayer?
        let originResponse: AudioSpeechResult
        let format: String
    }
    
    @MainActor
    func createSpeech(_ query: AudioSpeechQuery) async {
        guard let input = query.input, !input.isEmpty else { return }
        do {
            let response = try await openAIClient.audioCreateSpeech(query: query)
            guard let data = response.audioData else { return }
            let player = try? AVAudioPlayer(data: data)
            let audioObject = AudioObject(prompt: input,
                                          audioPlayer: player,
                                          originResponse: response,
                                          format: query.responseFormat.rawValue)
            audioObjects.append(audioObject)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func getFileInDocumentsDirectory(_ data: Data, fileName: String, _ dir: @escaping (URL) -> Void) {
        if let fileURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            let saveURL = fileURL.appendingPathComponent(fileName)
            do {
                try data.write(to: saveURL)
                dir(saveURL)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
}
