//
//  FileSpllitHelper.swift
//  SwiftFileSplitter
//
//  Created by Alexandr Sivash on 16.07.2024.
//

import Foundation

class FileSplitHelper {
    
    func indexFileChunks(fileString: String, completion: @escaping ([Range<String.Index>]) -> Void) {
        
        //1) split string into 10000 chars chunks
        
        let chunksCount = Int(ceil(Double(fileString.count) / 1000.0))
        var cursor = fileString.startIndex
        
        let desiredDistance = 50000
        var ranges: [Range<String.Index>] = (0..<chunksCount).compactMap { _ in
            
            lazy var availableDistance = fileString.distance(from: cursor, to: fileString.endIndex)
            let newEndIndex = fileString.index(cursor, offsetBy: desiredDistance, limitedBy: fileString.endIndex) ??
                fileString.index(cursor, offsetBy: availableDistance)
            
            let rawRange = Range<String.Index>(uncheckedBounds: (
                lower: cursor,
                upper: newEndIndex
            ))
            
            let linedRange = fileString.lineRange(for: rawRange)
            guard !linedRange.isEmpty else {
                return nil
            }
            
            cursor = linedRange.upperBound
            return linedRange
        }
        
        //2) Find DW_TAG_compile_unit's in there. Multithread. Ensure result thread-safe
        //2.1) Check indexes uniqueness
        var lineRanges: Set<Range<String.Index>> = [] //this set ensures unique-ness
        let sync = DispatchGroup()
        DispatchQueue.concurrentPerform(iterations: ranges.count, register: sync) { index in
            let regex: any RegexComponent = /public (?:struct|enum)/
            findOccunencesOf(signature: regex, in: fileString, range: ranges[index]) { newRanges in
                DispatchQueue.main.async { //this ensures thread-safe. Main is not concurrent
                    lineRanges.formUnion(newRanges)
                    sync.leave()
                }
            }
        }
        
        sync.notify(queue: .main) {
            
            ranges = lineRanges.sorted(by: {
                $0.lowerBound < $1.lowerBound
            })
            
            //3) Convert indexes of DW_TAG_compile_unit to compile unit pages
            let lastRangeIndex = max(0, ranges.count - 1)
            let interRanges = ranges.lazy.enumerated().map {
                if $0.offset == lastRangeIndex {
                    return Range<String.Index>(uncheckedBounds: (
                        lower: $0.element.lowerBound,
                        upper: fileString.endIndex
                    ))
                    
                } else {
                    let nextRange = ranges[$0.offset + 1]
                    return Range<String.Index>(uncheckedBounds: (
                        lower: $0.element.lowerBound,
                        upper: nextRange.lowerBound
                    ))
                }
            }
            
            completion(interRanges)
        }
        
        //return fileString.ranges(of: try! Regex(#"^0x[abcdef0-9]{8}: DW_TAG_compile_unit\n"#).anchorsMatchLineEndings())
    }
    
    func findOccunencesOf(signature: String, in string: String, range: Range<String.Index>, completion: (_ lineRanges: [Range<String.Index>]) -> Void) {
        let ranges = string.lazy[range]
            .ranges(of: signature)
            .map(string.lineRange(for:))
        
        completion(ranges)
    }
    
    func findOccunencesOf(signature: any RegexComponent, in string: String, range: Range<String.Index>, completion: (_ lineRanges: [Range<String.Index>]) -> Void) {
        let ranges = string[range]
            .ranges(of: signature)
            .map(string.lineRange(for:))
        
        let strings = ranges.map {
            String(string[$0])
        }
        
        //lost PaymentStatusType
        if strings.contains(where: { $0.contains("Payment") }) {
            print("hello")
        }
        
        completion(ranges)
    }
}
