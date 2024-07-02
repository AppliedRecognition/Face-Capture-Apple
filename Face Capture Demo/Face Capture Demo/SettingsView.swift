//
//  SettingsView.swift
//  Face Capture Demo
//
//  Created by Jakub Dolejs on 09/02/2024.
//

import SwiftUI

struct SettingsView: View {
    
    @ObservedObject var settings: Settings = Settings()
    
    var body: some View {
        List {
            Section {
                Toggle("Use back camera", isOn: self.$settings.useBackCamera)
                Toggle("Enable active liveness", isOn: self.$settings.enableActiveLiveness)
                NavigationLink {
                    FaceOvalSizeView(settings: self.settings)
                        .navigationTitle("Face oval")
                } label: {
                    Text("Face oval size")
                }
                Picker("Face detection", selection: self.$settings.faceDetection) {
                    ForEach(FaceDetectionImplementation.allCases, id: \.self.rawValue) { opt in
                        Text(opt.rawValue).tag(opt)
                    }
                }
                .pickerStyle(.menu)
            } header: {
                Text("Session settings")
            }
        }
        .navigationTitle("Settings")
    }
}

struct FaceOvalSizeView: View {
    
    @ObservedObject var settings: Settings
    @State var isEditingHeight: Bool = false
    @State var isEditingWidth: Bool = false
    
    var body: some View {
        VStack {
            ZStack {
                FaceOvalShape(settings: self.settings)
                Text(String(format: "%.0f%%", self.settings.faceOvalWidth)).foregroundStyle(.background)
            }
            .aspectRatio(9/16, contentMode: .fit)
            .background {
                RoundedRectangle(cornerRadius: 16).fill(self.isEditingWidth ? Color.accentColor : .secondary)
            }
            Text("Face width (in portrait orientation)")
            Slider(value: self.$settings.faceOvalWidth, in: 20...90, step: 5) {
                Text("Face width")
            } minimumValueLabel: {
                Text("20%")
            } maximumValueLabel: {
                Text("90%")
            } onEditingChanged: { editing in
                self.isEditingWidth = editing
            }.padding(.bottom, 32)
            ZStack {
                FaceOvalShape(settings: self.settings)
                Text(String(format: "%.0f%%", self.settings.faceOvalHeight)).foregroundStyle(.background)
            }
            .aspectRatio(16/9, contentMode: .fit)
            .background {
                RoundedRectangle(cornerRadius: 16).fill(self.isEditingHeight ? Color.accentColor : .secondary)
            }
            Text("Face height (in landscape orientation)")
            Slider(value: self.$settings.faceOvalHeight, in: 20...90, step: 5) {
                Text("Face height")
            } minimumValueLabel: {
                Text("20%")
            } maximumValueLabel: {
                Text("90%")
            } onEditingChanged: { editing in
                self.isEditingHeight = editing
            }
        }.padding()
    }
}

struct FaceOvalShape: Shape {
    
    @ObservedObject var settings: Settings
    
    let faceAspectRatio: CGFloat = 4/5
    
    func ellipseRectInSize(_ size: CGSize) -> CGRect {
        let width: CGFloat
        let height: CGFloat
        if size.width / size.height > self.faceAspectRatio {
            height = size.height * self.settings.faceOvalHeight * 0.01
            width = height * self.faceAspectRatio
        } else {
            width = (size.width * self.settings.faceOvalWidth) * 0.01
            height = (width / self.faceAspectRatio)
        }
        return CGRect(x: size.width / 2 - width / 2, y: size.height / 2 - height / 2, width: width, height: height)
    }
    
    func path(in rect: CGRect) -> Path {
        Path(ellipseIn: self.ellipseRectInSize(rect.size))
    }
}

struct Settings_Previews: PreviewProvider {
    
    static var previews: some View {
        SettingsView()
        FaceOvalSizeView(settings: Settings())
    }
}
