import SwiftUI


// A reusable donut chart view for percentage metrics.
struct DonutChartView: View {
    var progress: CGFloat  // Expected range: 0 to 1.
    var title: String
    var gradientColors: [Color]
    
    var body: some View {
        VStack {
            ZStack {
                // Background circle.
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 20)
                // Foreground progress circle.
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: gradientColors),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 20, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                // Display progress as a percentage.
                Text("\(Int(progress * 100))%")
                    .font(.headline)
                    .foregroundColor(.black)
            }
            .frame(width: 150, height: 150)
            
            // Metric title.
            Text(title)
                .font(.subheadline)
                .padding(.top, 8)
        }
    }
}

// A view for displaying numeric metrics with a progress bar.
struct ProgressMetricView: View {
    var progress: CGFloat // Expected range: 0 to 1.
    var title: String
    var valueText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(valueText)
                .font(.subheadline)
                .foregroundColor(.gray)
            GeometryReader { geometry in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: geometry.size.width * progress, height: 8)
                    .animation(.easeInOut, value: progress)
            }
            .frame(height: 8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(4)
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(10)
    }
}

struct DashboardView: View {
    // Define a grid layout with two columns.
    let gridColumns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Warm, inviting yellow gradient background.
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#FFF9C4"), Color(hex: "#FFD54F")]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                        // Progress metric cards.
                        VStack(spacing: 20) {
                            ProgressMetricView(
                                progress: 0.4,  // Example: 120 sec out of 300 sec.
                                title: "Avg Time to Complete Test",
                                valueText: "2:00 min"
                            )
                            
                            ProgressMetricView(
                                progress: 0.5,  // Example: 250 ms out of 500 ms.
                                title: "Visual Processing Speed",
                                valueText: "250 ms"
                            )
                        }
                        .padding(.horizontal)
                        
                        // "Take Test" Button.
                        NavigationLink(destination: TestView()) {
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
                    VStack(alignment: .leading, spacing: 30) {
                        // Greeting.
                        Text("Hello, Alex")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top)
                            .padding(.horizontal)
                        
                        // Grid of donut charts for percentage-based metrics.
                        LazyVGrid(columns: gridColumns, spacing: 20) {
                            DonutChartView(
                                progress: 0.78,  // 78/100 Total Score.
                                title: "Total Score",
                                gradientColors: [Color.pink, Color.red]
                            )
                            DonutChartView(
                                progress: 0.65,  // 65% Comprehension.
                                title: "Comprehension",
                                gradientColors: [Color.green, Color.blue]
                            )
                            DonutChartView(
                                progress: 0.85,  // 85% Word Decoding.
                                title: "Word Decoding",
                                gradientColors: [Color.orange, Color.yellow]
                            )
                            DonutChartView(
                                progress: 0.75,  // 75% Phonemic Awareness.
                                title: "Phonemic Awareness",
                                gradientColors: [Color.purple, Color.blue]
                            )
                            DonutChartView(
                                progress: 0.15,  // 15% Confusion Frequency.
                                title: "Confusion",
                                gradientColors: [Color.gray, Color.black]
                            )
                        }
                        .padding(.horizontal)
                        
                        
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Dashboard")
        }
    }
}



struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
