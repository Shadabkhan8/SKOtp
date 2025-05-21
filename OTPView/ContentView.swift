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
        SKOtpView(otp: $otp, onSubmit: {
            print("OTP: \(otp)")
        })
    }
}

#Preview {
    ContentView()
}
