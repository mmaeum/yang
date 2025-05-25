//
//  yangApp.swift
//  yang
//
//  Created by 박수진 on 5/18/25.
//

import SwiftUI

@main
struct yangApp: App {
    @State private var isLaunching = true
    
    var body: some Scene {
        WindowGroup {
            if isLaunching {
                LaunchScreenView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                isLaunching = false
                            }
                        }
                    }
            } else {
                CameraView()
            }
        }
    }
}

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color.black 
            Image("LaunchImage")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
        }
        .ignoresSafeArea()
    }
}
