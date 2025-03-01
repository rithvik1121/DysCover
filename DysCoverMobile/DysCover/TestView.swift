import SwiftUI
import AVFoundation  // For audio playback

class BackendManager {
    static let baseURL = "http://192.168.1.213:8443"
    
    // Generic GET request for retrieving data (e.g., audio files)
    static func getRequest(route: String, completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: baseURL + route) else {
            completion(nil)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("GET request error (\(route)): \(error)")
                completion(nil)
                return
            }
            completion(data)
        }.resume()
    }

    // ✅ Fix: Add this `postRequest` function for submitting answers or starting tests
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
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("POST request error (\(route)): \(error)")
                completion(false)
                return
            }
            completion(true)
        }.resume()
    }

    // ✅ Fix: Add `fetchAudio` method (fetches an audio file from the backend)
    static func fetchAudio(route: String, completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: baseURL + route) else {
            completion(nil)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching audio from \(route): \(error)")
                completion(nil)
                return
            }
            completion(data)
        }.resume()
    }
    
    static func submitAnswer(route: String, payload: [String: Any], completion: @escaping (Bool) -> Void) {
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
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("POST request error (\(route)): \(error)")
                completion(false)
                return
            }
            completion(true)
        }.resume()
    }

}



// MARK: - Reusable CardView with Warm Off-White Background
struct CardView<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content
            .padding()
            .background(Color(hex: "#FFFDE7").opacity(0.9))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Step Indicator View with Warm Yellows
struct StepIndicatorView: View {
    var current: Int
    var total: Int
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

// MARK: - StartTestView
struct StartTestView: View {
    @State private var username: String = ""
    @State private var navigateToTest = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Warm gradient background
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#FFF9C4"), Color(hex: "#FFD54F")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Text("Welcome to the Dyslexia Test")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#F57F17"))
                        .multilineTextAlignment(.center)
                        .padding(.top, 40)
                    
                    TextField("Enter your username", text: $username)
                        .padding()
                        .background(Color(hex: "#FFFDE7").opacity(0.8))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    Button("Start Test") {
                        startTest()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#FBC02D"))
                    
                    NavigationLink(destination: TestView(), isActive: $navigateToTest) {
                        EmptyView()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    func startTest() {
        let payload = ["username": username]
        BackendManager.postRequest(route: "/start", payload: payload) { success in
            if success {
                print("Test started for \(username)")
                DispatchQueue.main.async {
                    navigateToTest = true
                }
            } else {
                print("Failed to start test.")
            }
        }
    }
}

// MARK: - Main TestView Container
struct TestView: View {
    @State private var currentSection: Int = 1
    
    var body: some View {
        ZStack {
            // Warm yellow gradient background.
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#FFF9C4"), Color(hex: "#FFD54F")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header and Step Indicator.
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
                
                // Display the current section
                Group {
                    if currentSection == 1 {
                        ComprehensionSectionView(currentSection: $currentSection)
                    } else if currentSection == 2 {
                        PronunciationSectionView(currentSection: $currentSection)
                    } else if currentSection == 3 {
                        StutterDetectionSectionView(currentSection: $currentSection)
                    } else if currentSection == 4 {
                        HandwritingSectionView(currentSection: $currentSection)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding()
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Section 1: Comprehension
struct ComprehensionSectionView: View {
    @Binding var currentSection: Int
    
    // For "Question One"
    @State private var typedAnswer: String = ""
    @State private var player: AVAudioPlayer?
    @State private var isAudioFetched = false
    @State private var isLoadingAudio = false
    
    // For "Letter Discrimination"
    @State private var selectedLetter: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Part 1: Audio Comprehension (Question 1)
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
                
                // Part 2: Letter Discrimination
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Letter Discrimination")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#F57F17"))
                        Text("Tap below to hear a letter, then select the correct one.")
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
                            ForEach(["B", "D", "W", "M"], id: \.self) { letter in
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
    
    // MARK: - Question 1: GET /question_one -> MP3, then Play
    func fetchQuestionOneAudio() {
        isLoadingAudio = true
        BackendManager.getRequest(route: "/question_one") { data in
            DispatchQueue.main.async {
                self.isLoadingAudio = false
            }
            guard let data = data else {
                print("Failed to fetch question 1 audio.")
                return
            }
            print("Question 1 audio fetched: \(data.count) bytes")
            // Prepare AVAudioPlayer
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
    
    // MARK: - Letter Discrimination
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
    
    // MARK: - Backend Call for Section 2
    func submitPronunciationAudio() {
        let payload = ["audio": "dummyAudioData"]
        BackendManager.submitAnswer(route: "/pronunciation/grade", payload: payload) { success in
            print("Submitted pronunciation audio: \(success)")
        }
    }
}

// MARK: - Section 3: Stutter Detection
struct StutterDetectionSectionView: View {
    @Binding var currentSection: Int
    @State private var isRecording = false
    let displayedWord = "Practice" // Can be a different word.
    
    var body: some View {
        CardView {
            VStack(spacing: 20) {
                Text("Stutter Detection")
                    .font(.headline)
                    .foregroundColor(Color(hex: "#F57F17"))
                Text("Read the word aloud so we can analyze your fluency.")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "#F9A825"))
                Text(displayedWord)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .padding()
                
                Button(action: {
                    isRecording.toggle()
                    if !isRecording {
                        submitStutterAudio()
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
    }
    
    // MARK: - Backend Call for Section 3
    func submitStutterAudio() {
        let payload = ["audio": "dummyAudioData"]
        BackendManager.submitAnswer(route: "/stutter/grade", payload: payload) { success in
            print("Submitted stutter audio: \(success)")
        }
    }
}

// MARK: - Section 4: Handwriting
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
                            // Launch camera/image picker in a real app.
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
                    // Finalize the test – navigate back or show results.
                    print("Test completed")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#FBC02D"))
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Backend Calls for Section 4
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
        StartTestView()
    }
}
