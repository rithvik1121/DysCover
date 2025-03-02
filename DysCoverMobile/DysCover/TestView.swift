import SwiftUI
import AVFoundation  // For audio playback and recording

// MARK: - BackendManager
class BackendManager {
    static let baseURL = "http://192.168.1.213:8443"
    
    // Generic GET request (for audio files or JSON)
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
    
    // Generic POST request (for submitting answers or starting tests)
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
    
    // fetchAudio is the same as getRequest
    static func fetchAudio(route: String, completion: @escaping (Data?) -> Void) {
        getRequest(route: route, completion: completion)
    }
    
    // Alias for convenience
    static func submitAnswer(route: String, payload: [String: Any], completion: @escaping (Bool) -> Void) {
        postRequest(route: route, payload: payload, completion: completion)
    }
}

// MARK: - Reusable CardView
struct CardView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding()
            .background(Color(hex: "#FFFDE7").opacity(0.9))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Step Indicator View
struct StepIndicatorView: View {
    var current: Int, total: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...total, id: \.self) { index in
                Circle()
                    .fill(index <= current ? Color(hex: "#FBC02D") : Color(hex: "#FFF59D"))
                    .frame(width: 12, height: 12)
            }
        }
    }
}

// MARK: - AudioRecorder (used for recording in Question 3 and Question 4)
class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    var audioRecorder: AVAudioRecorder?
    var recordingURL: URL?
    
    func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = UUID().uuidString + ".m4a"
            recordingURL = tempDir.appendingPathComponent(fileName)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            audioRecorder = try AVAudioRecorder(url: recordingURL!, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            print("Recording started...")
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        audioRecorder?.stop()
        print("Recording stopped: \(recordingURL?.absoluteString ?? "No URL")")
        completion(recordingURL)
    }
}

// MARK: - Data extension for multipart form data
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) { append(data) }
    }
}

// MARK: - TestView
struct TestView: View {
    @State private var didBeginTest = false  // Whether "Begin" has been tapped
    @State private var isLoading = false
    @State private var currentSection: Int = 1  // Now 5 sections total
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#FFF9C4"), Color(hex: "#FFD54F")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if !didBeginTest {
                // Pre-Test Screen with "Begin" button
                VStack(spacing: 30) {
                    Text("Ready to begin, \(globalUsername)?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#F57F17"))
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    
                    Button(action: beginTest) {
                        Text("Begin")
                            .font(.title2)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#FBC02D"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                }
            } else {
                // Test Content (Sections 1-5)
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("Dyslexia Test")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#F57F17"))
                        Text("Section \(currentSection) of 5")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#F9A825").opacity(0.85))
                        StepIndicatorView(current: currentSection, total: 5)
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    Group {
                        if currentSection == 1 {
                            ComprehensionSectionView(currentSection: $currentSection)
                        } else if currentSection == 2 {
                            PronunciationSectionView(currentSection: $currentSection)
                        } else if currentSection == 3 {
                            QuestionThreeSectionView(currentSection: $currentSection)
                        } else if currentSection == 4 {
                            WaveformSectionView(currentSection: $currentSection)
                        } else if currentSection == 5 {
                            HandwritingSectionView(currentSection: $currentSection)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
    }
    
    func beginTest() {
        isLoading = true
        let payload = ["username": globalUsername]
        BackendManager.postRequest(route: "/start", payload: payload) { success in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    print("Test started for \(globalUsername)")
                    didBeginTest = true
                } else {
                    print("Failed to start test.")
                }
            }
        }
    }
}

// MARK: - Section 1: Comprehension
struct ComprehensionSectionView: View {
    @Binding var currentSection: Int
    @State private var typedAnswer: String = ""
    @State private var player: AVAudioPlayer?
    @State private var isAudioFetched = false
    @State private var isLoadingAudio = false
    @State private var selectedLetter: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Question 1: Listen & Answer")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#F57F17"))
                        Text("Tap 'Fetch Audio', then 'Play Audio' to hear the question. Type your answer below.")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#F9A825"))
                        
                        HStack(spacing: 10) {
                            Button("Fetch Audio") {
                                fetchQuestionOneAudio()
                            }
                            .padding()
                            .background(Color(hex: "#FFB74D"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            
                            Button("Play Audio") {
                                playQuestionOneAudio()
                            }
                            .padding()
                            .background(isAudioFetched ? Color(hex: "#FFB74D") : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .disabled(!isAudioFetched)
                        }
                        
                        TextField("Your answer...", text: $typedAnswer)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Button("Submit Answer") {
                            submitQuestionOneAnswer()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: "#FBC02D"))
                    }
                }
                
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Letter Discrimination")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#F57F17"))
                        Text("Tap to hear a letter, then select the correct one.")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#F9A825"))
                        Button(action: playLetterAudio) {
                            Label("Play Letter", systemImage: "speaker.wave.2.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(hex: "#FFA726"))
                                .cornerRadius(12)
                        }
                        HStack(spacing: 20) {
                            ForEach(["b", "d", "w", "m"], id: \.self) { letter in
                                Button(letter) {
                                    selectedLetter = letter
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(selectedLetter == letter ? Color(hex: "#FFB74D") : Color(hex: "#FFCC80"))
                                .cornerRadius(8)
                                .foregroundColor(Color(hex: "#5D4037"))
                            }
                        }
                        Button("Submit Letter") {
                            submitLetterAnswer()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: "#FBC02D"))
                    }
                }
                
                Button("Next Section") {
                    currentSection = 2
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#FBC02D"))
            }
            .padding(.vertical)
        }
    }
    
    func fetchQuestionOneAudio() {
        isLoadingAudio = true
        BackendManager.getRequest(route: "/question_one") { data in
            DispatchQueue.main.async { self.isLoadingAudio = false }
            guard let data = data else {
                print("Failed to fetch question 1 audio.")
                return
            }
            print("Question 1 audio fetched: \(data.count) bytes")
            DispatchQueue.main.async {
                do {
                    player = try AVAudioPlayer(data: data)
                    isAudioFetched = true
                    print("Audio player ready.")
                } catch {
                    print("Error initializing AVAudioPlayer: \(error)")
                }
            }
        }
    }
    
    func playQuestionOneAudio() {
        guard let player = player else {
            print("Audio not available yet.")
            return
        }
        player.play()
        print("Playing question 1 audio.")
    }
    
    func submitQuestionOneAnswer() {
        let payload = ["question_one_answer": typedAnswer]
        BackendManager.postRequest(route: "/question_one", payload: payload) { success in
            print(success ? "Question 1 answer submitted." : "Failed to submit question 1 answer.")
        }
    }
    
    func playLetterAudio() {
        BackendManager.fetchAudio(route: "/comprehension/letter") { data in
            print("Played letter audio (dummy).")
        }
    }
    
    func submitLetterAnswer() {
        guard let letter = selectedLetter else { return }
        let payload = ["letter": letter]
        BackendManager.submitAnswer(route: "/comprehension/gradeLetter", payload: payload) { success in
            print("Submitted letter answer: \(success)")
        }
    }
}

// MARK: - Section 2: Pronunciation
struct PronunciationSectionView: View {
    @Binding var currentSection: Int
    @State private var isRecording = false
    let displayedWord = "Example" // Ideally fetched from backend.
    
    var body: some View {
        CardView {
            VStack(spacing: 20) {
                Text("Pronunciation")
                    .font(.headline)
                    .foregroundColor(Color(hex: "#F57F17"))
                Text("Read the word aloud. Tap 'Record' to capture your pronunciation.")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#F9A825"))
                Text(displayedWord)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .padding()
                
                Button(action: {
                    isRecording.toggle()
                    if !isRecording {
                        submitPronunciationAudio()
                    }
                }) {
                    Label(isRecording ? "Stop" : "Record",
                          systemImage: isRecording ? "stop.circle.fill" : "mic.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(isRecording ? Color(hex: "#FB8C00") : Color(hex: "#FFA726"))
                        .cornerRadius(12)
                }
                
                Button("Next Section") {
                    currentSection = 3
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#FBC02D"))
            }
        }
    }
    
    func submitPronunciationAudio() {
        let payload = ["audio": "dummyAudioData"]
        BackendManager.submitAnswer(route: "/pronunciation/grade", payload: payload) { success in
            print("Submitted pronunciation audio: \(success)")
        }
    }
}

// MARK: - Section 3: Question Three (Recording)
struct QuestionThreeSectionView: View {
    @Binding var currentSection: Int
    @State private var questionPrompt: String = "Loading..."
    @StateObject private var recorder = AudioRecorder()
    @State private var isRecording = false

    var body: some View {
        CardView {
            VStack(spacing: 20) {
                Text("Question 3: Record Your Answer")
                    .font(.headline)
                    .foregroundColor(Color(hex: "#F57F17"))
                Text("Listen to the prompt below, then record yourself speaking the word.")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#F9A825"))
                
                Text(questionPrompt)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .padding()
                
                Button(action: {
                    if !isRecording {
                        recorder.startRecording()
                    } else {
                        recorder.stopRecording { fileURL in
                            if let url = fileURL {
                                uploadRecording(fileURL: url, endpoint: "/question_three")
                            }
                        }
                    }
                    isRecording.toggle()
                }) {
                    Label(isRecording ? "Stop" : "Record",
                          systemImage: isRecording ? "stop.circle.fill" : "mic.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(isRecording ? Color(hex: "#FB8C00") : Color(hex: "#FFA726"))
                        .cornerRadius(12)
                }
                
                Button("Next Section") {
                    currentSection = 4
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#FBC02D"))
            }
        }
        .onAppear {
            fetchQuestionPrompt()
        }
    }
    
    func fetchQuestionPrompt() {
        BackendManager.getRequest(route: "/question_three") { data in
            guard let data = data else {
                print("Failed to fetch question 3 prompt.")
                return
            }
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let prompt = jsonObject["word_prompt"] as? String {
                    DispatchQueue.main.async {
                        questionPrompt = prompt
                    }
                } else {
                    print("Invalid JSON format for question 3 prompt.")
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }
    }
    
    func uploadRecording(fileURL: URL, endpoint: String) {
        guard let url = URL(string: "\(BackendManager.baseURL)\(endpoint)") else {
            print("Invalid URL for uploading recording.")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        let filename = fileURL.lastPathComponent
        let mimeType = "audio/m4a"
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        if let fileData = try? Data(contentsOf: fileURL) {
            body.append(fileData)
        }
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("Error uploading recording to \(endpoint): \(error)")
                return
            }
            print("Recording uploaded successfully for \(endpoint).")
        }.resume()
    }
}

// MARK: - Section 4: Waveform Analysis (New)
struct WaveformSectionView: View {
    @Binding var currentSection: Int
    @State private var questionPrompt: String = "Loading..."
    @StateObject private var recorder = AudioRecorder()
    @State private var isRecording = false

    var body: some View {
        CardView {
            VStack(spacing: 20) {
                Text("Question 4: Record Waveform")
                    .font(.headline)
                    .foregroundColor(Color(hex: "#F57F17"))
                Text("Record your waveform for analysis.")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#F9A825"))
                
                Text(questionPrompt)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .padding()
                
                Button(action: {
                    if !isRecording {
                        recorder.startRecording()
                    } else {
                        recorder.stopRecording { fileURL in
                            if let url = fileURL {
                                // Upload to /question_four endpoint
                                uploadRecording(fileURL: url, endpoint: "/question_four")
                            }
                        }
                    }
                    isRecording.toggle()
                }) {
                    Label(isRecording ? "Stop" : "Record",
                          systemImage: isRecording ? "stop.circle.fill" : "mic.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding()
                        .background(isRecording ? Color(hex: "#FB8C00") : Color(hex: "#FFA726"))
                        .cornerRadius(12)
                }
                
                Button("Next Section") {
                    currentSection = 5
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#FBC02D"))
            }
        }
        .onAppear {
            fetchQuestionPrompt()
        }
    }
    
    func fetchQuestionPrompt() {
        BackendManager.getRequest(route: "/question_four") { data in
            guard let data = data else {
                print("Failed to fetch question 4 prompt.")
                return
            }
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let prompt = jsonObject["word_prompt"] as? String {
                    DispatchQueue.main.async {
                        questionPrompt = prompt
                    }
                } else {
                    print("Invalid JSON format for question 4 prompt.")
                }
            } catch {
                print("Error parsing JSON: \(error)")
            }
        }
    }
    
    func uploadRecording(fileURL: URL, endpoint: String) {
        guard let url = URL(string: "\(BackendManager.baseURL)\(endpoint)") else {
            print("Invalid URL for uploading recording.")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        let filename = fileURL.lastPathComponent
        let mimeType = "audio/m4a"
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"audio\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        if let fileData = try? Data(contentsOf: fileURL) {
            body.append(fileData)
        }
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("Error uploading recording to \(endpoint): \(error)")
                return
            }
            print("Recording uploaded successfully for \(endpoint).")
        }.resume()
    }
}

// MARK: - Section 5: Handwriting (Unchanged)
struct HandwritingSectionView: View {
    @Binding var currentSection: Int
    @State private var capturedImage: Image? = nil
    let sentenceToWrite = "The quick brown fox jumps over the lazy dog." // Example sentence.
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CardView {
                    VStack(spacing: 16) {
                        Text("Handwriting")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#F57F17"))
                        Text("Listen to the sentence and write it by hand. Then take a picture.")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#F9A825"))
                        Text(sentenceToWrite)
                            .font(.body)
                            .padding()
                        
                        Button(action: playHandwritingAudio) {
                            Label("Play Sentence", systemImage: "speaker.wave.2.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(hex: "#FFB74D"))
                                .cornerRadius(12)
                        }
                        Button(action: {
                            // In a real app, launch camera/image picker.
                            capturedImage = Image(systemName: "photo")
                        }) {
                            Label("Take Picture", systemImage: "camera.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(hex: "#FFA726"))
                                .cornerRadius(12)
                        }
                        
                        if let image = capturedImage {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(10)
                        }
                        
                        Button("Submit Handwriting") {
                            submitHandwritingImage()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: "#FBC02D"))
                    }
                }
                
                Button("Finish Test") {
                    print("Test completed")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#FBC02D"))
            }
            .padding(.vertical)
        }
    }
    
    func playHandwritingAudio() {
        BackendManager.fetchAudio(route: "/handwriting/audio") { data in
            print("Played handwriting audio.")
        }
    }
    
    func submitHandwritingImage() {
        let payload = ["image": "dummyImageData"]
        BackendManager.submitAnswer(route: "/handwriting/grade", payload: payload) { success in
            print("Submitted handwriting image: \(success)")
        }
    }
}



// MARK: - Preview
struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}
