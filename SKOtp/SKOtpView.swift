//
//  SKOtpView.swift
//  SKOtp
//
//  Created by Shadab khan on 21/05/25.
//

import SwiftUI

public struct SKOtpView: View {
    @Binding var otp: String
    @FocusState private var isFocused: Bool
    @State private var showCursor: Bool = true
    
    private let maxLength: Int
    private let isAlphanumeric: Bool
    private let onSubmit: () -> Void
    
    public init(otp: Binding<String>, maxLength: Int = 6, isAlphanumeric: Bool = false, onSubmit: @escaping () -> Void) {
        self._otp = otp
        self.maxLength = maxLength
        self.isAlphanumeric = isAlphanumeric
        self.onSubmit = onSubmit
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            Text("Enter \(maxLength)-digit \(isAlphanumeric ? "Alphanumeric" : "Numeric") OTP")
                .font(.headline)
            
            // Hidden TextField for capturing input
            TextField("", text: Binding(
                get: { otp },
                set: { newValue in
                    let filtered = newValue.uppercased().filter {
                        isAlphanumeric ? $0.isLetter || $0.isNumber : $0.isNumber
                    }
                    if filtered.count <= maxLength {
                        otp = filtered
                    }
                }
            ))
            .keyboardType(isAlphanumeric ? .asciiCapable : .numberPad)
            .textInputAutocapitalization(.characters)
            .disableAutocorrection(true)
            .focused($isFocused)
            .textContentType(.oneTimeCode)
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .onChange(of: otp) { newValue in
                if newValue.count == maxLength {
                    isFocused = false
                }
            }
            // Add Done button toolbar only if keyboard is numeric
            .toolbar {
                if !isAlphanumeric {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Done") {
                            isFocused = false
                        }
                    }
                }
            }
            
            // OTP Boxes
            HStack(spacing: 8) {
                ForEach(0..<maxLength, id: \.self) { index in
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                (index == otp.count && isFocused) ||
                                (otp.count == maxLength && index == maxLength - 1 && isFocused)
                                ? Color.blue : Color.gray,
                                lineWidth: 1
                            )
                            .frame(width: 40, height: 50)
                        
                        Text(character(at: index))
                            .font(.title2)
                            .foregroundColor(.primary)
                        
                        if index == otp.count && otp.count < maxLength && isFocused {
                            Rectangle()
                                .fill(Color.primary)
                                .frame(width: 2, height: 30)
                                .opacity(showCursor ? 1 : 0)
                                .animation(.easeInOut(duration: 0.5), value: showCursor)
                        }
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }
            
            Button(action: {
                onSubmit()
            }) {
                Text("Submit OTP")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isOtpValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(!isOtpValid)
        }
        .padding()
        .onAppear {
            isFocused = true
            startCursorBlink()
        }
    }
    
    private var isOtpValid: Bool {
        otp.count == maxLength &&
        otp.range(of: isAlphanumeric ? "^[A-Za-z0-9]{\(maxLength)}$" : "^[0-9]{\(maxLength)}$", options: .regularExpression) != nil
    }
    
    private func character(at index: Int) -> String {
        if index < otp.count {
            let charIndex = otp.index(otp.startIndex, offsetBy: index)
            return String(otp[charIndex])
        }
        return ""
    }
    
    private func startCursorBlink() {
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            showCursor.toggle()
        }
    }
}
