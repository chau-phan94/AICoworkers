import Foundation

protocol OpenAIServiceProtocol {
    func sendMessage(_ message: String) async throws -> String
}
