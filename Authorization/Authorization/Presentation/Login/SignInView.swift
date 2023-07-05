//
//  SignInView.swift
//  Authorization
//
//  Created by Vladimir Chekyrta on 13.09.2022.
//

import SwiftUI
import Core

public struct SignInView: View {
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    @ObservedObject
    private var viewModel: SignInViewModel
    
    public init(viewModel: SignInViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            VStack {
                CoreAssets.authBackground.swiftUIImage
                    .resizable()
                    .edgesIgnoringSafeArea(.top)
            }.frame(maxWidth: .infinity, maxHeight: 200)
            
            VStack(alignment: .center) {
                CoreAssets.appLogo.swiftUIImage
                    .resizable()
                    .frame(maxWidth: 189, maxHeight: 54)
                    .padding(.vertical, 40)
                
                ScrollView {
                    VStack {
                        VStack(alignment: .leading) {
                            Text(AuthLocalization.SignIn.logInTitle)
                                .font(Theme.Fonts.displaySmall)
                                .foregroundColor(CoreAssets.textPrimary.swiftUIColor)
                                .padding(.bottom, 4)
                            Text(AuthLocalization.SignIn.welcomeBack)
                                .font(Theme.Fonts.titleSmall)
                                .foregroundColor(CoreAssets.textPrimary.swiftUIColor)
                                .padding(.bottom, 20)
                            
                            Text(AuthLocalization.SignIn.email)
                                .font(Theme.Fonts.labelLarge)
                                .foregroundColor(CoreAssets.textPrimary.swiftUIColor)
                            TextField(AuthLocalization.SignIn.email, text: $email)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                                .padding(.all, 14)
                                .background(
                                    Theme.Shapes.textInputShape
                                        .fill(CoreAssets.textInputBackground.swiftUIColor)
                                )
                                .overlay(
                                    Theme.Shapes.textInputShape
                                        .stroke(lineWidth: 1)
                                        .fill(CoreAssets.textInputStroke.swiftUIColor)
                                )
                            
                            Text(AuthLocalization.SignIn.password)
                                .font(Theme.Fonts.labelLarge)
                                .foregroundColor(CoreAssets.textPrimary.swiftUIColor)
                                .padding(.top, 18)
                            SecureField(AuthLocalization.SignIn.password, text: $password)
                                .padding(.all, 14)
                                .background(
                                    Theme.Shapes.textInputShape
                                        .fill(CoreAssets.textInputBackground.swiftUIColor)
                                )
                                .overlay(
                                    Theme.Shapes.textInputShape
                                        .stroke(lineWidth: 1)
                                        .fill(CoreAssets.textInputStroke.swiftUIColor)
                                )
                            
                            HStack {
                                Button(AuthLocalization.SignIn.registerBtn) {
                                    viewModel.analytics.signUpClicked()
                                    viewModel.router.showRegisterScreen()
                                }.foregroundColor(CoreAssets.accentColor.swiftUIColor)
                                
                                Spacer()
                                
                                Button(AuthLocalization.SignIn.forgotPassBtn) {
                                    viewModel.analytics.forgotPasswordClicked()
                                    viewModel.router.showForgotPasswordScreen()
                                }.foregroundColor(CoreAssets.accentColor.swiftUIColor)
                            }
                            .padding(.top, 10)
                            if viewModel.isShowProgress {
                                HStack(alignment: .center) {
                                    ProgressBar(size: 40, lineWidth: 8)
                                        .padding(20)
                                }.frame(maxWidth: .infinity)
                            } else {
                                StyledButton(AuthLocalization.SignIn.logInBtn) {
                                    Task {
                                        await viewModel.login(username: email, password: password)
                                    }
                                }.frame(maxWidth: .infinity)
                                    .padding(.top, 40)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 50)
                }.roundedBackground(CoreAssets.background.swiftUIColor)
                    .scrollAvoidKeyboard(dismissKeyboardByTap: true)
                
            }
            
            // MARK: - Alert
            if viewModel.showAlert {
                VStack {
                    Text(viewModel.alertMessage ?? "")
                        .shadowCardStyle(bgColor: CoreAssets.accentColor.swiftUIColor,
                                         textColor: .white)
                        .padding(.top, 80)
                    Spacer()
                    
                }
                .transition(.move(edge: .top))
                .onAppear {
                    doAfter(Theme.Timeout.snackbarMessageLongTimeout) {
                        viewModel.alertMessage = nil
                    }
                }
            }
            
            // MARK: - Show error
            if viewModel.showError {
                VStack {
                    Spacer()
                    SnackBarView(message: viewModel.errorMessage)
                }.transition(.move(edge: .bottom))
                    .onAppear {
                        doAfter(Theme.Timeout.snackbarMessageLongTimeout) {
                            viewModel.errorMessage = nil
                        }
                    }
            }
        }
        .background(CoreAssets.background.swiftUIColor.ignoresSafeArea(.all))
    }
}

#if DEBUG
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = SignInViewModel(
            interactor: AuthInteractor.mock,
            router: AuthorizationRouterMock(),
            analytics: AuthorizationAnalyticsMock(),
            validator: Validator()
        )
        
        SignInView(viewModel: vm)
            .preferredColorScheme(.light)
            .previewDisplayName("SignInView Light")
            .loadFonts()
        
        SignInView(viewModel: vm)
            .preferredColorScheme(.dark)
            .previewDisplayName("SignInView Dark")
            .loadFonts()
    }
}
#endif
