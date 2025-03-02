import SwiftUI
import AVFoundation

// MARK: - Data Models
struct LearningQuestion: Codable, Identifiable {
    let correct_answer: String
    let url: String
    var id: String { url }
}

struct LearningResponse: Codable {
    let audio_files: [LearningQuestion]
}

// MARK: - LearningBackendManager
class LearningBackendManager {
    static let baseURL = "http://192.168.1.213:8443"
    
    static func getRequest(route: String, completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: baseURL + route) else {
            completion(nil)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("GET request error (\(route)): \(error)")
                completion(nil)
                return
            }
            completion(data)
        }.resume()
    }
    
    static func postRequest(route: String, payload: [String: Any], completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: baseURL + route) else {
            completion(false)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        } catch {
            print("Error serializing JSON for \(route): \(error)")
            completion(false)
            return
        }
        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("POST request error (\(route)): \(error)")
                completion(false)
                return
            }
            completion(true)
        }.resume()
    }
    
    static func fetchAudio(route: String, completion: @escaping (Data?) -> Void) {
        getRequest(route: route, completion: completion)
    }
    
    static func submitAnswer(route: String, payload: [String: Any], completion: @escaping (Bool) -> Void) {
        postRequest(route: route, payload: payload, completion: completion)
    }
}

// MARK: - Reusable LearningCardView
struct LearningCardView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            .padding(.horizontal)
    }
}

// MARK: - LearningView
struct LearningView: View {
    @State private var learningQuestions: [LearningQuestion] = []
    @State private var currentQuestionIndex: Int = 0
    @State private var userAnswer: String = ""
    @State private var detailedFeedback: AttributedString? = nil
    @State private var percentWrong: Double? = nil
    @State private var isLoading: Bool = false
    @State private var audioPlayer: AVAudioPlayer? = nil
    @State private var showNextButton: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#FFF8E1"), Color(hex: "#FFD180")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if isLoading {
                    ProgressView("Loading Questions...")
                } else if learningQuestions.isEmpty {
                    Text("No learning questions found.")
                        .font(.title2)
                        .foregroundColor(.gray)
                } else {
                    VStack(spacing: 20) {
                        // Logo and Title
                        Image("koala_logo_v1") // Replace with your actual logo asset name
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 4))
                            .shadow(radius: 10)
                        
                        Text("Learning Dashboard")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "#E65100"))
                        
                        Text("Question \(currentQuestionIndex + 1) of \(learningQuestions.count)")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        // Question Card
                        LearningCardView {
                            VStack(spacing: 16) {
                                Button(action: playCurrentAudio) {
                                    HStack {
                                        Image(systemName: "speaker.wave.2.fill")
                                        Text("Play Audio")
                                    }
                                    .padding()
                                    .background(Color(hex: "#FFD54F"))
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                
                                TextField("Type your answer here", text: $userAnswer)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .padding(.horizontal)
                                
                                Button(action: submitAnswer) {
                                    Text("Submit Answer")
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color(hex: "#FBC02D"))
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                                
                                if let percentWrong = percentWrong, let detailedFeedback = detailedFeedback {
                                    VStack(spacing: 4) {
                                        Text("You were \(Int(percentWrong))% wrong")
                                            .font(.headline)
                                            .foregroundColor(percentWrong == 0 ? .green : .red)
                                        Text(detailedFeedback)
                                            .font(.system(size: 20, weight: .bold, design: .rounded))
                                    }
                                    .padding(.top, 8)
                                    .transition(.opacity)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if showNextButton {
                            Button(action: nextQuestion) {
                                Text("Next Question")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .animation(.easeInOut, value: detailedFeedback)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            loadLearningQuestions()
        }
    }
    
    // MARK: - Data Fetch
    private func loadLearningQuestions() {
        isLoading = true
        let route = "/get_learning_audio_files?username=\(globalUsername)"
        LearningBackendManager.getRequest(route: route) { data in
            DispatchQueue.main.async {
                self.isLoading = false
                if let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let response = try decoder.decode(LearningResponse.self, from: data)
                        self.learningQuestions = response.audio_files
                        self.currentQuestionIndex = 0
                    } catch {
                        print("Error decoding learning questions: \(error)")
                    }
                } else {
                    print("No data received for learning questions")
                }
            }
        }
    }
    
    // MARK: - Audio and Answer Methods
    private func playCurrentAudio() {
        guard !learningQuestions.isEmpty, currentQuestionIndex < learningQuestions.count else { return }
        let question = learningQuestions[currentQuestionIndex]
        let path = question.url.replacingOccurrences(of: "http://192.168.1.213:8443", with: "")
        LearningBackendManager.fetchAudio(route: path) { data in
            if let data = data {
                DispatchQueue.main.async {
                    do {
                        self.audioPlayer = try AVAudioPlayer(data: data)
                        self.audioPlayer?.play()
                    } catch {
                        print("Error playing audio: \(error)")
                    }
                }
            }
        }
    }
    
    private func submitAnswer() {
        guard !learningQuestions.isEmpty, currentQuestionIndex < learningQuestions.count else { return }
        let correctAnswer = learningQuestions[currentQuestionIndex].correct_answer
        let (comparedAttributed, percent) = compareAnswers(correct: correctAnswer, user: userAnswer)
        percentWrong = percent
        detailedFeedback = comparedAttributed
        showNextButton = true
    }
    
    private func nextQuestion() {
        userAnswer = ""
        detailedFeedback = nil
        percentWrong = nil
        showNextButton = false
        if currentQuestionIndex < learningQuestions.count - 1 {
            currentQuestionIndex += 1
        } else {
            detailedFeedback = AttributedString("You've completed all questions!")
        }
    }
    
    // MARK: - Answer Comparison Function
    private func compareAnswers(correct: String, user: String) -> (AttributedString, Double) {
        let lowerCorrect = correct.lowercased()
        let lowerUser = user.lowercased()
        var result = AttributedString("")
        var mismatches = 0
        let count = lowerCorrect.count
        
        for i in 0..<count {
            let correctIndex = lowerCorrect.index(lowerCorrect.startIndex, offsetBy: i)
            let correctChar = lowerCorrect[correctIndex]
            let charStr = String(correctChar)
            var attr = AttributedString(charStr)
            
            if i < lowerUser.count {
                let userIndex = lowerUser.index(lowerUser.startIndex, offsetBy: i)
                let userChar = lowerUser[userIndex]
                if userChar == correctChar {
                    attr.foregroundColor = .green
                } else {
                    attr.foregroundColor = .red
                    mismatches += 1
                }
            } else {
                // Missing character from user input
                attr.foregroundColor = .red
                mismatches += 1
            }
            result.append(attr)
        }
        let percentWrong = (Double(mismatches) / Double(count)) * 100
        return (result, percentWrong)
    }
}




struct LearningView_Previews: PreviewProvider {
    static var previews: some View {
        LearningView()
    }
}

