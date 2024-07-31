//
//  main.swift
//  SwiftFileSplitter
//
//  Created by Alexandr Sivash on 16.07.2024.
//

import Foundation

guard CommandLine.arguments.count >= 3 else {
    print("Error! First argument must be a file to split")
    exit(13)
}

let filePath: String = CommandLine.arguments[1]
let exportDir: String = CommandLine.arguments[2]
var optionalFilePrefix: String?
if let optionalFilePrefixFilePath: String = CommandLine.arguments.safeGet(index: 3) {
    optionalFilePrefix = try? String.init(contentsOf: URL(filePath: optionalFilePrefixFilePath))
}

guard FileManager.default.fileExists(atPath: filePath) else {
    print("Error! Path leads to nothing")
    exit(13)
}

let string: String

do {
    string = try String(contentsOfFile: filePath)
    
} catch let err {
    print("Error! Path leads to nothing")
    exit(13)
}

var isDirectory: ObjCBool = false
guard FileManager.default.fileExists(atPath: exportDir, isDirectory: &isDirectory), isDirectory.boolValue == true else {
    print("Error! Export dir not found")
    exit(13)
}

FileSplitHelper().indexFileChunks(fileString: string) { chunkRanges in
    print("Indexing finished: \(chunkRanges.count) ranges found")
    
    var aggregatedRanges: [Range<String.Index>] = []
    
    var currentChunkSize: Int = 0
    var currentRange: Range<String.Index> = (string.startIndex..<string.endIndex)
        
    let rangesCount: Int = chunkRanges.count
    for (index, chunkRange) in chunkRanges.enumerated() {
        if index == 0 {
            currentRange = .init(uncheckedBounds: (lower: chunkRange.lowerBound, upper: chunkRange.lowerBound))
        } else {
            currentRange = .init(uncheckedBounds: (lower: currentRange.lowerBound, upper: chunkRange.upperBound))
        }
        
        currentChunkSize += string.distance(from: chunkRange.lowerBound, to: chunkRange.upperBound)
        
        if currentChunkSize >= 40000 || index == max(0, rangesCount - 1) {
            aggregatedRanges.append(currentRange)
            currentRange = (currentRange.upperBound..<string.endIndex)
            currentChunkSize = 0
        }
    }
    
    let fileURL = URL(filePath: filePath)
    let fileName = fileURL.lastPathComponent.dropLast(fileURL.pathExtension.count + 1)
    
    for (index, range) in aggregatedRanges.enumerated() {
        
        var filePath = exportDir
        if filePath.last != "/" {
            filePath.append("/")
        }
        filePath += fileName
        filePath += ".part\(index)"
        filePath += "." + fileURL.pathExtension
        
        var thing = String(string.lazy[range])
        if let optionalFilePrefix {
            thing = optionalFilePrefix + "\n" + thing
        }
        
        if FileManager.default.fileExists(atPath: filePath) {
            try? thing.data(using: .utf8)?.write(to: URL(filePath: filePath))
        } else {
            FileManager.default.createFile(atPath: filePath, contents: thing.data(using: .utf8))
        }
    }
    
    exit(0)
}

RunLoop.main.run()
