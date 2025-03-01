import SwiftUI

// Helper extension to use hex strings for colors.
extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let red = Double((rgb >> 16) & 0xFF) / 255.0
        let green = Double((rgb >> 8) & 0xFF) / 255.0
        let blue = Double(rgb & 0xFF) / 255.0
        
        self.init(red: red, green: green, blue: blue)
    }
}

struct ContentView: View {
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "#8E2DE2"), Color(hex: "#4A00E0")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Header Image in a circular frame.
                Image("zebra")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 140)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 4))
                    .shadow(radius: 10)
                    .padding(.top, 80)
                
                // Title
                Text("DysCover")
                    .font(.system(size: 48, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 3)
                
                // Subtitle
                Text("By Ishan, Rithvik, and Justin")
                    .font(.headline)
                    .foregroundColor(Color.white.opacity(0.85))
                
                Spacer()
                
                // "Get Started" Button
                Button(action: {
                    goTest()
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .foregroundColor(Color(hex: "#4A00E0"))
                        .cornerRadius(25)
                        .shadow(radius: 5)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

func goTest() {
    if let window = UIApplication.shared.windows.first {
        window.rootViewController = UIHostingController(rootView: httpRequest())
        window.makeKeyAndVisible()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
