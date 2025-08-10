import SwiftUI

struct CreditsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button(action: {
                            dismiss()
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.trailing, 8)
                        .zIndex(1000)
                    }
                    .padding(.bottom, geometry.size.height * 0.05)
                    
                    Spacer()
                    
                    VStack(spacing: geometry.size.height * 0.08) {
                        Text("YANG")
                            .font(Font.custom("PressStart2P-Regular", size: 28))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.16), radius: 20, x: 0, y: 0)
                        
                        VStack(spacing: geometry.size.height * 0.015) {
                            Text("Credits")
                                .font(Font.custom("ShareTechMono-Regular", size: 28))
                                .foregroundColor(.white)
                                .opacity(0.60)
                            Text("@twidy")
                                .font(Font.custom("ShareTechMono-Regular", size: 14))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: geometry.size.height * 0.015) {
                            Text("Legal")
                                .font(Font.custom("ShareTechMono-Regular", size: 28))
                                .foregroundColor(.white)
                                .opacity(0.60)
                            Text("Privacy Policy")
                                .font(Font.custom("ShareTechMono-Regular", size: 14))
                                .foregroundColor(.white)
                            Text("Terms of Service")
                                .font(Font.custom("ShareTechMono-Regular", size: 14))
                                .foregroundColor(.white)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .ignoresSafeArea(.all)
    }
}

struct CreditsView_Previews: PreviewProvider {
    static var previews: some View {
        CreditsView()
    }
}
