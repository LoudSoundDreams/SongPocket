//
//  PurchaseManager.swift
//  LavaRock
//
//  Created by h on 2020-12-27.
//

import StoreKit

final class PurchaseManager: NSObject { // Inherit from `NSObject` to more easily conform to `SKProductsRequestDelegate` and `SKPaymentTransactionObserver`, which inherit from `NSObjectProtocol`.
	private override init() {}
	static let shared = PurchaseManager() // We can’t turn everything in this class static, because StoreKit only works with instances, not types.
	
	private(set) lazy var tipProduct: SKProduct? = nil
	private(set) lazy var tipPriceFormatter: NumberFormatter? = nil
	
	final func beginObservingPaymentTransactions() {
		SKPaymentQueue.default().add(self) // We can’t turn this method static, because StoreKit needs an instance here, not a type.
	}
	
	final func requestAllSKProducts() {
		let identifiers = ProductIdentifier.allCases.map { $0.rawValue }
		let productsRequest = SKProductsRequest(productIdentifiers: Set(identifiers))
		productsRequest.delegate = self // We can’t turn this method static, because StoreKit needs an instance here, not a type.
		productsRequest.start()
		savedSKProductsRequest = productsRequest
		
		TipJarViewModel.shared.status = .loading
	}
	
	final func addToPaymentQueue(_ skProduct: SKProduct) {
		let skPayment = SKPayment(product: skProduct)
//		let skPayment = SKMutablePayment(product: skProduct)
//		skPayment.simulatesAskToBuyInSandbox = true
		SKPaymentQueue.default().add(skPayment)
		
		switch skProduct {
		case tipProduct:
			TipJarViewModel.shared.status = .confirming
		default:
			break
		}
	}
	
	// MARK: - PRIVATE
	
	private enum ProductIdentifier: String, CaseIterable {
		case tip = "com.loudsounddreams.LavaRock.tip"
	}
	
	private lazy var savedSKProductsRequest: SKProductsRequest? = nil
	// For testing only
//	private lazy var isTestingDidFailToReceiveAnySKProducts = true
	
	deinit {
		SKPaymentQueue.default().remove(self)
	}
}

extension PurchaseManager: SKProductsRequestDelegate {
	// StoreKit can call `SKProductsRequestDelegate` methods on any thread.
	
	final func productsRequest(
		_ request: SKProductsRequest,
		didReceive response: SKProductsResponse
	) {
		DispatchQueue.main.async {
			// For testing only
//			if self.isTestingDidFailToReceiveAnySKProducts {
//				self.isTestingDidFailToReceiveAnySKProducts = false
//				self.didFailToReceiveAnySKProducts()
//				return
//			}
			
			guard !response.products.isEmpty else {
				self.didFailToReceiveAnySKProducts()
				return
			}
			
			response.products.forEach { product in
				let rawIdentifier = product.productIdentifier
				guard let productIdentifier = ProductIdentifier(rawValue: rawIdentifier) else { return }
				switch productIdentifier {
				case .tip:
					self.tipProduct = product
					
					let formatter = NumberFormatter()
					formatter.numberStyle = .currency
					formatter.locale = product.priceLocale
					self.tipPriceFormatter = formatter
					
					TipJarViewModel.shared.status = .ready
				}
			}
		}
	}
	
	final func request(
		_ request: SKRequest,
		didFailWithError error: Error
	) {
		DispatchQueue.main.async {
			if request == self.savedSKProductsRequest {
				self.didFailToReceiveAnySKProducts()
			}
		}
	}
	
	private func didFailToReceiveAnySKProducts() {
		ProductIdentifier.allCases.forEach {
			switch $0 {
			case .tip:
				TipJarViewModel.shared.status = .reload
			}
		}
	}
}

extension PurchaseManager: SKPaymentTransactionObserver {
	final func paymentQueue(
		_ queue: SKPaymentQueue,
		updatedTransactions transactions: [SKPaymentTransaction])
	{
		transactions.forEach { transaction in
			guard let productIdentifier = ProductIdentifier(rawValue: transaction.payment.productIdentifier) else { return }
			switch productIdentifier {
			case .tip:
				switch transaction.transactionState {
				case .purchasing:
					break
				case .deferred:
					TipJarViewModel.shared.status = .ready
				case
						.failed,
						.restored:
					SKPaymentQueue.default().finishTransaction(transaction)
					TipJarViewModel.shared.status = .ready
				case .purchased:
					SKPaymentQueue.default().finishTransaction(transaction)
					TipJarViewModel.shared.status = .thankYou
				@unknown default:
					fatalError()
				}
			}
		}
	}
}
