import SwiftUI
import AVFoundation


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
    
    // fetchAudio is the same as getRequest.
    static func fetchAudio(route: String, completion: @escaping (Data?) -> Void) {
        getRequest(route: route, completion: completion)
    }
    
    // Alias for convenience.
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

// MARK: - AudioRecorder (used for recording in Section 2 and 3)
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
    @State private var didBeginTest = false  // Whether "Begin" has been tapped.
    @State private var isLoading = false
    // Now 4 sections:
    // Section 1: Comprehension (Questions 1 & 2)
    // Section 2: Reading prompt (formerly Question 3)
    // Section 3: Waveform Analysis
    // Section 4: Handwriting
    @State private var currentSection: Int = 1
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#FFF9C4"), Color(hex: "#FFD54F")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if !didBeginTest {
                // Pre-Test Screen.
                VStack(spacing: 30) {
                    Text("Ready to begin, \(globalUsername)?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#F57F17"))
                    
                    if isLoading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
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
                // Test Content.
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("Dyslexia Test")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "#F57F17"))
                        Text("Section \(currentSection) of 4")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#F9A825").opacity(0.85))
                        StepIndicatorView(current: currentSection, total: 4)
                    }
                    .padding(.top, 40)
                    
                    Spacer()
                    
                    Group {
                        if currentSection == 1 {
                            ComprehensionSectionView(currentSection: $currentSection)
                        } else if currentSection == 2 {
                            QuestionThreeSectionView(currentSection: $currentSection)
                        } else if currentSection == 3 {
                            WaveformSectionView(currentSection: $currentSection)
                        } else if currentSection == 4 {
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

// MARK: - Section 1: Comprehension (Questions 1 & 2)
struct ComprehensionSectionView: View {
    @Binding var currentSection: Int
    @State private var typedAnswer: String = ""
    @State private var player: AVAudioPlayer?
    @State private var isAudioFetched = false
    @State private var isLoadingAudio = false
    
    // Letter Discrimination (Question Two) states.
    @State private var letterPlayer: AVAudioPlayer?
    @State private var isLetterAudioFetched = false
    @State private var isLetterAudioLoading = false
    @State private var selectedLetter: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Question 1: Listen & Answer.
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
                
                // Question 2: Letter Discrimination.
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Question 2: Letter Discrimination")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#F57F17"))
                        Text("Tap 'Fetch Audio' then 'Play Audio' to hear the letter. Then select the correct letter below.")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#F9A825"))
                        
                        HStack(spacing: 10) {
                            Button("Fetch Audio") {
                                fetchLetterAudio()
                            }
                            .padding()
                            .background(Color(hex: "#FFB74D"))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            
                            Button("Play Audio") {
                                playLetterAudio()
                            }
                            .padding()
                            .background(isLetterAudioFetched ? Color(hex: "#FFB74D") : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .disabled(!isLetterAudioFetched)
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
                        
                        Button("Submit Answer") {
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
    
    // Question 1 functions.
    func fetchQuestionOneAudio() {
        isLoadingAudio = true
        BackendManager.getRequest(route: "/question_one") { data in
            DispatchQueue.main.async { self.isLoadingAudio = false }
            guard let data = data else {
                print("Failed to fetch question 1 audio.")
                return
            }
            DispatchQueue.main.async {
                do {
                    player = try AVAudioPlayer(data: data)
                    isAudioFetched = true
                    print("Question 1 audio player ready.")
                } catch {
                    print("Error initializing AVAudioPlayer for question 1: \(error)")
                }
            }
        }
    }
    
    func playQuestionOneAudio() {
        guard let player = player else {
            print("Audio not available yet for question 1.")
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
    
    // Letter Discrimination functions (Question 2).
    func fetchLetterAudio() {
        isLetterAudioLoading = true
        BackendManager.getRequest(route: "/question_two") { data in
            DispatchQueue.main.async {
                self.isLetterAudioLoading = false
                guard let data = data else {
                    print("Failed to fetch letter discrimination audio.")
                    return
                }
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                    try AVAudioSession.sharedInstance().setActive(true)
                    self.letterPlayer = try AVAudioPlayer(data: data)
                    self.letterPlayer?.prepareToPlay()
                    self.isLetterAudioFetched = true
                    print("Letter discrimination audio player ready.")
                } catch {
                    print("Error initializing AVAudioPlayer for letter discrimination: \(error)")
                }
            }
        }
    }
    
    func playLetterAudio() {
        guard let letterPlayer = letterPlayer else {
            print("Letter audio not available yet.")
            return
        }
        letterPlayer.play()
        print("Playing letter discrimination audio.")
    }
    
    func submitLetterAnswer() {
        guard let letter = selectedLetter else { return }
        let payload = ["question_two_answer": letter]
        BackendManager.postRequest(route: "/question_two", payload: payload) { success in
            print("Submitted letter answer: \(success)")
        }
    }
}

// MARK: - Section 2: Reading Prompt (Record Your Answer)
struct QuestionThreeSectionView: View {
    @Binding var currentSection: Int
    @State private var questionPrompt: String = "Loading..."
    @StateObject private var recorder = AudioRecorder()
    @State private var isRecording = false

    var body: some View {
        CardView {
            VStack(spacing: 20) {
                Text("Section 2: Reading Prompt")
                    .font(.headline)
                    .foregroundColor(Color(hex: "#F57F17"))
                Text("Read the prompt below, then record yourself speaking the word.")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#F9A825"))
                
                Text(questionPrompt)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .padding()
                
                // Record/Stop Button.
                Button(action: {
                    if !isRecording {
                        recorder.startRecording()
                        isRecording = true
                    } else {
                        recorder.stopRecording { fileURL in
                            if let url = fileURL {
                                uploadRecording(fileURL: url)
                            } else {
                                print("Recording failed or file URL is unavailable.")
                            }
                            isRecording = false
                        }
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
        .onAppear {
            fetchQuestionPrompt()
        }
    }
    
    // Fetch the word prompt from /question_three.
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
                print("Error parsing JSON for question 3: \(error)")
            }
        }
    }
    
    // Upload the recorded audio to /question_three.
    func uploadRecording(fileURL: URL) {
        guard let url = URL(string: "\(BackendManager.baseURL)/question_three") else {
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
        
        do {
            let fileData = try Data(contentsOf: fileURL)
            body.append(fileData)
        } catch {
            print("Error reading audio file data: \(error)")
            return
        }
        
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("Error uploading recording: \(error)")
                return
            }
            print("Recording uploaded successfully for question three.")
        }.resume()
    }
}

// MARK: - Section 3: Waveform Analysis
struct WaveformSectionView: View {
    @Binding var currentSection: Int
    @State private var questionPrompt: String = "Loading..."
    @StateObject private var recorder = AudioRecorder()
    @State private var isRecording = false

    var body: some View {
        CardView {
            VStack(spacing: 20) {
                Text("Section 3: Record Waveform")
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
                        isRecording = true
                    } else {
                        recorder.stopRecording { fileURL in
                            if let url = fileURL {
                                uploadRecording(fileURL: url, endpoint: "/question_four")
                            }
                        }
                        isRecording = false
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
                print("Error parsing JSON for question 4: \(error)")
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

// MARK: - Section 4: Handwriting
struct HandwritingSectionView: View {
    @Binding var currentSection: Int
    @State private var phrase: String = "Loading..."
    @State private var capturedImage: Image? = nil
    @State private var capturedImageURL: URL? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                CardView {
                    VStack(spacing: 16) {
                        Text("Section 4: Handwriting")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#F57F17"))
                        Text("Please write the following phrase by hand, then take a picture of your handwriting.")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#F9A825"))
                        Text(phrase)
                            .font(.body)
                            .padding()
                        
                        Button(action: playQuestionFiveAudio) {
                            Label("Play Phrase Audio", systemImage: "speaker.wave.2.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(hex: "#FFB74D"))
                                .cornerRadius(12)
                        }
                        
                        Button(action: captureImage) {
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
        .onAppear {
            fetchPhrase()
        }
    }
    
    func fetchPhrase() {
        BackendManager.getRequest(route: "/question_five") { data in
            guard let data = data else {
                print("Failed to fetch phrase for question 5.")
                return
            }
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let fetchedPhrase = jsonObject["phrase"] as? String {
                    DispatchQueue.main.async {
                        phrase = fetchedPhrase
                    }
                } else {
                    print("Invalid JSON format for question 5 phrase.")
                }
            } catch {
                print("Error parsing JSON for question 5: \(error)")
            }
        }
    }
    
    func playQuestionFiveAudio() {
        print("Playing question 5 phrase audio (if implemented).")
    }
    
    func captureImage() {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("dummy_handwriting.jpg")
        if let dummyData = "dummyImageData".data(using: .utf8) {
            do {
                try dummyData.write(to: fileURL)
                capturedImageURL = fileURL
                capturedImage = Image(systemName: "photo")
                print("Simulated image captured at \(fileURL)")
            } catch {
                print("Error writing dummy image data: \(error)")
            }
        }
    }
    
    func submitHandwritingImage() {
        guard let fileURL = capturedImageURL else {
            print("No image captured.")
            return
        }
        guard let url = URL(string: "\(BackendManager.baseURL)/question_five") else {
            print("Invalid URL for uploading handwriting image.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        let filename = fileURL.lastPathComponent
        let mimeType = "image/jpeg"
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        if let fileData = try? Data(contentsOf: fileURL) {
            body.append(fileData)
        }
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")
        request.httpBody = body
        
        URLSession.shared.dataTask(with: request) { _, _, error in
            if let error = error {
                print("Error uploading handwriting image: \(error)")
                return
            }
            print("Handwriting image uploaded successfully for question 5.")
        }.resume()
    }
}

// MARK: - Preview
struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}
