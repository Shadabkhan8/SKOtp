//
//  SKOtpView.swift
//  SKOtp
//
//  Created by Shadab khan on 21/05/25.
//

import SwiftUI
import UIKit

public struct SKOtpView: View {
    @Binding var otp: String
    @FocusState private var isFocused: Bool
    @State private var showCursor: Bool = true
    
    @State private var timeRemaining: Int = 60
    @State private var shakeOffset: CGFloat = 0
    @State private var shake = false
    @State private var showError = false
    
    // Alert popup state
    @State private var showingValidAlert = false
    
    private let maxLength: Int
    private let isAlphanumeric: Bool
    private let boxStyle: BoxStyle
    private let focusedColor: Color
    private let unfocusedColor: Color
    private let filledColor: Color
    private let cursorColor: Color
    private let textColor: Color
    private let buttonColor: Color
    private let imageName: String?
    private let titleText: String?
    private let subtitleText: String?
    private let onSubmit: () -> Void
    
    private let localOtp = "12345678"
    
    public init(
        otp: Binding<String>,
        maxLength: Int = 6,
        isAlphanumeric: Bool = false,
        boxStyle: BoxStyle = .filled,
        focusedColor: Color = .blue,
        unfocusedColor: Color = Color.gray.opacity(0.4),
        filledColor: Color = Color.blue.opacity(0.15),
        cursorColor: Color = .blue,
        textColor: Color = .primary,
        buttonColor: Color = .blue,
        imageName: String? = nil,
        titleText: String? = nil,
        subtitleText: String? = nil,
        onSubmit: @escaping () -> Void = {}
    ) {
        self._otp = otp
        self.maxLength = maxLength
        self.isAlphanumeric = isAlphanumeric
        self.boxStyle = boxStyle
        self.focusedColor = focusedColor
        self.unfocusedColor = unfocusedColor
        self.filledColor = filledColor
        self.cursorColor = cursorColor
        self.textColor = textColor
        self.buttonColor = buttonColor
        self.imageName = imageName
        self.titleText = titleText
        self.subtitleText = subtitleText
        self.onSubmit = onSubmit
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            
            if let imageName = imageName {
                Image(systemName: imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(focusedColor)
            }
            
            if let titleText = titleText {
                Text(titleText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
            }
            
            if let subtitleText = subtitleText {
                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
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
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                
                if newValue.count == maxLength {
                    isFocused = false
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isFocused = false
                    }
                }
            }
            
            GeometryReader { geometry in
                let spacing: CGFloat = 12
                let totalSpacing = CGFloat(maxLength - 1) * spacing
                let boxWidth = (geometry.size.width - totalSpacing) / CGFloat(maxLength)
                
                HStack(spacing: spacing) {
                    ForEach(0..<maxLength, id: \.self) { index in
                        let isCurrentFocused = (index == otp.count && isFocused)
                        let isLastFocused = (otp.count == maxLength && index == maxLength - 1 && isFocused)
                        let focused = isCurrentFocused || isLastFocused
                        let filled = index < otp.count
                        
                        ZStack {
                            boxView(isFocused: focused, isFilled: filled)
                                .frame(width: boxWidth, height: 60)
                                .scaleEffect(focused ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: focused)
                            
                            Text(character(at: index))
                                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                                .foregroundColor(textColor)
                                .accessibilityLabel("Digit \(index + 1): \(character(at: index).isEmpty ? "Empty" : character(at: index))")
                            
                            if index == otp.count && otp.count < maxLength && isFocused {
                                Rectangle()
                                    .fill(cursorColor)
                                    .frame(width: 2, height: 32)
                                    .opacity(showCursor ? 1 : 0)
                                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: showCursor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                }
                .frame(maxWidth: .infinity)
                .offset(x: shakeOffset)
            }
            .frame(height: 80)
            .contentShape(Rectangle())
            .onTapGesture {
                isFocused = true
            }
            
            if timeRemaining > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundColor(.white)
                    Text("Expires in \(timeRemaining)s")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple]),
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )
                .clipShape(Capsule())
                .shadow(radius: 4)
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut, value: timeRemaining)
            }  else {
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                    Text("OTP expired")
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red)
                .clipShape(Capsule())
                .shadow(radius: 4)
                .transition(.opacity.combined(with: .scale))
                .animation(.easeInOut, value: timeRemaining)
            }
            
            Button(action: {
                validateOtpAndSubmit()
            }) {
                Text("Submit OTP")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isOtpValid ? buttonColor : Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(color: isOtpValid ? buttonColor.opacity(0.6) : Color.clear, radius: 10, x: 0, y: 4)
                    .animation(.easeInOut, value: isOtpValid)
            }
            .disabled(!isOtpValid)
        }
        .padding()
        .onAppear {

            if let clipboard = UIPasteboard.general.string {
                let filtered = clipboard.uppercased().filter {
                    isAlphanumeric ? $0.isLetter || $0.isNumber : $0.isNumber
                }
                if filtered.count == maxLength {
                    otp = filtered
                }
            }
            
            isFocused = true
            startCursorBlink()
            startTimer()
        }

        .alert("Valid OTP", isPresented: $showingValidAlert) {
            Button("OK") {}
        }
    }
    
    private var isOtpValid: Bool {
        otp.count == maxLength &&
        otp.range(of: isAlphanumeric ? "^[A-Za-z0-9]{\(maxLength)}$" : "^[0-9]{\(maxLength)}$", options: .regularExpression) != nil
    }
    
    private func character(at index: Int) -> String {
        guard index < otp.count else { return "" }
        let charIndex = otp.index(otp.startIndex, offsetBy: index)
        return String(otp[charIndex])
    }
    
    private func startCursorBlink() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeInOut(duration: 0.6)) {
                showCursor.toggle()
            }
            startCursorBlink()
        }
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
            }
        }
    }
    
    private func triggerShake() {
        
        withAnimation(.default) {
            shakeOffset = 10
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.default) {
                shakeOffset = -10
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.default) {
                shakeOffset = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showError = false
            }
        }
    }
    
    private func validateOtpAndSubmit() {
        if otp == localOtp {
            showingValidAlert = true
            resetTimer()
            onSubmit()
        } else {
            showError = true
            triggerShake()
        }
    }
    
    private func resetTimer() {
        timeRemaining = 60
        startTimer()
    }
    
    @ViewBuilder
    private func boxView(isFocused: Bool, isFilled: Bool) -> some View {
        let errorColor = Color.red
        
        switch boxStyle {
        case .bordered:
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(showError ? errorColor : (isFocused ? focusedColor : unfocusedColor), lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(showError ? errorColor.opacity(0.3) : (isFilled ? filledColor : Color.clear))
                )
                .animation(.easeInOut, value: isFocused)
            
        case .underline:
            VStack {
                Spacer()
                Rectangle()
                    .fill(showError ? errorColor : (isFocused ? focusedColor : unfocusedColor))
                    .frame(height: 3)
                    .animation(.easeInOut, value: isFocused)
            }
            
        case .roundedBorder:
            RoundedRectangle(cornerRadius: 12)
                .stroke(showError ? errorColor : (isFocused ? focusedColor : unfocusedColor), lineWidth: 3)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(showError ? errorColor.opacity(0.3) : (isFilled ? filledColor : Color.clear))
                )
                .animation(.easeInOut, value: isFocused)
            
        case .filled:
            RoundedRectangle(cornerRadius: 8)
                .fill(showError ? errorColor.opacity(0.3) : (isFocused ? focusedColor.opacity(0.15) : filledColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(showError ? errorColor : (isFocused ? focusedColor : unfocusedColor.opacity(0.5)), lineWidth: 1)
                )
                .animation(.easeInOut, value: isFocused)
            
        case .circle:
            Circle()
                .stroke(showError ? errorColor : (isFocused ? focusedColor : unfocusedColor), lineWidth: 3)
                .background(
                    Circle()
                        .fill(showError ? errorColor.opacity(0.3) : (isFilled ? filledColor : Color.clear))
                )
                .animation(.easeInOut, value: isFocused)
            
        case .shadow:
                    RoundedRectangle(cornerRadius: 10)
                        .fill(showError ? Color.red.opacity(0.3) : (isFilled ? filledColor : Color.white))
                        .shadow(color: showError ? Color.red.opacity(0.6) : (isFocused ? focusedColor.opacity(0.1) : unfocusedColor.opacity(0.9)), radius: 5, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(showError ? errorColor : (isFocused ? focusedColor : unfocusedColor), lineWidth: 1)
                        )
                        .animation(.easeInOut, value: isFocused)
            
        case .custom(let builder):
            builder(isFocused, isFilled)
        }
    }
}
