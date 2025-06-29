//
//  yangApp.swift
//  yang
//
//  Created by 박수진 on 5/18/25.
//

import SwiftUI
import AVKit
import RiveRuntime

class AppState: ObservableObject {
    @Published var isLaunching = true
    @Published var hasTodayVideo = false
    @Published var isCheckingPhotos = true
}

@main
struct yangApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        if appState.isLaunching {
            LaunchScreenView()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation {
                            appState.isLaunching = false
                            checkTodayVideos()
                        }
                    }
                }
        } else if appState.isCheckingPhotos {
            LoadingView()
        } else {
            if appState.hasTodayVideo {
                ContentView()
            } else {
                VideoRecordingView(onVideoSaved: {
                    appState.hasTodayVideo = true
                })
            }
        }
    }
    
    private func checkTodayVideos() {
        PhotoLibraryChecker.checkForTodayVideosInYangFolder { hasVideos in
            print("checkTodayVideos completion: hasVideos=\(hasVideos)")
            DispatchQueue.main.async {
                print("set hasTodayVideo, isCheckingPhotos = false")
                appState.hasTodayVideo = hasVideos
                appState.isCheckingPhotos = false
            }
        }
    }
}

struct LaunchScreenView: View {
    private let riveModel = RiveViewModel(fileName: "launch_animation")
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            riveModel.view()
                .frame(width: 300, height: 300)
        }
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
