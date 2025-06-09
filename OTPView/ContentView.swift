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
            maxLength: 8,
            isAlphanumeric: true,
            boxStyle: .underline,
            imageName: "lock.shield",
            titleText: "Enter OTP",
            subtitleText: "Please enter the 6-digit code sent to you",
            autoSubmitOnFullEntry: false,
//            expiresIn: 30,
            onExpire: {
                print("OTP expired")
            },
            onResend: {
                print("Resend")
            },
            onSubmit: {
                print("OTP Submitted: \(otp)")
            }
        )
    }
}

#Preview {
    ContentView()
}
