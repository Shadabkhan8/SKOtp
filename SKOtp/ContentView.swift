//
//  ContentView.swift
//  SKOtp
//
//  Created by Shadab khan on 13/05/25.
//

import SwiftUI

struct ContentView: View {
    @State private var otp: String = ""
    
    var body: some View {
        SKOtpView(otp: $otp, maxLength: 8, isAlphanumeric: true) {
            print("Entered OTP: \(otp)")
        }
    }
}
