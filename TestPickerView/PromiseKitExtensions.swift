////
///  PromiseKitExtensions.swift
//

import PromiseKit


extension Promise {

    @discardableResult
    func ignoreErrors() -> Promise<T> {
        self.catch { _ in }
        return self
    }
}
