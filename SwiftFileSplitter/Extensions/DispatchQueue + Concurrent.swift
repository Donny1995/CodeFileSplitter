//
//  DispatchQueue + Concurrent.swift
//  SwiftFileSplitter
//
//  Created by Alexandr Sivash on 16.07.2024.
//

import Foundation

extension DispatchQueue {
    static func concurrentPerform(iterations: Int, register in: DispatchGroup, execute work: (Int) -> Void) {
        for _ in 0..<iterations{
            `in`.enter()
        }
        
        DispatchQueue.concurrentPerform(
            iterations: iterations,
            execute: work
        )
    }
    
    static func concurrentPerformM2(iterations: Int, exitQueue: DispatchQueue = .main, execute work: (_ iteration: Int, _ resolve: @escaping () -> Void) -> Void, completion: @escaping () -> Void) {
        let sync = DispatchGroup()
        for _ in 0..<iterations{
            sync.enter()
        }
        
        DispatchQueue.concurrentPerform(iterations: iterations) { iteration in
            work(iteration, sync.leave)
        }
        
        sync.notify(queue: exitQueue, execute: completion)
    }
}
