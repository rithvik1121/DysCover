//
//  LearningView.swift
//  DysCover
//
//  Created by Justin Getty on 3/1/25.
//

import SwiftUI
import AVFoundation

// MARK: - OpenAI Service (Using text-davinci-003)
class OpenAIService {
    // WARNING: For production, do NOT store your API key in the source code.
    private let apiKey = "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"
    private let urlString = "https://api.openai.com/v1/completions"
    
    /// Generates a question using a pre-prompt.
    func generateQuestion(completion: @escaping (String) -> Void) {
        guard let url = URL(string: urlString) else {
            completion("Error: Invalid URL")
            return
        }
        
        // Pre-prompt that forces the output to be "Spell elephant"
        let prePrompt = "Spell elephant"
        
        let body: [String: Any] = [
            "model": "text-davinci-003",
            "prompt": prePrompt,
            "temperature": 0.7,
            "max_tokens": 20
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body)
            request.httpBody = jsonData
        } catch {
            completion("Error: Failed to encode request body")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion("Error: \(error.localizedDescription)")
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion("Error: No data returned")
                }
                return
            }
            
            // Debug: Print raw API response
            if let rawResponse = String(data: data, encoding: .utf8) {
                print("Raw API Response: \(rawResponse)")
            }
            
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = jsonResponse["choices"] as? [[String: Any]],
                   let question = choices.first?["text"] as? String {
                    DispatchQueue.main.async {
                        completion(question.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                } else {
                    DispatchQueue.main.async {
                        completion("Error: Unable to parse response")
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion("Error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}

// MARK: - Speech Synthesizer
class SpeechSynthesizer {
    private let synthesizer = AVSpeechSynthesizer()
    
    func speak(text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        synthesizer.speak(utterance)
    }
}

// MARK: - LearningView
struct LearningView: View {
    @State private var generatedQuestion: String = "Loading question..."
    @State private var userAnswer: String = ""
    @State private var gradeResult: String = ""
    
    private let correctAnswer = "elephant"
    private let openAIService = OpenAIService()
    private let speechSynthesizer = SpeechSynthesizer()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Please listen carefully:")
                .font(.title)
                .padding(.top)
            
            Text(generatedQuestion)
                .font(.headline)
                .padding()
                .multilineTextAlignment(.center)
                .border(Color.gray, width: 1)
                .cornerRadius(8)
            
            TextField("Type your answer here", text: $userAnswer)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            Button(action: checkAnswer) {
                Text("Submit")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            if !gradeResult.isEmpty {
                Text(gradeResult)
                    .font(.headline)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .onAppear(perform: loadQuestion)
    }
    
    // Load the question from OpenAI, then speak it.
    func loadQuestion() {
        openAIService.generateQuestion { question in
            self.generatedQuestion = question
            speechSynthesizer.speak(text: question)
        }
    }
    
    // Grade the user's answer.
    func checkAnswer() {
        let trimmedAnswer = userAnswer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmedAnswer == correctAnswer {
            gradeResult = "Correct!"
        } else {
            gradeResult = "Incorrect. The correct spelling is elephant."
        }
    }
}

struct LearningView_Previews: PreviewProvider {
    static var previews: some View {
        LearningView()
    }
}
