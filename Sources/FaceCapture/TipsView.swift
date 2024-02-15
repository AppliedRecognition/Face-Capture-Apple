//
//  TipsView.swift
//
//
//  Created by Jakub Dolejs on 14/02/2024.
//

import SwiftUI

public struct TipsView: View {
    
    public init() {
        UIPageControl.appearance().currentPageIndicatorTintColor = .label
        UIPageControl.appearance().pageIndicatorTintColor = .gray
    }
    
    let tips: [TipContent] = [
        TipContent(imageName: "tip_sharp_shadows", text: "Avoid standing in a light that throws sharp shadows like in sharp sunlight or directly under a lamp."),
        TipContent(imageName: "head_with_glasses", text: "If you can, take off your glasses."),
        TipContent(imageName: "busy_background", text: "Avoid standing in front of busy backgrounds.")
    ]
    
    public var body: some View {
        if #available(iOS 14, *) {
            TabView {
                ForEach(self.tips) { tip in
                    TipView(imageName: tip.imageName, text: tip.text)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
        } else {
            LegacyTipsView(tips: self.tips)
        }
    }
}

public struct TipView: View {
    
    public let imageName: String
    public let text: LocalizedStringKey
    
    public var body: some View {
        GeometryReader { geometryReader in
            VStack {
                ZStack(alignment: .center) {
                    Rectangle().fill(.gray)
                    SwiftUI.Image(self.imageName, bundle: Bundle.module).frame(width: geometryReader.size.width, height: geometryReader.size.height * 0.4).clipped()
                }
                    .frame(height: geometryReader.size.height * 0.4)
                    .clipped()
                HStack {
                    Text(self.text, bundle: .module)
                    Spacer()
                }
                .padding()
                Spacer()
            }
        }
    }
}

struct TipContent: Identifiable {
    var id: String {
        self.imageName
    }
    let imageName: String
    let text: LocalizedStringKey
}

struct LegacyTipsView: View {
    
    @State var selection: Int = 0
    @State var offset: CGFloat = 0
    
    let tips: [TipContent]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TipView(imageName: self.tips[self.selection].imageName, text: self.tips[self.selection].text)
                .gesture(DragGesture(minimumDistance: 3.0, coordinateSpace: .local)
                    .onChanged { value in
                        self.offset = value.translation.width
                    }
                    .onEnded { value in
                        self.offset = 0
                        switch value.translation.width {
                        case ...0:
                            if self.selection < self.tips.count - 1 {
                                self.selection += 1
                            }
                        case 0...:
                            if selection > 0 {
                                self.selection -= 1
                            }
                        default:
                            print("no swipe")
                        }
                    })
                .offset(x: self.offset)
            HStack {
                Button {
                    self.selection = 0
                } label: {
                    DotView(selected: self.selection == 0)
                }
                Button {
                    self.selection = 1
                } label: {
                    DotView(selected: self.selection == 1)
                }.padding(.horizontal, 4)
                Button {
                    self.selection = 2
                } label: {
                    DotView(selected: self.selection == 2)
                }
            }
            .padding(.bottom, 32)
        }
    }
}

struct DotView: View {
    
    let selected: Bool
    
    var body: some View {
        Circle().fill(self.selected ? Color(.label) : Color.gray).frame(width: 10, height: 10)
    }
}

struct TipsView_Previews: PreviewProvider {
    
    static var previews: some View {
        ForEach(["fr","en","es"], id: \.self) { lang in
            TipsView().environment(\.locale, .init(identifier: lang))
        }
        
    }
}
