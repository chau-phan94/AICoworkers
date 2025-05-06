import Foundation

final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [Message] = []
    @Published var inputText = ""
    @Published var isLoading = false
    
    private let openAIService: OpenAIServiceProtocol
    private var lastTopic: String? = nil
    
    init(openAIService: OpenAIServiceProtocol = OpenAIService(apiKey: "YOUR_API_KEY")) {
        self.openAIService = openAIService
    }
    
    @MainActor
    func updateLoading(isLoading: Bool) {
        self.isLoading = isLoading
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let userMessage = Message(content: inputText, type: .user)
        messages.append(userMessage)
        let topic = inputText // Save the topic for Socratic exploration
        lastTopic = topic
        inputText = ""

        Task {
            await updateLoading(isLoading: true)
            do {
                // 1. AI generates clarifying questions about the topic
                let clarifyingPrompt = "Given the topic: \(topic), generate 3 clarifying or exploratory questions that would help someone understand or make a decision about this topic. Format as a numbered list."
                let questionsString = try await openAIService.sendMessage(clarifyingPrompt)
                await MainActor.run {
                    messages.append(Message(content: "AI suggests these questions to explore the topic:\n" + questionsString, type: .aiSuggestion))
                }

                // 2. Extract questions from the AI's response (simple split on newlines/numbers)
                let questions = questionsString
                    .split(separator: "\n")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty && ($0.first?.isNumber ?? false) }
                    .map { line -> String in
                        // Remove leading number and dot
                        if let dotIndex = line.firstIndex(of: ".") {
                            return String(line[line.index(after: dotIndex)...]).trimmingCharacters(in: .whitespaces)
                        }
                        return line
                    }

                // 3. For each question, get an answer from the AI
                for question in questions {
                    let answer = try await openAIService.sendMessage(question)
                    await MainActor.run {
                        messages.append(Message(content: "Q: \(question)\nA: \(answer)", type: .ai))
                    }
                }

                // 4. Suggest further questions or a summary
                let followupPrompt = "Given the topic: \(topic), and the above Q&A, suggest 2 more follow-up questions or provide a summary to help the user make a final decision or grasp the overall knowledge."
                let followup = try await openAIService.sendMessage(followupPrompt)
                await MainActor.run {
                    messages.append(Message(content: "AI follow-up: \n" + followup, type: .aiSuggestion))
                    updateLoading(isLoading: false)
                }
            } catch {
                print("Error: \(error)")
                await MainActor.run {
                    messages.append(Message(content: "Failed to get response", type: .ai))
                    updateLoading(isLoading: false)
                }
            }
        }
    }
    
    func clearChat() {
        messages.removeAll()
        lastTopic = nil
    }

    // Request the next suggestion or deeper discussion
    func requestNextSuggestion() {
        guard let topic = lastTopic else { return }
        Task {
            await updateLoading(isLoading: true)
            do {
                // Construct context from previous Q&A (last 10 messages)
                let recentQnA = messages.suffix(10).map { m in
                    "[\(m.type.rawValue.capitalized)] \(m.content)"
                }.joined(separator: "\n")
                let prompt = "Given the topic: \(topic), and the following chat history, suggest 2 more follow-up questions, discuss further, or generate a more detailed document to help the user.\n\nChat History:\n\(recentQnA)"
                let suggestion = try await openAIService.sendMessage(prompt)
                await MainActor.run {
                    messages.append(Message(content: suggestion, type: .aiSuggestion))
                    updateLoading(isLoading: false)
                }
            } catch {
                print("Error: \(error)")
                await MainActor.run {
                    messages.append(Message(content: "Failed to get further suggestions", type: .ai))
                    updateLoading(isLoading: false)
                }
            }
        }
    }
}

