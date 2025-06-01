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
    @State private var hasTodayVideo = false
    @State private var isCheckingPhotos = true
    
    var body: some Scene {
        WindowGroup {
            if isLaunching {
                LaunchScreenView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                isLaunching = false
                                checkTodayVideos()
                            }
                        }
                    }
            } else if isCheckingPhotos {
                LoadingView()
            } else {
                if hasTodayVideo {
                    ContentView()
                } else {
                    VideoRecordingView(onVideoSaved: {
                        self.hasTodayVideo = true
                    })
                }
            }
        }
    }
    
    private func checkTodayVideos() {
        PhotoLibraryChecker.checkForTodayVideosInYangFolder { hasVideos in
            DispatchQueue.main.async {
                self.hasTodayVideo = hasVideos
                self.isCheckingPhotos = false
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

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black
            VStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .ignoresSafeArea()
    }
}
