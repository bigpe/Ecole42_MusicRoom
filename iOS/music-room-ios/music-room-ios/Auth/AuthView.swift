import SwiftUI
import AlertToast

struct AuthView: View {
    var api: API!
    
    @EnvironmentObject
    var viewModel: ViewModel
    
    @EnvironmentObject
    var authViewModel: AuthViewModel
    
    var focusedField: FocusState<Field?>.Binding
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Sign In")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    
                    TextField(text: $authViewModel.usernameText) {
                        Text("Username")
                    }
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)
                    .focused(focusedField, equals: .authUsername)
                    
                    SecureField("Password", text: $authViewModel.passwordText)
                        .textFieldStyle(.roundedBorder)
                        .focused(focusedField, equals: .authPassword)
                }
                
                Button {
                    let username = authViewModel.usernameText
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    let password = authViewModel.passwordText
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    guard
                        !authViewModel.isLoading,
                        !username.isEmpty,
                        password.count >= 8
                    else {
                        return // FIXME: Error Message
                    }
                    
                    Task {
                        await MainActor.run {
                            authViewModel.isLoading = true
                        }
                        
                        do {
                            try await viewModel.auth(username, password)
                            
                            await MainActor.run {
                                authViewModel.isLoading = false
                                authViewModel.isShowing = false
                            }
                        } catch {
                            debugPrint(error)
                            
                            await MainActor.run {
                                authViewModel.isLoading = false
                            }
                            
                            // FIXME: Error Message
                        }
                    }
                } label: {
                    if !authViewModel.isLoading {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(viewModel.primaryControlsColor)
                            .frame(maxWidth: .infinity, maxHeight: 24)
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(viewModel.primaryControlsColor)
                            .frame(maxWidth: .infinity, maxHeight: 24)
                    }
                    
                }
                .buttonStyle(.borderedProminent)
                .tint(.pink)
            }

        }
        .padding(.horizontal, 16)
        .interactiveDismissDisabled()
        .toast(
            isPresenting: $viewModel.isSignInToastShowing,
            duration: 3,
            tapToDismiss: true,
            offsetY: 32,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: viewModel.signInToastType,
                    title: viewModel.signInToastTitle,
                    subTitle: viewModel.signInToastSubtitle,
                    style: nil
                )
            }
        )
    }
}
