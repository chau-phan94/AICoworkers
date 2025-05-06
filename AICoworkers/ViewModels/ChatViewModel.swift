import Foundation

final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [Message] = []
    @Published var inputText = ""
    @Published var isLoading = false
    
    private let openAIService: OpenAIServiceProtocol
    
    init(openAIService: OpenAIServiceProtocol = OpenAIService(apiKey: "YOUR_API_KEY")) {
        self.openAIService = openAIService
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let userMessage = Message(content: inputText, type: .user)
        messages.append(userMessage)
        inputText = ""
        
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                let response = try await openAIService.sendMessage(userMessage.content)
                let aiMessage = Message(content: response, type: .ai)
                await MainActor.run {
                    messages.append(aiMessage)
                }
            } catch {
                print("Error: \(error)")
                await MainActor.run {
                    messages.append(Message(content: "Failed to get response", type: .ai))
                }
            }
        }
    }
    
    func clearChat() {
        messages.removeAll()
    }
}
