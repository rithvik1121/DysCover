import SwiftUI

struct EnterUsernameView: View {
    @State private var localUsername: String = ""
    @State private var localClassName: String = ""
    @State private var navigateToDashboardView: Bool = false

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
                    Text("Welcome to DysCover")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#F57F17"))
                        .multilineTextAlignment(.center)
                        .padding(.top, 40)

                    // Username Field
                    TextField("Enter your username", text: $localUsername)
                        .padding()
                        .background(Color(hex: "#FFFDE7").opacity(0.8))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    // Class Name Field
                    TextField("Enter your class name", text: $localClassName)
                        .padding()
                        .background(Color(hex: "#FFFDE7").opacity(0.8))
                        .cornerRadius(8)
                        .padding(.horizontal)

                    Button("Continue") {
                        // Only proceed if both fields are non-empty
                        if !localUsername.isEmpty && !localClassName.isEmpty {
                            globalUsername = localUsername
                            globalClassName = localClassName
                            navigateToDashboardView = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "#FBC02D"))
                    .padding(.bottom, 20)

                    // NavigationLink to TestView
                    NavigationLink(destination: DashboardView(username: globalUsername, className: globalClassName), isActive: $navigateToDashboardView) {
                        EmptyView()
                    }
                }
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


