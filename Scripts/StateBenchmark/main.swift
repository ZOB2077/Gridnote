import Foundation

let state = AppState()
let iterations = 10_000
let start = CFAbsoluteTimeGetCurrent()
for _ in 0..<iterations { state.toggleWorkspace() }
let average = (CFAbsoluteTimeGetCurrent() - start) / Double(iterations)
print("workspace_state_toggle_seconds=\(String(format: "%.8f", average))")
