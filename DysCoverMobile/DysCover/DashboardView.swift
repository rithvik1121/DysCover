import SwiftUI

// MARK: - Data Model
struct TestRecord: Identifiable, Codable {
    let test_id: Int
    let username: String
    let className: String
    let question1: String?
    let question2: String?
    let question3: String?
    let question4: String?
    let question5: String?
    let spelling_accuracy: Double?
    let stutter_metric: String?
    let speaking_accuracy: String?
    let handwriting_metric: Double?
    let total_score: Double?
    
    var id: Int { test_id }
    
    enum CodingKeys: String, CodingKey {
        case test_id
        case username
        case className = "class"
        case question1, question2, question3, question4, question5
        case spelling_accuracy, stutter_metric, speaking_accuracy, handwriting_metric, total_score
    }
}

// MARK: - VerticalBarView
struct VerticalBarView: View {
    let progress: CGFloat  // 0...1
    let color: Color
    let label: String
    let valueText: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(valueText)
                .font(.headline)
                .foregroundColor(color)
            
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.15))
                    .frame(width: 30, height: 160)
                
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 30, height: 160 * progress)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(.black)
        }
        .padding(.horizontal, 6)
    }
}

// MARK: - AestheticLineChartView
struct AestheticLineChartView: View {
    let dataPoints: [Double]
    let title: String
    var lineColor: Color = .blue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .padding(.bottom, 2)
            
            GeometryReader { geo in
                ZStack {
                    // Fill area under the line
                    if dataPoints.count > 1 {
                        createClosedPath(in: geo)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        lineColor.opacity(0.3),
                                        .clear
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    
                    // Gradient-stroked line
                    createLinePath(in: geo)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    lineColor.opacity(0.85),
                                    lineColor.opacity(0.4)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )
                    
                    // Data point circles
                    if dataPoints.count > 1 {
                        ForEach(dataPoints.indices, id: \.self) { index in
                            let (x, y) = pointPosition(in: geo, index: index)
                            Circle()
                                .fill(lineColor)
                                .frame(width: 9, height: 9)
                                .position(x: x, y: y)
                                .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
                        }
                    }
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "#FFFCE8"),
                            Color(hex: "#F3E5F5").opacity(0.35)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    // Optional stroke
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(lineColor.opacity(0.3), lineWidth: 1)
                    )
                )
                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            }
            .frame(height: 240)
        }
        .padding(8)
    }
    
    // MARK: - Path Helpers
    private func createLinePath(in geo: GeometryProxy) -> Path {
        var path = Path()
        guard dataPoints.count > 1 else { return path }
        
        let width  = geo.size.width
        let height = geo.size.height
        let (minVal, maxVal) = minMax()
        let range = maxVal - minVal == 0 ? 1 : (maxVal - minVal)
        let step = width / CGFloat(dataPoints.count - 1)
        
        for (index, value) in dataPoints.enumerated() {
            let x = CGFloat(index) * step
            let y = height - ((CGFloat(value - minVal) / CGFloat(range)) * height)
            
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
    
    private func createClosedPath(in geo: GeometryProxy) -> Path {
        var path = createLinePath(in: geo)
        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
        path.addLine(to: CGPoint(x: 0, y: geo.size.height))
        path.closeSubpath()
        return path
    }
    
    private func pointPosition(in geo: GeometryProxy, index: Int) -> (CGFloat, CGFloat) {
        let width  = geo.size.width
        let height = geo.size.height
        let (minVal, maxVal) = minMax()
        let range = maxVal - minVal == 0 ? 1 : (maxVal - minVal)
        let step = width / CGFloat(dataPoints.count - 1)
        let value = dataPoints[index]
        
        let x = CGFloat(index) * step
        let y = height - ((CGFloat(value - minVal) / CGFloat(range)) * height)
        return (x, y)
    }
    
    private func minMax() -> (Double, Double) {
        (dataPoints.min() ?? 0, dataPoints.max() ?? 1)
    }
}

// MARK: - DashboardView
struct DashboardView: View {
    let username: String
    let className: String
    
    @State private var testRecords: [TestRecord] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    // Averages
    private var avgTotalScore: Double {
        let scores = testRecords.compactMap { $0.total_score }
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }
    private var avgSpelling: Double {
        let scores = testRecords.compactMap { $0.spelling_accuracy }
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }
    private var avgHandwriting: Double {
        let scores = testRecords.compactMap { $0.handwriting_metric }
        return scores.isEmpty ? 0 : scores.reduce(0, +) / Double(scores.count)
    }
    
    // Convert them to 0...1 for vertical bars
    private var totalScoreProgress: CGFloat { CGFloat(avgTotalScore / 100) }
    private var comprehensionProgress: CGFloat { CGFloat(avgSpelling / 100) }
    private var handwritingProgress: CGFloat { CGFloat(avgHandwriting / 100) }
    private var confusionProgress: CGFloat { CGFloat((100 - avgTotalScore) / 100) }
    
    // Trend data
    private var totalScoreTrend: [Double] { testRecords.compactMap { $0.total_score } }
    private var spellingTrend: [Double] { testRecords.compactMap { $0.spelling_accuracy } }
    private var handwritingTrend: [Double] { testRecords.compactMap { $0.handwriting_metric } }
    
    var body: some View {
        ZStack {
            // Warm gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#FFF9C4"),
                    Color(hex: "#FFD54F")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)
            
            if isLoading {
                ProgressView("Loading data...")
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Logo at the top
                        Image("koala_logo_v1") // <--- Replace with your actual logo asset name
                            .resizable()
                            .scaledToFit()
                            .frame(width: 120, height: 120)
                            .padding(.top, 20)
                        
                        // Titles
                        Text("Hello, \(globalUsername)")
                            .font(.system(size: 34, weight: .heavy, design: .default))
                            .foregroundColor(.brown)
                            .multilineTextAlignment(.center)
                        
                        Text("Class: \(globalClassName)")
                            .font(.title3)
                            .foregroundColor(.brown.opacity(0.8))
                        
                        HStack(spacing: 16) {
                                                    NavigationLink(destination: TestView()) {
                                                        Text("Take Test")
                                                            .font(.headline)
                                                            .foregroundColor(.white)
                                                            .padding(.vertical, 12)
                                                            .padding(.horizontal, 24)
                                                            .background(Color.blue)
                                                            .cornerRadius(12)
                                                            .shadow(radius: 3)
                                                    }
                                                    
                                                    NavigationLink(destination: LearningView()) {
                                                        Text("Learning")
                                                            .font(.headline)
                                                            .foregroundColor(.white)
                                                            .padding(.vertical, 12)
                                                            .padding(.horizontal, 24)
                                                            .background(Color.green)
                                                            .cornerRadius(12)
                                                            .shadow(radius: 3)
                                                    }
                                                }
                                                .padding(.top, 10)
                                                
                                                Divider()
                                                    .padding(.horizontal, 50)
                                                    .padding(.top, 10)
                        
                        // Horizontal bar set
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                VerticalBarView(
                                    progress: totalScoreProgress,
                                    color: .red,
                                    label: "Total Score",
                                    valueText: "\(Int(avgTotalScore))%"
                                )
                                VerticalBarView(
                                    progress: comprehensionProgress,
                                    color: .green,
                                    label: "Comprehension",
                                    valueText: "\(Int(avgSpelling))%"
                                )
                                VerticalBarView(
                                    progress: handwritingProgress,
                                    color: .blue,
                                    label: "Handwriting",
                                    valueText: "\(Int(avgHandwriting))%"
                                )
                                VerticalBarView(
                                    progress: confusionProgress,
                                    color: .gray,
                                    label: "Confusion",
                                    valueText: "\(Int(100 - avgTotalScore))%"
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        // Trends Section
                        if !testRecords.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Trends")
                                    .font(.headline)
                                    .foregroundColor(.brown)
                                    .padding(.horizontal)
                                
                                if !totalScoreTrend.isEmpty {
                                    AestheticLineChartView(
                                        dataPoints: totalScoreTrend,
                                        title: "Total Score Trend",
                                        lineColor: .red
                                    )
                                    .padding(.horizontal)
                                }
                                if !spellingTrend.isEmpty {
                                    AestheticLineChartView(
                                        dataPoints: spellingTrend,
                                        title: "Spelling Trend",
                                        lineColor: .green
                                    )
                                    .padding(.horizontal)
                                }
                                if !handwritingTrend.isEmpty {
                                    AestheticLineChartView(
                                        dataPoints: handwritingTrend,
                                        title: "Handwriting Trend",
                                        lineColor: .blue
                                    )
                                    .padding(.horizontal)
                                }
                            }
                            .transition(.slide)
                        } else {
                            Text("No records found for this user/class.")
                                .foregroundColor(.gray)
                                .padding(.horizontal)
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        // Use an empty string for the title and hide the back button
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(false) // You can set true if you want to hide entire nav bar
        .onAppear {
            fetchData()
        }
    }
    
    
    // MARK: - Data Fetch
    private func fetchData() {
        isLoading = true
        errorMessage = nil

        let baseURL = "http://192.168.1.213:8443/get_user_class_data"
        guard let encodedUsername = globalUsername.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedClassName = globalClassName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)?username=\(encodedUsername)&class_name=\(encodedClassName)") else {
            self.errorMessage = "Invalid URL"
            self.isLoading = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No data returned"
                    return
                }
                // For debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON: \(jsonString)")
                }
                do {
                    let decoder = JSONDecoder()
                    self.testRecords = try decoder.decode([TestRecord].self, from: data)
                    print("Decoded TestRecords:")
                    self.testRecords.forEach { print($0) }
                } catch {
                    self.errorMessage = error.localizedDescription
                    print("Decoding error: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(username: "SampleUser", className: "SampleClass")
    }
}


