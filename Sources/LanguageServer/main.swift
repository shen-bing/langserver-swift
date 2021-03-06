import BaseProtocol
import Dispatch
import Foundation
import LanguageServerProtocol

private let header: [String : String] = [
    "Content-Type": "application/vscode-jsonrpc; charset=utf8"
]

let main = OperationQueue.main
let stdin = FileHandle.standardInput
var requests = RequestBuffer()
stdin.waitForDataInBackgroundAndNotify()

// When new data is available
var dataAvailable : NSObjectProtocol!
dataAvailable = NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: stdin, queue: main) { (notification) -> Void in
    let buffer = stdin.availableData

    guard !buffer.isEmpty else {
        return stdin.waitForDataInBackgroundAndNotify()
    }

    requests.append(buffer)

    for requestBuffer in requests {
        do {
            let request = try Request(requestBuffer)
            let response = handle(request)
            /// If the request id is null then it is a notification and not a request
            switch request {
            case .request(_, _, _):
                let toSend = response.data(header)
                FileHandle.standardOutput.write(toSend)
            default: ()
            }
        } catch let error as PredefinedError {
            fatalError(error.description)
        } catch {
            fatalError("TODO: Better error handeling. \(error)")
        }
    }

    return stdin.waitForDataInBackgroundAndNotify()
}

// Launch the task
RunLoop.main.run()
//while RunLoop.main.run(mode: .defaultRunLoopMode, before: .distantFuture) {}
