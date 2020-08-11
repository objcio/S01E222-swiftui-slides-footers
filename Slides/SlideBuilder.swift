//
//  SlideBuilder.swift
//  Slides
//
//  Created by Chris Eidhof on 18.08.20.
//  Copyright © 2020 Chris Eidhof. All rights reserved.
//

import SwiftUI

protocol SlideList {
    associatedtype V: View
    func slide(at index: Int) -> V
    var count: Int { get }
}

struct Single<Content: View>: SlideList {
    let view: Content
    let count = 1
    
    func slide(at index: Int) -> some View {
        view
    }
}

struct Pair<First: View, Second: SlideList>: SlideList {
    let first: First
    let remainder: Second
    var count: Int {
        remainder.count +  1
    }
    
    func slide(at index: Int) -> some View {
        Group {
            if index == 0 {
                first
            } else {
                remainder.slide(at: index-1)
            }
        }
    }
}

@_functionBuilder enum SlideBuilder {
    public static func buildBlock<Content>(_ content: Content) -> some SlideList where Content : View {
        Single(view: content)
    }
    
    public static func buildBlock<C0, C1>(_ c0: C0, _ c1: C1) -> some SlideList where C0 : View, C1 : View {
        Pair(first: c0, remainder: Single(view: c1))
    }
    
    public static func buildBlock<C0, C1, C2>(_ c0: C0, _ c1: C1, _ c2: C2) -> some SlideList where C0 : View, C1 : View, C2: View {
        Pair(first: c0, remainder: Pair(first: c1, remainder: Single(view: c2)))
    }
}
