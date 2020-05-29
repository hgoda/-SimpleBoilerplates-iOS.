//
//  SignUpVM.swift
//  ExtraaNumber
//
//  Created by sadman samee on 26/1/19.
//  Copyright © 2019 sadman samee. All rights reserved.
//


import Moya
import RxRelay
import RxSwift
import SwiftyJSON

class SignUpVM {

    fileprivate var authProvider : MoyaProvider<AuthService>

    init(service : MoyaProvider<AuthService>) {
        authProvider = service
    }
    
    //let authProvider = MoyaProvider<AuthService>(plugins: [NetworkLoggerPlugin(verbose: true, responseDataFormatter: JSONResponseDataFormatter)])

    private let isLoadingVariable = BehaviorRelay(value: false)
    private let alertMessageVariable = PublishSubject<AlertMessage>()

    var onShowingLoading: Observable<Bool> {
        return isLoadingVariable.asObservable()
                .distinctUntilChanged()
    }

    var onShowAlert: Observable<AlertMessage> {
        return alertMessageVariable.asObservable()
    }

    private let successVariable = PublishSubject<JSON>()

    var onSuccess: Observable<JSON> {
        return successVariable.asObservable()
    }

    var email = BehaviorRelay<String?>(value: nil)
    var password = BehaviorRelay<String?>(value: nil)
    var fullName = BehaviorRelay<String?>(value: nil)

    var isValid: Observable<Bool> {
        return Observable.combineLatest(email, password) { email, password in

            guard let email = email, let password = password else {
                return false
            }
            return email.count > 0
                    && password.count > 0
        }.share()
    }

    func signUp() {
        if let fullName = fullName.value, let email = email.value, let password = password.value {
            isLoadingVariable.accept(true)

            authProvider.request(.signUp(fullName, email, password), completion: { result in
                self.isLoadingVariable.accept(false)
                if case let .success(response) = result {
                    do {
                        let json = try JSON(data: response.data)
                        if !json.isError {
                            self.successVariable.onNext(json)
                        } else {
                            self.alertMessageVariable.onNext(AlertMessage(title: json.message, message: ""))
                        }
                    } catch {
                        self.alertMessageVariable.onNext(AlertMessage(title: error.localizedDescription, message: ""))
                    }
                } else {
                    self.alertMessageVariable.onNext(AlertMessage(title: result.error?.errorDescription, message: ""))
                }
            })
        }
    }
}
