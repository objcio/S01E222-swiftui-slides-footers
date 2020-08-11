//
//  ContentView.swift
//  Slides
//
//  Created by Chris Eidhof on 11.08.20.
//  Copyright © 2020 Chris Eidhof. All rights reserved.
//

import SwiftUI

struct Context {
    var currentStep: Int = 0
    var currentSlide: Int = 0
    var slideCount: Int = 0
    var namespace: Namespace.ID!
}

struct Presentation<S: SlideList, Theme: ViewModifier>: View {
    var slides: S
    var theme: Theme
    @State var currentSlide = 0
    @State var steps: [Animation] = []
    @State var currentStep = 0
    
    var numberOfSteps: Int { steps.count + 1 }
    
    init(@SlideBuilder slides: () -> S, theme: Theme) {
        self.slides = slides()
        self.theme = theme
    }
    
    init(slides: S, theme: Theme) {
        self.slides = slides
        self.theme = theme
    }
    
    func previous() {
        if currentSlide > 0  {
            currentSlide -= 1
            currentStep = 0
        }
    }
    
    func next() {
        if currentStep + 1 < numberOfSteps {
            withAnimation(steps[currentStep]) {
                currentStep += 1
            }
        } else if currentSlide + 1 < slides.count {
            withAnimation(.default) {
                currentSlide += 1
            }
            currentStep = 0
        }
    }
    
    @Namespace var namespace
    var context: Context {
        Context(currentStep: currentStep, currentSlide: currentSlide, slideCount: slides.count, namespace: namespace)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            HStack {
                Button("Previous") { self.previous() }
                Text("Slide \(currentSlide + 1) of \(slides.count) — Step \(currentStep + 1) of \(numberOfSteps)")
                Button("Next") { self.next() }
            }
            SlideContainer(content: slides.slide(at: currentSlide), theme: theme)
                .onPreferenceChange(StepsKey.self, perform: {
                    self.steps = $0
                })
                .environment(\.context, context)
                .aspectRatio(CGSize(width: 16, height: 9), contentMode: .fit)
                .border(Color.black)
        }
    }
}

extension Presentation where Theme == EmptyModifier {
    init(@SlideBuilder slides: () -> S) {
        self.init(slides: slides, theme: .identity)
    }
}

struct SlideContainer<Content: View, Theme: ViewModifier>: View {
    let size = CGSize(width: 1920, height: 1080)
    let content: Content
    let theme: Theme
    
    var body: some View {
        GeometryReader { proxy in
            VStack {
                self.content
            }
                .frame(width: self.size.width, height: self.size.height)
                .modifier(self.theme)
                .scaleEffect(min(proxy.size.width/self.size.width, proxy.size.height/self.size.height))
                .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}

struct Progress: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress  }
        set { progress = newValue }
    }
    func path(in rect: CGRect) -> Path {
        Path {
            $0.addRect(rect.divided(atDistance: rect.size.width * progress, from: .minXEdge).slice)
        }
    }
}

struct MyTheme: ViewModifier {
    @Environment(\.context) var context
    
    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    Text("Slide \(context.currentSlide + 1)/\(context.slideCount)")
                    Progress(progress: CGFloat(context.currentSlide + 1) / CGFloat(context.slideCount))
                        .fill(Color.white)
                        .frame(height: 10)
                },
                alignment: .bottom
            )
            .foregroundColor(.white)
            .background(Color.blue)
            .font(.custom("Avenir", size: 48))
            .headerStyle({
                $0.padding(50).border(Color.white, width: 5)
            })
    }
}

struct StepsKey: PreferenceKey {
    static let defaultValue: [Animation] = []
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value = nextValue()
    }
}

struct ContextKey: EnvironmentKey {
    static let defaultValue = Context()
}

extension EnvironmentValues {
    var context: Context {
        get { self[ContextKey.self] }
        set { self[ContextKey.self] = newValue }
    }
}

struct Slide<Content: View>: View {
    var steps: [Animation] = []
    let content: (Int) -> Content
    @Environment(\.context.currentStep) var step: Int
    
    var body: some View {
        content(step)
            .preference(key: StepsKey.self, value: steps)
    }
}

extension Slide {
    init(numberOfSteps: Int, content: @escaping (Int) -> Content) {
        self.init(steps: Array(repeating: .default, count: numberOfSteps-1), content: content)
    }
}

struct ImageSlide: View {
    var body: some View {
        Slide(steps: [Animation.easeInOut(duration: 5)]) { step in
            Image(systemName: "tortoise")
                .frame(maxWidth: .infinity, alignment: step > 0 ? .trailing :  .leading)
                .padding(50)
        }
            
    }
}

struct HeaderStyleKey: EnvironmentKey {
    static let defaultValue = AnyViewModifier { $0 }
}

extension EnvironmentValues {
    var headerStyle: AnyViewModifier {
        get { self[HeaderStyleKey.self] }
        set { self[HeaderStyleKey.self] = newValue }
    }
}

extension View {
    func headerStyle<V: View>(_ transform: @escaping (AnyViewModifier.Content) -> V) -> some View {
        self.environment(\.headerStyle, AnyViewModifier(transform: transform))
    }
}

struct AnyViewModifier: ViewModifier {
    let apply: (Content) -> AnyView
    init<V: View>(transform: @escaping (Content) -> V) {
        self.apply = { AnyView(transform($0)) }
    }
    func body(content: Content) -> AnyView {
        apply(content)
    }
}

struct Header<Content: View>: View {
    @Environment(\.headerStyle) var headerStyle: AnyViewModifier
    var content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        content.modifier(headerStyle)
    }
}

struct PresentationGeometryEffect<ID: Hashable>: ViewModifier {
    @Environment(\.context.namespace) var namespace
    let id: ID
    func body(content: Content) -> some View {
        content.matchedGeometryEffect(id: id, in: namespace!)
    }
}

extension View {
    func matchedGeometryEffect<ID: Hashable>(id: ID) -> some View {
        modifier(PresentationGeometryEffect(id: id))
    }
}

@SlideBuilder var slides: some SlideList {
    Header {
        Text("Hello, World!")
    }
    .matchedGeometryEffect(id: "title")
    VStack(spacing: 100) {
        Header {
            Text("Hello, World!")
        }
        .matchedGeometryEffect(id: "title")
        Text("Some more body text")
    }
    Slide(numberOfSteps: 2) { step in
        HStack {
            Text("Hello")
            if step > 0 {
                Text("World")
            }
        }
    }
}


struct ContentView: View {
    @Namespace var ns
    

    var body: some View {
        Presentation(slides: slides, theme: MyTheme())
    }
}

struct PreviewModifier: ViewModifier {
    @Namespace var ns
    
    func body(content: Content) -> some View {
        content.environment(\.context, Context(currentStep: 0, currentSlide: 0, slideCount: 0, namespace: ns))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(0..<slides.count) { ix in
            SlideContainer(content: AnyView(slides.slide(at: ix)), theme: MyTheme())
                .modifier(PreviewModifier())
                .previewLayout(.fixed(width: 320, height: 180))
            .previewDisplayName("Slide \(ix+1)")
        }
    }
}
