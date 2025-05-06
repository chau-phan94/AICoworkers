import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    ScrollViewReader { proxy in
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.messages) { message in
                                MessageBubble(message: message)
                            }
                        }
                        .onChange(of: viewModel.messages) { _ in
                            withAnimation {
                                proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Next Suggestion Button
                if viewModel.isLoading == false && !viewModel.inputText.isEmpty == false {
                    Button(action: {
                        viewModel.requestNextSuggestion()
                    }) {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Next Suggestion / Discuss More")
                        }
                        .padding(8)
                        .foregroundColor(.white)
                        .background(Color.orange)
                        .cornerRadius(10)
                    }
                    .padding(.bottom, 4)
                }

                InputBarView(text: $viewModel.inputText, sendAction: viewModel.sendMessage)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            .navigationTitle("AI Chat")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.clearChat) {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.type == .user {
                Spacer()
                Text(message.content)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            } else if message.type == .aiSuggestion {
                // AI Socratic suggestions: special style
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                VStack(alignment: .leading) {
                    Text("AI Suggestion")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding()
                .background(Color.yellow.opacity(0.18))
                .cornerRadius(12)
                Spacer()
            } else {
                Text(message.content)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                Spacer()
            }
        }
        .padding(.horizontal)
    }
}

struct InputBarView: View {
    @Binding var text: String
    var sendAction: (() -> Void)
    
    var body: some View {
        HStack {
            TextField("Type a message...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button(action: {
                guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                sendAction()
                text = ""
            }) {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.blue)
            }
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}

struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
    }
}
