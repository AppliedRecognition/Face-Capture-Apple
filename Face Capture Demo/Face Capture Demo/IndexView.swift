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
                ModalView(navigationPath: self.$navigationPath, title: demo.title, description: demo.description)
            case .embedded:
                EmbeddedView(navigationPath: self.$navigationPath, title: demo.title, description: demo.description)
            case .navigationStack:
                NavStackView(navigationPath: self.$navigationPath, title: demo.title, description: demo.description)
            }
        }
    }
}

fileprivate struct _IndexView: View {
    
    let onNavigate: (Demo) -> Void
    
    var body: some View {
        List {
            DemoSection(demo: .modal(title: "Modal", description: "This example shows how to configure and run face capture presented in a modal sheet."), onNavigate: self.onNavigate)
            DemoSection(demo: .embedded(title: "Embedded", description: "This example shows how to embed a face capture session view in your layout.") , onNavigate: self.onNavigate)
            DemoSection(demo: .navigationStack(title: "Navigation", description: "This example shows how to run a face capture session in a view pushed to a navigation stack. The session will start as soon as the view is pushed on to the stack. Once the session finishes the view is popped off the stack."), onNavigate: self.onNavigate)
        }
        .listStyle(.insetGrouped)
        .listRowInsets(.none)
        .navigationTitle("Face capture")
        .toolbar {
            ToolbarItem {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
    }
}

fileprivate enum Demo: Hashable {
    case modal(title: String, description: String)
    case embedded(title: String, description: String)
    case navigationStack(title: String, description: String)
    
    var title: String {
        switch self {
        case .modal(title: let title, description: _):
            return title
        case .embedded(title: let title, description: _):
            return title
        case .navigationStack(title: let title, description: _):
            return title
        }
    }
    
    var description: String {
        switch self {
        case .modal(title: _, description: let description):
            return description
        case .embedded(title: _, description: let description):
            return description
        case .navigationStack(title: _, description: let description):
            return description
        }
    }
}

fileprivate struct DemoSection: View {
    
    let demo: Demo
    let onNavigate: (Demo) -> Void
    
    var body: some View {
        Section {
            HStack {
                Text(self.demo.title).font(.title2).foregroundStyle(Color.accentColor)
                Spacer()
                Image(systemName: "play.circle.fill").imageScale(.large).foregroundStyle(Color.accentColor)
            }
            HStack {
                Text(self.demo.description)
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
