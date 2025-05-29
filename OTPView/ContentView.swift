//
//  ContentView.swift
//  OTPView
//
//  Created by IE Mac 05 on 21/05/25.
//

import SwiftUI
import SKOtp

struct ContentView: View {
    @State private var otp: String = ""
    
    var body: some View {
        SKOtpView(
            otp: $otp,
            maxLength: 6,
            isAlphanumeric: true,
            boxStyle: .circle,
            imageName: "lock.shield",
            titleText: "Enter OTP",
            subtitleText: "Please enter the 6-digit code sent to you",
            onSubmit: {
                print("OTP Submitted: \(otp)")
            }
        )
        .preferredColorScheme(.light)
    }
}

#Preview {
    ContentView()
}
