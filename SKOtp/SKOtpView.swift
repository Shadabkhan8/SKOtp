//
//  SKOtpView.swift
//  SKOtp
//
//  Created by Shadab khan on 21/05/25.
//

import SwiftUICore
import Combine
import SwiftUI

public struct SKOtpView: View {
    @Binding var otp: String
    @FocusState private var isFocused: Bool
    @State private var showCursor: Bool = true
    @State private var timeRemaining: Int = 60
    @State private var shakeOffset: CGFloat = 0
    @State private var shake = false
    @State private var showError = false
    @State private var showingValidAlert = false
    @State private var remainingTime: Int = 0
    @State private var isExpired: Bool = false
    @State private var timer: Timer?
    @State private var isResending: Bool = false

    private let autoSubmitOnFullEntry: Bool
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
    private let expiresIn: Int?
    private let onExpire: (() -> Void)?
    private let onResend: (() -> Void)?

    private let localOtp = "12345678" // For demo/testing

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
        autoSubmitOnFullEntry: Bool = true,
        expiresIn: Int? = nil,
        onExpire: (() -> Void)? = nil,
        onResend: (() -> Void)? = nil,
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
        self.autoSubmitOnFullEntry = autoSubmitOnFullEntry
        self.expiresIn = expiresIn
        self.onExpire = onExpire
        self.onResend = onResend
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
//            .disabled(isExpired)
            .keyboardType(isAlphanumeric ? .asciiCapable : .numberPad)
            .textInputAutocapitalization(.characters)
            .disableAutocorrection(true)
            .focused($isFocused)
            .textContentType(.oneTimeCode)
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .onChange(of: otp) { newValue in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                if newValue.count == maxLength {
                    isFocused = false
                    if autoSubmitOnFullEntry && isOtpValid {
                        validateOtpAndSubmit()
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { isFocused = false }
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

                            if index == otp.count && otp.count < maxLength && isFocused {
                                Rectangle()
                                    .fill(cursorColor)
                                    .frame(width: 2, height: 32)
                                    .opacity(showCursor ? 1 : 0)
                                    .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: showCursor)
                            } else if index == maxLength - 1 && otp.count == maxLength && isFocused {
                                Rectangle()
                                    .fill(cursorColor)
                                    .frame(width: 2, height: 32)
                                    .offset(x: 10)
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
            .onTapGesture { isFocused = true }

            if let expiresIn {
                if !isExpired {
                    Label("Expires in \(remainingTime)s", systemImage: "clock")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .clipShape(Capsule())
                        .transition(.opacity.combined(with: .scale))
                } else {
                    VStack(spacing: 8) {
                        Text("OTP expired")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .clipShape(Capsule())
                            .transition(.opacity.combined(with: .scale))
                    }
                }
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
            }
            .disabled(!isOtpValid)
            if let onResend {
                Button(action: {
                    isResending = true
                    otp = ""
                    isExpired = false
                    startTimer(seconds: expiresIn ?? 60)
                    onResend()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        isResending = false
                    }
                }) {
                    Text(isResending ? "Sending..." : "Resend OTP")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.blue)
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 1)
                        )
                }
            }
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
            if let expiresIn { startTimer(seconds: expiresIn) }
        }
        .onDisappear { timer?.invalidate() }
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

    private func startTimer(seconds: Int) {
        remainingTime = seconds
        isExpired = false
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
            }
            if remainingTime == 0 {
                isExpired = true
                timer?.invalidate()
                onExpire?()
            }
        }
    }

    private func triggerShake() {
        withAnimation { shakeOffset = 10 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation { shakeOffset = -10 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation { shakeOffset = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showError = false
            }
        }
    }

    private func validateOtpAndSubmit() {
        if otp == localOtp {
            showingValidAlert = true
            onSubmit()
        } else {
            showError = true
            triggerShake()
        }
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
