import SwiftUI
import AVFoundation
import PhotosUI

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
    
    // Generic POST request (for submitting answers or starting/finishing tests)
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
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: "#FFFDE7").opacity(0.95))
        )
        .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 4)
    }
}

// MARK: - Step Indicator View
struct StepIndicatorView: View {
    var current: Int
    var total: Int
    
    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...total, id: \.self) { index in
                Circle()
                    .fill(
                        index <= current
                        ? Color(hex: "#FFCA28")
                        : Color(hex: "#FFF59D")
                    )
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle().stroke(Color(hex: "#FFCA28"),
                                        lineWidth: index <= current ? 0 : 1)
                    )
                    .scaleEffect(index == current ? 1.2 : 1.0)
                    .animation(.easeInOut, value: current)
            }
        }
    }
}

// MARK: - AudioRecorder
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
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

// MARK: - TestView (Main Entry)
struct TestView: View {
    @State private var didBeginTest = false
    @State private var isLoading = false
    @State private var currentSection: Int = 1
    @State private var finishTestCompleted = false  // Triggers navigation on finishing
    
    var body: some View {
        NavigationView {
            ZStack {
                // Softer background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(hex: "#FFF8E1"),
                        Color(hex: "#FFD180"),
                        Color(hex: "#FFC107")
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if !didBeginTest {
                    // Pre-Test Screen
                    VStack(spacing: 40) {
                        Spacer()
                        
                        Text("Welcome, \(globalUsername)!")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(Color(hex: "#F57F17"))
                            .padding(.top, 30)
                        
                        Text("Ready for your Dyslexia Screening?\nLet's get started!")
                            .font(.title2)
                            .foregroundColor(Color(hex: "#6D4C41").opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 50)
                        
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#F57F17")))
                                .scaleEffect(1.8)
                                .padding(.top, 20)
                        }
                        
                        Button(action: beginTest) {
                            Text("Begin Test")
                                .font(.title2)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
                                .background(Color(hex: "#FFCA28"))
                                .foregroundColor(.white)
                                .cornerRadius(18)
                                .shadow(color: .gray.opacity(0.4), radius: 4, x: 0, y: 4)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .transition(.opacity)
                } else {
                    // Test in Progress
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 12) {
                            Text("Dyslexia Test")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "#E65100"))
                            
                            Text("Section \(currentSection) of 4")
                                .font(.title3)
                                .foregroundColor(Color(hex: "#6D4C41").opacity(0.8))
                            
                            StepIndicatorView(current: currentSection, total: 4)
                        }
                        .padding(.top, 50)
                        
                        Spacer()
                        
                        // Animated Section Content
                        Group {
                            switch currentSection {
                            case 1:
                                ComprehensionSectionView(currentSection: $currentSection)
                                    .transition(.move(edge: .trailing))
                            case 2:
                                QuestionThreeSectionView(currentSection: $currentSection)
                                    .transition(.move(edge: .trailing))
                            case 3:
                                WaveformSectionView(currentSection: $currentSection)
                                    .transition(.move(edge: .trailing))
                            case 4:
                                HandwritingSectionView(currentSection: $currentSection)
                                    .transition(.move(edge: .trailing))
                            default:
                                EmptyView()
                            }
                        }
                        .animation(.easeInOut, value: currentSection)
                        
                        Spacer()
                        
                        // Finish Button
                        Button(action: finishTest) {
                            Text("Finish Test")
                                .font(.title2)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 14)
                                .background(Color(hex: "#FF7043"))
                                .foregroundColor(.white)
                                .cornerRadius(18)
                                .shadow(color: .gray.opacity(0.4), radius: 4, x: 0, y: 4)
                        }
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                    .transition(.opacity)
                }
            }
            // NavigationLink to Dashboard once finishing
            .background(
                NavigationLink(
                    destination: DashboardView(username: globalUsername, className: globalClassName),
                    isActive: $finishTestCompleted
                ) {
                    EmptyView()
                }
                .hidden()
            )
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func beginTest() {
        isLoading = true
        let payload = ["username": globalUsername]
        
        BackendManager.postRequest(route: "/start", payload: payload) { success in
            DispatchQueue.main.async {
                self.isLoading = false
                if success {
                    print("Test started for \(globalUsername)")
                    withAnimation {
                        self.didBeginTest = true
                    }
                } else {
                    print("Failed to start test.")
                }
            }
        }
    }
    
    private func finishTest() {
        let payload = ["username": globalUsername]
        
        BackendManager.postRequest(route: "/finish_test", payload: payload) { success in
            DispatchQueue.main.async {
                if success {
                    print("Finish test POST succeeded.")
                    finishTestCompleted = true
                } else {
                    print("Finish test POST failed.")
                }
            }
        }
    }
}

// MARK: - SECTION 1: Comprehension (Questions 1 & 2)
// ADJUSTED so the text field is never covered by the keyboard:
struct ComprehensionSectionView: View {
    @Binding var currentSection: Int
    
    // Q1
    @State private var typedAnswer: String = ""
    @State private var playerQ1: AVAudioPlayer?
    @State private var isQ1AudioReady = false
    
    // Q2 (Letter Discrimination)
    @State private var letterPlayer: AVAudioPlayer?
    @State private var isLetterAudioReady = false
    @State private var selectedLetter: String? = nil
    
    var body: some View {
        // Use a ScrollView with extra bottom padding to avoid keyboard overlap
        ScrollView {
            VStack(spacing: 30) {
                // Question 1 Card
                CardView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Question 1: Listen & Answer")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#F57F17"))
                        
                        Text("Tap 'Play Audio' to hear the question.\nType your answer below:")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#5D4037").opacity(0.8))
                        
                        Button(action: { playQ1Audio() }) {
                            Label("Play Audio", systemImage: "speaker.wave.2.fill")
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isQ1AudioReady ? Color(hex: "#FFD54F") : Color.gray)
                                .cornerRadius(10)
                        }
                        .disabled(!isQ1AudioReady)
                        
                        TextField("Your answer", text: $typedAnswer)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.top, 6)
                    }
                }
                
                // Question 2 Card
                CardView {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Question 2: Letter Discrimination")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#F57F17"))
                        
                        Text("Tap 'Play Audio' to hear a letter.\nPick the matching letter below.")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#5D4037").opacity(0.8))
                        
                        Button(action: { playLetterAudio() }) {
                            Label("Play Audio", systemImage: "speaker.wave.2.fill")
                                .foregroundColor(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(isLetterAudioReady ? Color(hex: "#FFD54F") : Color.gray)
                                .cornerRadius(10)
                        }
                        .disabled(!isLetterAudioReady)
                        
                        HStack(spacing: 20) {
                            ForEach(["b", "d", "w", "m"], id: \.self) { letter in
                                Button(action: {
                                    selectedLetter = letter
                                }) {
                                    Text(letter)
                                        .font(.title2)
                                        .foregroundColor(
                                            selectedLetter == letter
                                            ? .white
                                            : Color(hex: "#5D4037")
                                        )
                                        .frame(width: 44, height: 44)
                                        .background(
                                            Circle().fill(
                                                selectedLetter == letter
                                                ? Color(hex: "#FFB74D")
                                                : Color(hex: "#FFF59D")
                                            )
                                        )
                                }
                            }
                        }
                    }
                }
                
                // Next Section (submits Q1 & Q2 automatically)
                Button {
                    submitAnswersThenNext()
                } label: {
                    Text("Next Section")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color(hex: "#FBC02D"))
                        .cornerRadius(14)
                }
                .padding(.bottom, 10)
            }
            .padding(.vertical, 15)
            .padding(.bottom, 150) // Extra space so keyboard doesn't obscure the text field
        }
        .onAppear {
            fetchQ1Audio()
            fetchQ2Audio()
        }
        // This helps to dismiss the keyboard if the user scrolls or taps away
        .scrollDismissesKeyboard(.interactively)
    }
    
    // Q1 Audio
    private func fetchQ1Audio() {
        BackendManager.fetchAudio(route: "/question_one") { data in
            guard let data = data else {
                print("Failed to fetch Q1 audio.")
                return
            }
            DispatchQueue.main.async {
                do {
                    self.playerQ1 = try AVAudioPlayer(data: data)
                    self.isQ1AudioReady = true
                    print("Q1 audio is ready.")
                } catch {
                    print("Error initializing Q1 audio: \(error)")
                }
            }
        }
    }
    
    private func playQ1Audio() {
        playerQ1?.play()
        print("Playing Q1 audio.")
    }
    
    private func submitQuestionOneAnswer() {
        let payload: [String: Any] = ["question_one_answer": typedAnswer]
        BackendManager.submitAnswer(route: "/question_one", payload: payload) { success in
            print(success ? "Q1 answer submitted." : "Failed to submit Q1 answer.")
        }
    }
    
    // Q2 Audio
    private func fetchQ2Audio() {
        BackendManager.fetchAudio(route: "/question_two") { data in
            guard let data = data else {
                print("Failed to fetch Q2 letter audio.")
                return
            }
            DispatchQueue.main.async {
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                    try AVAudioSession.sharedInstance().setActive(true)
                    
                    self.letterPlayer = try AVAudioPlayer(data: data)
                    self.letterPlayer?.prepareToPlay()
                    self.isLetterAudioReady = true
                    print("Q2 letter audio is ready.")
                } catch {
                    print("Error initializing Q2 letter audio: \(error)")
                }
            }
        }
    }
    
    private func playLetterAudio() {
        letterPlayer?.play()
        print("Playing letter audio.")
    }
    
    private func submitLetterAnswer() {
        guard let letter = selectedLetter else { return }
        let payload: [String: Any] = ["question_two_answer": letter]
        BackendManager.submitAnswer(route: "/question_two", payload: payload) { success in
            print(success ? "Q2 letter answer submitted." : "Failed to submit Q2 letter answer.")
        }
    }
    
    // Combined submission
    private func submitAnswersThenNext() {
        submitQuestionOneAnswer()
        submitLetterAnswer()
        
        withAnimation {
            currentSection = 2
        }
    }
}

// MARK: - SECTION 2: Reading Prompt
struct QuestionThreeSectionView: View {
    @Binding var currentSection: Int
    
    @State private var questionPrompt: String = "Loading..."
    @StateObject private var recorder = AudioRecorder()
    @State private var isRecording = false
    
    var body: some View {
        CardView {
            VStack(spacing: 24) {
                Text("Section 2: Reading Prompt")
                    .font(.title3)
                    .foregroundColor(Color(hex: "#E65100"))
                
                Text(questionPrompt)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#5D4037"))
                    .padding(.horizontal, 10)
                    .multilineTextAlignment(.center)
                
                // Record / Stop
                Button {
                    toggleRecording()
                } label: {
                    Label(isRecording ? "Stop" : "Record",
                          systemImage: isRecording ? "stop.circle.fill" : "mic.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding()
                        .background(isRecording ? Color(hex: "#FB8C00") : Color(hex: "#FFA726"))
                        .cornerRadius(12)
                        .shadow(radius: 3)
                }
                
                Button("Next Section") {
                    withAnimation {
                        currentSection = 3
                    }
                }
                .font(.title3)
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#FFC107"))
            }
        }
        .onAppear {
            fetchQuestionPrompt()
        }
    }
    
    private func fetchQuestionPrompt() {
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
                    print("Invalid JSON for Q3 prompt.")
                }
            } catch {
                print("Error parsing Q3 JSON: \(error)")
            }
        }
    }
    
    private func toggleRecording() {
        if !isRecording {
            recorder.startRecording()
            isRecording = true
        } else {
            recorder.stopRecording { fileURL in
                if let url = fileURL {
                    uploadRecording(fileURL: url)
                }
                isRecording = false
            }
        }
    }
    
    private func uploadRecording(fileURL: URL) {
        guard let url = URL(string: "\(BackendManager.baseURL)/question_three") else {
            print("Invalid Q3 upload URL.")
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
                print("Error uploading Q3 recording: \(error)")
            } else {
                print("Q3 recording uploaded successfully.")
            }
        }.resume()
    }
}

// MARK: - SECTION 3: Waveform Analysis
struct WaveformSectionView: View {
    @Binding var currentSection: Int
    
    @State private var questionPrompt: String = "Loading..."
    @StateObject private var recorder = AudioRecorder()
    @State private var isRecording = false
    
    var body: some View {
        CardView {
            VStack(spacing: 24) {
                Text("Section 3: Waveform Analysis")
                    .font(.title3)
                    .foregroundColor(Color(hex: "#E65100"))
                
                Text(questionPrompt)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#5D4037"))
                    .padding(.horizontal, 10)
                    .multilineTextAlignment(.center)
                
                Button {
                    toggleRecording()
                } label: {
                    Label(isRecording ? "Stop" : "Record",
                          systemImage: isRecording ? "stop.circle.fill" : "mic.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                        .padding()
                        .background(isRecording ? Color(hex: "#FB8C00") : Color(hex: "#FFA726"))
                        .cornerRadius(12)
                        .shadow(radius: 3)
                }
                
                Button("Next Section") {
                    withAnimation {
                        currentSection = 4
                    }
                }
                .font(.title3)
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#FFC107"))
            }
        }
        .onAppear {
            fetchQuestionPrompt()
        }
    }
    
    private func fetchQuestionPrompt() {
        BackendManager.getRequest(route: "/question_four") { data in
            guard let data = data else {
                print("Failed to fetch Q4 prompt.")
                return
            }
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let prompt = jsonObject["word_prompt"] as? String {
                    DispatchQueue.main.async {
                        questionPrompt = prompt
                    }
                } else {
                    print("Invalid JSON for Q4 prompt.")
                }
            } catch {
                print("Error parsing Q4 JSON: \(error)")
            }
        }
    }
    
    private func toggleRecording() {
        if !isRecording {
            recorder.startRecording()
            isRecording = true
        } else {
            recorder.stopRecording { fileURL in
                if let url = fileURL {
                    uploadRecording(fileURL: url)
                }
                isRecording = false
            }
        }
    }
    
    private func uploadRecording(fileURL: URL) {
        guard let url = URL(string: "\(BackendManager.baseURL)/question_four") else {
            print("Invalid Q4 upload URL.")
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
                print("Error uploading Q4 recording: \(error)")
            } else {
                print("Q4 recording uploaded successfully.")
            }
        }.resume()
    }
}

// MARK: - SECTION 4: Handwriting
// REPLACED the "captureImage()" with a real Image Picker flow:
struct HandwritingSectionView: View {
    @Binding var currentSection: Int
    
    @State private var phrase: String = "Loading..."
    
    // Q5 Audio
    @State private var question5Player: AVAudioPlayer?
    @State private var isQ5AudioReady = false
    
    // The image the user picks or takes
    @State private var inputUIImage: UIImage?
    @State private var capturedImage: Image?
    
    // Whether to show the image picker
    @State private var isShowingImagePicker = false
    
    var body: some View {
        CardView {
            VStack(spacing: 24) {
                Text("Section 4: Handwriting")
                    .font(.title3)
                    .foregroundColor(Color(hex: "#E65100"))
                
                Text(phrase)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#5D4037"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                
                // Play Audio (Question 5)
                Button {
                    playQuestionFiveAudio()
                } label: {
                    Label("Play Phrase Audio", systemImage: "speaker.wave.2.fill")
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(isQ5AudioReady ? Color(hex: "#FFD54F") : Color.gray)
                        .cornerRadius(10)
                }
                .disabled(!isQ5AudioReady)
                
                // Actual camera or photo library
                Button {
                    isShowingImagePicker = true
                } label: {
                    Label("Take/Choose Picture", systemImage: "camera.fill")
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 14)
                        .background(Color(hex: "#FFA726"))
                        .cornerRadius(10)
                }
                
                if let capturedImage = capturedImage {
                    capturedImage
                        .resizable()
                        .scaledToFit()
                        .frame(height: 220)
                        .cornerRadius(10)
                }
            }
        }
        .onAppear {
            fetchPhrase()
            fetchQ5Audio()  // fetch audio for Q5 route
        }
        // Present the image picker as a sheet
        .sheet(isPresented: $isShowingImagePicker, onDismiss: loadImage) {
            ImagePicker(selectedImage: $inputUIImage)
        }
    }
    
    // 1) Fetch the phrase from /question_five
    private func fetchPhrase() {
        BackendManager.getRequest(route: "/question_five") { data in
            guard let data = data else {
                print("Failed to fetch Q5 phrase data.")
                return
            }
            do {
                if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let fetchedPhrase = jsonObject["phrase"] as? String {
                    DispatchQueue.main.async {
                        phrase = fetchedPhrase
                    }
                } else {
                    print("No phrase or invalid JSON for Q5.")
                }
            } catch {
                print("Error reading Q5 phrase JSON: \(error)")
            }
        }
    }
    
    // 2) Fetch audio from /question_five
    private func fetchQ5Audio() {
        BackendManager.fetchAudio(route: "/question_five") { data in
            guard let data = data else {
                print("Failed to fetch Q5 audio.")
                return
            }
            DispatchQueue.main.async {
                do {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                    try AVAudioSession.sharedInstance().setActive(true)
                    
                    self.question5Player = try AVAudioPlayer(data: data)
                    self.isQ5AudioReady = true
                    print("Q5 audio is ready.")
                } catch {
                    print("Error initializing Q5 audio: \(error)")
                }
            }
        }
    }
    
    private func playQuestionFiveAudio() {
        question5Player?.play()
        print("Playing Q5 audio.")
    }
    
    // Called when the image picker is dismissed
    private func loadImage() {
        guard let uiImage = inputUIImage else { return }
        // Display the image in SwiftUI
        capturedImage = Image(uiImage: uiImage)
        
        // Convert to Data & upload
        do {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".jpg")
            
            if let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                try jpegData.write(to: tempURL)
                print("Image saved to temp URL: \(tempURL)")
                submitHandwritingImage(fileURL: tempURL)
            }
        } catch {
            print("Error writing captured image to disk: \(error)")
        }
    }
    
    // Upload the user-chosen or camera-taken image
    private func submitHandwritingImage(fileURL: URL) {
        guard let url = URL(string: "\(BackendManager.baseURL)/question_five") else {
            print("Invalid Q5 upload URL.")
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
                print("Error uploading Q5 handwriting image: \(error)")
            } else {
                print("Q5 handwriting image uploaded successfully.")
            }
        }.resume()
    }
}

// MARK: - ImagePicker for SwiftUI
// A simple UIViewControllerRepresentable that supports camera or photo library
struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var selectedImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        
        // If you want the camera only, set .sourceType = .camera
        // For letting user choose library or camera, you might build a custom sheet or system UI.
        // Here, we do the photoLibrary as an example:
        picker.sourceType = .camera // or .photoLibrary
        picker.delegate = context.coordinator
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // no-op
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // Coordinator to handle delegate methods
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.selectedImage = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview
struct TestView_Previews: PreviewProvider {
    static var previews: some View {
        TestView()
    }
}


