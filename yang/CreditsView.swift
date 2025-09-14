import SwiftUI

struct CreditsView: View {
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 그라데이션 배경
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 73/255, green: 43/255, blue: 0/255, opacity: 0.8)
                    ]),
                    center: UnitPoint(x: 0.5, y: 0.47),
                    startRadius: geometry.size.width * 0.3,
                    endRadius: geometry.size.width * 1.2
                )
                .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button(action: {
                            onDismiss?()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.40))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.30), lineWidth: 0.25)
                                    )
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 20)
                        .zIndex(1000)
                    }
                    .padding(.top, geometry.safeAreaInsets.top + 60)
                    
                    Spacer()
                    
                    VStack(spacing: geometry.size.height * 0.08) {
                        Text("YANG")
                            .font(Font.custom("PressStart2P-Regular", size: 12))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.16), radius: 20, x: 0, y: 0)
                        
                        VStack(spacing: geometry.size.height * 0.015) {
                            Text("Credits")
                                .font(Font.custom("ShareTechMono-Regular", size: 12))
                                .foregroundColor(.white)
                                .opacity(0.60)
                            Link("@twidy", destination: URL(string: "https://x.com/Teammaeum0228")!)
                                .font(Font.custom("ShareTechMono-Regular", size: 14))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: geometry.size.height * 0.015) {
                            Text("Legal")
                                .font(Font.custom("ShareTechMono-Regular", size: 11))
                                .foregroundColor(.white)
                                .opacity(0.60)
                            Link("Privacy Policy", destination: URL(string: "https://sungjungjo.notion.site/privacy-policy-2311208e804580a9a698d51a1c7d9ccc")!)
                                .font(Font.custom("ShareTechMono-Regular", size: 12))
                                .foregroundColor(.white)
                            Link("Terms of Service", destination: URL(string: "https://sungjungjo.notion.site/terms-of-Service-2311208e80458075b6fdc9704db28886")!)
                                .font(Font.custom("ShareTechMono-Regular", size: 12))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .background(.black)
        .ignoresSafeArea(.all)
    }
}

struct CreditsView_Previews: PreviewProvider {
    static var previews: some View {
        CreditsView()
    }
}
