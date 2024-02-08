//
//  IndexView.swift
//  Face Capture Demo
//
//  Created by Jakub Dolejs on 06/02/2024.
//

import SwiftUI

struct IndexView: View {
    
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        _IndexView() { demo in
            self.navigationPath.append(demo)
        }
        .navigationDestination(for: Demo.self) { demo in
            switch demo {
            case .modal:
                ModalView(navigationPath: self.$navigationPath)
            case .embedded:
                EmbeddedView(navigationPath: self.$navigationPath)
            case .navigationStack:
                NavStackView(navigationPath: self.$navigationPath)
            }
        }
    }
}

fileprivate struct _IndexView: View {
    
    let onNavigate: (Demo) -> Void
    
    var body: some View {
//        VStack {
//            HStack {
//                Text("This app shows how to configure and run and embed face capture sessions into SwiftUI views")
//                Spacer()
//            }
            List {
                DemoSection(title: "Modal", description: "Shows how to configure and run face capture by presenting a modal sheet.", demo: .modal, onNavigate: self.onNavigate)
                DemoSection(title: "Embedded", description: "Shows how to embed a face capture session view in your layout.", demo: .embedded , onNavigate: self.onNavigate)
                DemoSection(title: "Navigation", description: "Shows how to launch a face capture session in a view pushed to the navigation stack.", demo: .navigationStack, onNavigate: self.onNavigate)
            }
            .listStyle(.insetGrouped)
            .listRowInsets(.none)
//            Spacer()
//        }
//        .padding()
        .navigationTitle("Face capture demos")
    }
}

fileprivate enum Demo: Int, Hashable {
    case modal, embedded, navigationStack
}

fileprivate struct DemoSection: View {
    
    let title: String
    let description: String
    let demo: Demo
    let onNavigate: (Demo) -> Void
    
    var body: some View {
        Section {
            HStack {
                Text(self.title).font(.title2).foregroundStyle(Color.accentColor)
                Spacer()
                Image(systemName: "play.circle.fill").imageScale(.large).foregroundStyle(Color.accentColor)
            }
            HStack {
                Text(self.description)
                Spacer()
            }
        }
        .onTapGesture {
            self.onNavigate(self.demo)
        }
    }
}

struct IndexView_Previews: PreviewProvider {
    
    static var previews: some View {
        NavigationStack {
            _IndexView(onNavigate: { _ in })
        }
    }
}

//#Preview {
//    @State var path = NavigationPath()
//    NavigationStack(path: $path) {
//        IndexView(navigationPath: $path)
//    }
//}
