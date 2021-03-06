//
//  SwiftModule.swift
//  langserver-swift
//
//  Created by Ryan Lovelett on 12/18/16.
//
//

import Argo
import enum Build.TargetDescription
import Curry
import Foundation
import class PackageModel.ResolvedTarget
import Runes

private extension TargetDescription {

    /// The compiler arguments that will be sent to SourceKit.
    ///
    /// In the future, this may or may not be added to `libSwiftPM`.
    var arguments: [String] {
        switch self {
        case .clang(let c):
            return c.basicArguments()
        case .swift(let s):
            return s.compileArguments()
        }
    }

}

/// A module, typically defined and managed by [SwiftPM](), that manages the sources and the compiler arguments
/// that should be sent to SourceKit.
struct SwiftModule {

    /// The name of the Swift module.
    let name: String

    /// A mapping of the raw text of a source to it's location on the file system.
    var sources: [URL : TextDocument]

    /// The raw arguments provided by SwiftPM.
    let otherArguments: [String]

    /// Arguments to be sent to SourceKit.
    var arguments: [String] {
        return sources.keys.map({ $0.path }) + otherArguments
    }

    /// Create a false module that is just a collection of source files in a directory. Ideally
    /// this should not be used since SwiftPM defined modules are preferred.
    ///
    /// - Parameter directory: A directory containing a collection of Swift source files.
    init(_ directory: URL) {
        name = directory.lastPathComponent
        let s = WorkspaceSequence(root: directory).lazy
            .filter({ $0.isFileURL && $0.isFile })
            .filter({ $0.pathExtension.lowercased() == "swift" }) // Check if file is a Swift source file (e.g., has `.swift` extension)
            .flatMap(TextDocument.init)
            .map({ (key: $0.uri, value: $0) })
        sources = Dictionary(s)
        otherArguments = []
    }

    /// Create a module from the definition provided by SwiftPM.
    ///
    /// - Parameters:
    ///   - target: A fully resolved target. All the dependencies for the target are resolved.
    ///   - description: The description of either a Swift or Clang target.
    init(target: ResolvedTarget, description: TargetDescription) {
        name = target.name
        let dict = target.sources.paths.lazy
            .map { URL(fileURLWithPath: $0.asString) }
            .flatMap(TextDocument.init)
            .map { (key: $0.uri, value: $0) }
        sources = Dictionary(dict)
        otherArguments = description.arguments
    }

    var root: URL {
        return commonRoot(sources.keys)
    }

}

extension SwiftModule : Hashable {

    var hashValue: Int {
        return name.hashValue
    }

}

extension SwiftModule : Equatable {

    /// Returns a Boolean value indicating whether two values are equal.
    ///
    /// Equality is the inverse of inequality. For any values `a` and `b`,
    /// `a == b` implies that `a != b` is `false`.
    ///
    /// - Parameters:
    ///   - lhs: A value to compare.
    ///   - rhs: Another value to compare.
    static func ==(lhs: SwiftModule, rhs: SwiftModule) -> Bool {
        return lhs.name == rhs.name
    }

}
