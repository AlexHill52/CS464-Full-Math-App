import SwiftUI
struct MathProblemsView: View {
    var participantId: String
    var onComplete: (Int, Int) -> Void
    
    @State private var currentProblem = 0
    @State private var answer: String = ""
    @State private var problems: [(String, Int)] = []
    @State private var correctAnswers = 0
    @State private var startTime = Date()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            if currentProblem < 3 {
                // Problem solving view
                VStack(spacing: 20) {
                    Text("Problem \(currentProblem + 1) of 3")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(problems.isEmpty ? "" : problems[currentProblem].0)
                        .font(.system(size: 48, weight: .bold))
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(15)
                    
                    TextField("Your answer", text: $answer)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .onSubmit(submitAnswer)
                    
                    Button(action: submitAnswer) {
                        Text("Submit Answer")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(answer.isEmpty ? Color.gray : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(answer.isEmpty)
                }
                .padding()
            } else {
                // Completion screen with thank you and exit options
                VStack(spacing: 30) {
                    Spacer()
                    
                    VStack(spacing: 25) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.green)
                        
                        Text("Thank You!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 10) {
                            Text("You completed today's problems")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("\(correctAnswers) out of 3 correct")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                        }
                        
                        Text("Your participation is valuable to our research!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 15) {
                        Button(action: {
                            onComplete(3, correctAnswers)
                        }) {
                            HStack {
                                Image(systemName: "arrow.uturn.left")
                                Text("Back to Dashboard")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        
                        Button(action: {
                            onComplete(3, correctAnswers)
                            exitApp()
                        }) {
                            HStack {
                                Image(systemName: "power")
                                Text("Exit App")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
        }
        .onAppear {
            generateProblems()
            startTime = Date()
        }
    }
    
    func generateProblems() {
        problems = (0..<3).map { _ in
            let num1 = Int.random(in: 1...20)
            let num2 = Int.random(in: 1...20)
            let ops = ["+", "-", "*"]
            let op = ops.randomElement()!
            
            let result: Int
            switch op {
            case "+": result = num1 + num2
            case "-": result = num1 - num2
            case "*": result = num1 * num2
            default: result = 0
            }
            
            return ("\(num1) \(op) \(num2)", result)
        }
    }
    
    func submitAnswer() {
        guard let userAnswer = Int(answer) else { return }
        
        if userAnswer == problems[currentProblem].1 {
            correctAnswers += 1
        }
        
        answer = ""
        currentProblem += 1
    }
    
    func exitApp() {
        // Graceful app exit
        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            exit(0)
        }
    }
}
