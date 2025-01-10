//
//  TipsView.swift
//
//
//  Created by Jakub Dolejs on 14/02/2024.
//

import SwiftUI

public struct TipsView: View {
    
    @State private var currentPage = 0
    
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
            PageView(views: self.tips.map({ TipView(imageName: $0.imageName, text: $0.text) }), currentPage: $currentPage)
                .navigationTitle(String.localizedStringWithFormat(NSLocalizedString("tip_x_of_y", bundle: .module, comment: ""), self.currentPage + 1, self.tips.count))
        } else {
            PageView(views: self.tips.map({ TipView(imageName: $0.imageName, text: $0.text) }), currentPage: $currentPage)
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
    let id = UUID()
    let imageName: String
    let text: LocalizedStringKey
}

struct TipsView_Previews: PreviewProvider {
    
    static var previews: some View {
        ForEach(["fr","en","es"], id: \.self) { lang in
            TipsView().environment(\.locale, .init(identifier: lang))
        }
        
    }
}
