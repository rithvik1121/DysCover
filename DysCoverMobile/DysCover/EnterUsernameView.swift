import SwiftUI

struct EnterUsernameView: View {
    @State private var localUsername: String = ""
    @State private var localClassName: String = ""
    @State private var navigateToDashboardView: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient with soft colors
                LinearGradient(
                    gradient: Gradient(colors: [Color(hex: "#FFF9C4"), Color(hex: "#FFD54F")]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    // Koala Logo at the top
                    Image("koala_logo_v1") // Replace with your asset name
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 10)
                    
                    Text("Welcome to DysCover")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "#F57F17"))
                        .multilineTextAlignment(.center)
                    
                    // Input Fields
                    VStack(spacing: 20) {
                        TextField("Enter your username", text: $localUsername)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                        
                        TextField("Enter your class name", text: $localClassName)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding(.horizontal, 40)
                    
                    // Continue Button
                    Button(action: {
                        if !localUsername.isEmpty && !localClassName.isEmpty {
                            globalUsername = localUsername
                            globalClassName = localClassName
                            navigateToDashboardView = true
                        }
                    }) {
                        Text("Continue")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(hex: "#FBC02D"))
                            .cornerRadius(12)
                            .shadow(color: .gray.opacity(0.4), radius: 4, x: 0, y: 4)
                    }
                    .padding(.horizontal, 40)
                    
                    Spacer()
                }
            }
            .navigationDestination(isPresented: $navigateToDashboardView) {
                DashboardView(username: globalUsername, className: globalClassName)
            }
            .navigationBarHidden(true)
        }
    }
}

struct EnterUsernameView_Previews: PreviewProvider {
    static var previews: some View {
        EnterUsernameView()
    }
}
