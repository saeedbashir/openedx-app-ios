//
//  CourseUpgradeHandlerProtocol.swift
//  Core
//
//  Created by Vadim Kuznetsov on 22.05.24.
//

import Foundation

//sourcery: AutoMockable
public protocol CourseUpgradeHandlerProtocol {
    typealias UpgradeCompletionHandler = (UpgradeState) -> Void
    
    func upgradeCourse(
        sku: String?,
        mode: UpgradeMode,
        productInfo: StoreProductInfo?,
        pacing: String,
        courseID: String,
        componentID: String?,
        screen: CourseUpgradeScreen,
        completion: UpgradeCompletionHandler?
    ) async
    
    func fetchProduct(sku: String) async throws -> StoreProductInfo
}

class CourseUpgradeHandlerProtocolMock: CourseUpgradeHandlerProtocol {    
    func upgradeCourse(sku: String?, mode: UpgradeMode, productInfo: StoreProductInfo?, pacing: String, courseID: String, componentID: String?, screen: CourseUpgradeScreen, completion: UpgradeCompletionHandler?) async {
    }
    
    func fetchProduct(sku: String) async throws -> StoreProductInfo {
        StoreProductInfo(price: .zero)
    }
}
