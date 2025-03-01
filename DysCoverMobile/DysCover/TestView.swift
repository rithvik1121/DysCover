import SwiftUI


// MARK: - Backend Manager
class BackendManager {
    static let baseURL = "http://192.168.1.213:8443"
    
    static func fetchAudio(route: String, completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: baseURL + route) else {
            completion(nil)
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching audio from \(route): \(error)")
                completion(nil)
                return
            }
            print("Audio fetched from \(route)")
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
                print("Error submitting answer to \(route): \(error)")
                completion(false)
                return
            }
            print("Answer submitted to \(route)")
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
                
                // Display the current section within a CardView.
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
    @State private var typedAnswer: String = ""
    @State private var selectedLetter: String? = nil
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Part 1: Audio Comprehension
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Listen & Type")
                            .font(.headline)
                            .foregroundColor(Color(hex: "#F57F17"))
                        Text("Tap below, listen carefully, then type what you hear.")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#F9A825"))
                        Button(action: playComprehensionAudio) {
                            Label("Play Audio", systemImage: "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color(hex: "#FFB74D"))
                                .cornerRadius(12)
                        }
                        TextField("Your answer...", text: $typedAnswer)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Submit Answer") {
                            submitComprehensionAnswer()
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
                                Button(letter) { selectedLetter = letter }
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
    
    // MARK: - Backend Calls for Section 1
    func playComprehensionAudio() {
        BackendManager.fetchAudio(route: "/comprehension/audio") { data in
            print("Played comprehension audio.")
        }
    }
    
    func submitComprehensionAnswer() {
        let payload = ["answer": typedAnswer]
        BackendManager.submitAnswer(route: "/comprehension/grade", payload: payload) { success in
            print("Submitted comprehension answer: \(success)")
        }
    }
    
    func playLetterAudio() {
        BackendManager.fetchAudio(route: "/comprehension/letter") { data in
            print("Played letter audio.")
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
                    Label(isRecording ? "Stop" : "Record", systemImage: isRecording ? "stop.circle.fill" : "mic.fill")
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
                    Label(isRecording ? "Stop" : "Record", systemImage: isRecording ? "stop.circle.fill" : "mic.fill")
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
        NavigationView {
            TestView()
        }
    }
}
