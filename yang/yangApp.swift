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
    @Published var showContents = false
}

@main
struct yangApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var pushManager = PushManager.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(pushManager)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var pushManager: PushManager
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if appState.isLaunching {
                LaunchScreenView()
                    .onAppear {
                        checkTodayVideos()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 4.42) {
                            appState.showContents = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                            appState.isLaunching = false
                        }
                    }
            } else if appState.isCheckingPhotos {
                LoadingView()
            }



            if appState.showContents {
                ContentView()
                .opacity(appState.showContents && appState.hasTodayVideo ? 1 : 0)
                .animation(.easeInOut(duration: 1.5), value: appState.showContents && appState.hasTodayVideo)
                
                VideoRecordingView(pushManager: pushManager, onVideoSaved: {
                    appState.hasTodayVideo = true
                })
                .opacity(appState.showContents && appState.hasTodayVideo ? 0 : 1)
                .animation(.easeInOut(duration: 0.5), value: appState.showContents && !appState.hasTodayVideo)
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
    private let riveModel = RiveViewModel(fileName: "launch_animation", animationName: "Timeline 1")
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
        .onAppear {
            print("LoadingView appeared")
        }
        .onDisappear {
            print("LoadingView disappeared")
        }
    }
}
