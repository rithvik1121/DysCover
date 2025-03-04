import SwiftUI


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

// MARK: - ContentView
struct ContentView: View {
    @State private var showUserEntry = false
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#FFF9C4"), Color(hex: "#FFD54F")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    Image("koala_logo_v1")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 170, height: 170)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 10)
                        .padding(.top, 80)
                    
                    Text("DysCover")
                        .font(.system(size: 52, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 3, x: 0, y: 3)
                    
                    Text("Make learning fun!")
                        .foregroundColor(Color.gray.opacity(0.95))
                        .font(.system(size: 22))
                    
                    Spacer()
                    
                    Button(action: {
                        // Show the user entry flow
                        showUserEntry = true
                    }) {
                        Text("Get Started")
                            .font(.system(size: 24, weight: .heavy))
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .foregroundColor(Color(hex: "#FFB74D"))
                            .cornerRadius(25)
                            .shadow(radius: 5)
                            .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                }
                .padding()
                
                // Hidden NavigationLink to go to EnterUsernameView
                NavigationLink(destination: EnterUsernameView(),
                               isActive: $showUserEntry) {
                    EmptyView()
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}


// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
