import SwiftUI


// MARK: - Data Model

struct TestRecord: Identifiable, Codable {
    let test_id: Int
    let username: String
    let className: String  // Swift property for JSON "class"
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
        case className = "class"  // Maps JSON "class" to Swift property className
        case question1, question2, question3, question4, question5
        case spelling_accuracy, stutter_metric, speaking_accuracy, handwriting_metric, total_score
    }
}

// MARK: - VerticalBarView
/// A vertical bar showing a percentage metric with label and numeric value.
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
/// A line chart with gradient fill under the line, plus data point circles.
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
                    // The fill area under the line
                    if dataPoints.count > 1 {
                        createClosedPath(in: geo)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [lineColor.opacity(0.3), .clear]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    
                    // The stroked line
                    createLinePath(in: geo)
                        .stroke(lineColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    
                    // Data point circles
                    if dataPoints.count > 1 {
                        ForEach(dataPoints.indices, id: \.self) { index in
                            let (x, y) = pointPosition(in: geo, index: index)
                            Circle()
                                .fill(lineColor)
                                .frame(width: 8, height: 8)
                                .position(x: x, y: y)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(6)
                .shadow(radius: 2)
            }
            .frame(height: 250) // bigger chart
        }
        .padding(8)
    }
    
    /// Creates a path for just the line (without closing).
    private func createLinePath(in geo: GeometryProxy) -> Path {
        var path = Path()
        guard dataPoints.count > 1 else { return path }
        
        let width = geo.size.width
        let height = geo.size.height
        let (minVal, maxVal) = minMax()
        let range = maxVal - minVal == 0 ? 1 : (maxVal - minVal)
        let step = width / CGFloat(dataPoints.count - 1)
        
        for (index, value) in dataPoints.enumerated() {
            let x = CGFloat(index) * step
            let y = height - ((CGFloat(value - minVal) / range) * height)
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }
    
    /// Creates a closed path for filling under the line.
    private func createClosedPath(in geo: GeometryProxy) -> Path {
        var path = createLinePath(in: geo)
        // Close the shape by drawing down to the bottom edge, then back to start.
        path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
        path.addLine(to: CGPoint(x: 0, y: geo.size.height))
        path.closeSubpath()
        return path
    }
    
    /// Helper to get min/max of dataPoints
    private func minMax() -> (Double, Double) {
        let minVal = dataPoints.min() ?? 0
        let maxVal = dataPoints.max() ?? 1
        return (minVal, maxVal)
    }
    
    /// Returns the (x, y) coordinate of a data point circle.
    private func pointPosition(in geo: GeometryProxy, index: Int) -> (CGFloat, CGFloat) {
        let width = geo.size.width
        let height = geo.size.height
        let (minVal, maxVal) = minMax()
        let range = maxVal - minVal == 0 ? 1 : (maxVal - minVal)
        let step = width / CGFloat(dataPoints.count - 1)
        
        let value = dataPoints[index]
        let x = CGFloat(index) * step
        let y = height - ((CGFloat(value - minVal) / range) * height)
        return (x, y)
    }
}

// MARK: - DashboardView

struct DashboardView: View {
    let username: String
    let className: String
    
    @State private var testRecords: [TestRecord] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    
    // Average calculations
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
        NavigationView {
            ZStack {
                // Warm gradient background
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#FFF9C4"), Color(hex: "#FFD54F")]),
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
                        VStack(alignment: .leading, spacing: 24) {
                            // Greeting
                            Text("Hello, \(username)")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .padding(.top)
                                .padding(.horizontal)
                            
                            Text("Class: \(className)")
                                .font(.title2)
                                .padding(.horizontal)
                            
                            // 4 vertical bars
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
                                        .padding(.horizontal)
                                    
                                    // Larger, more aesthetic line charts
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
                            } else {
                                Text("No records found for this user/class.")
                                    .foregroundColor(.gray)
                                    .padding(.horizontal)
                            }
                            
                            // "Take Test" Button
                            Button(action: {
                                // Implement test-taking logic
                            }) {
                                Text("Take Test")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            
                            Spacer()
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Dashboard")
            .onAppear {
                fetchData()
            }
        }
    }
    
    // MARK: - Data Fetch
    private func fetchData() {
        isLoading = true
        errorMessage = nil
        
        let baseURL = "http://192.168.1.213:8443/get_user_class_data"
        guard let encodedUsername = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedClassName = className.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
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
                // Print raw JSON for debugging
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
        DashboardView(username: globalUsername, className: globalClassName)
    }
}
