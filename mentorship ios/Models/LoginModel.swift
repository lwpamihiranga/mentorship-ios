//
//  LoginModel.swift
//  Created on 05/06/20.
//  Created for AnitaB.org Mentorship-iOS 
//

import SwiftUI
import Combine

final class LoginModel: ObservableObject {
    // MARK: - Variables
    @Published var loginData = LoginUploadData(username: "", password: "")
    @Published var loginResponseData = LoginResponseData(message: "", accessToken: "")
    @Published var inActivity: Bool = false
    private var cancellable: AnyCancellable?

    var loginDisabled: Bool {
        if self.loginData.username.isEmpty || self.loginData.password.isEmpty {
            return true
        }
        return false
    }

    // MARK: - Main Function
    func login() {
        self.inActivity = true

        guard let uploadData = try? JSONEncoder().encode(loginData) else {
            self.inActivity = false
            return
        }

        cancellable = NetworkManager.callAPI(urlString: URLStringConstants.Users.login, httpMethod: "POST", uploadData: uploadData)
            .receive(on: RunLoop.main)
            .catch { _ in Just(self.loginResponseData) }
            .sink(receiveCompletion: { _ in
                self.inActivity = false
            }, receiveValue: { value in
                self.loginResponseData = value
                //if login successful, store access token in keychain
                if var token = value.accessToken {
                    token = "Bearer " + token
                    do {
                        try KeychainManager.addToKeychain(username: self.loginData.username, tokenString: token)
                        print("added")
                        UserDefaults.standard.set(true, forKey: UserDefaultsConstants.isLoggedIn)
                    } catch {
                        print("not added")
                        return
                    }
                }
            })
    }

    // MARK: - Structures
    struct LoginUploadData: Encodable {
        var username: String
        var password: String
    }

    struct LoginResponseData: Decodable {
        let message: String?
        let accessToken: String?

        enum CodingKeys: String, CodingKey {
            case message
            case accessToken = "access_token"
        }
    }
}
