// Test evidence only: capture only the explicitly supplied Godot process window.
import Foundation
import CoreGraphics
let args = CommandLine.arguments
if args.count != 3 { exit(2) }
let pid = Int(args[1])!
let list = CGWindowListCopyWindowInfo(.optionAll, kCGNullWindowID) as? [[String: Any]] ?? []
let owned = list.filter { ($0[kCGWindowOwnerPID as String] as? Int) == pid }
let candidates = owned.filter {
    let bounds = $0[kCGWindowBounds as String] as? [String: Any] ?? [:]
    let width = bounds["Width"] as? Double ?? 0
    let height = bounds["Height"] as? Double ?? 1
    return width / max(1,height) > 1.6 && width / max(1,height) < 1.9 && width >= 300 && height >= 180 &&
    ($0[kCGWindowOwnerPID as String] as? Int) == pid &&
    ($0[kCGWindowLayer as String] as? Int) == 0 &&
    (($0[kCGWindowBounds as String] as? [String: Any])?["Width"] as? Double ?? 0) >= 320
}
guard let window = candidates.first, let number = window[kCGWindowNumber as String] as? Int else {
    for item in owned { print("Owned Godot window bounds \(item[kCGWindowBounds as String] ?? [:]), layer \(item[kCGWindowLayer as String] ?? -1)") }
    exit(3)
}
print("Godot capture window \(number), bounds \(window[kCGWindowBounds as String] ?? [:])")
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
task.arguments = ["-x", "-o", "-l", String(number), args[2]]
try task.run()
task.waitUntilExit()
exit(task.terminationStatus)
