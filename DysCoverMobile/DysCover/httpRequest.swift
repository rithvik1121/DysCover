import SwiftUI

struct Post: Codable, Identifiable {
    let id: Int
    let title: String
    let body: String
}

struct httpRequest: View {
    @State private var posts: [Post] = []

    var body: some View {
        VStack {
            Button("Fetch Posts") {
                fetchPosts()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

            Button("Send Data") {
                sendData()
            }
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)

            List(posts) { post in
                VStack(alignment: .leading) {
                    Text(post.title)
                        .font(.headline)
                    Text(post.body)
                        .font(.subheadline)
                }
            }
        }
    }

    func fetchPosts() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else { return }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let decodedPosts = try JSONDecoder().decode([Post].self, from: data)
                    DispatchQueue.main.async {
                        self.posts = decodedPosts
                    }
                } catch {
                    print("Error decoding: \(error)")
                }
            }
        }.resume()
    }

    func sendData() {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else { return }

        let postData = ["title": "Hello SwiftUI", "body": "This is a test", "userId": 1] as [String: Any]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: postData) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
        }.resume()
    }
}


struct httpRequest_Previews: PreviewProvider {
    static var previews: some View {
        httpRequest()
    }
}
