//
//  PurchaseManager.swift
//  LavaRock
//
//  Created by h on 2020-12-27.
//

import StoreKit

final class PurchaseManager: NSObject { // Inherit from `NSObject` to more easily conform to `SKProductsRequestDelegate` and `SKPaymentTransactionObserver`, which inherit from `NSObjectProtocol`.
	private override init() {}
	static let shared = PurchaseManager()
	
	func beginObservingPaymentTransactions() {
		Self.paymentQueue.add(self)
	}
	
	@MainActor
	func requestTipProduct() {
		tipProductRequest.start()
		
		TipJarViewModel.shared.status = .loading
	}
	
	var tipTitle: String? {
		return tipProduct?.localizedTitle
	}
	
	var tipPrice: String? {
		guard let tipProduct = tipProduct else { return nil }
		
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		formatter.locale = tipProduct.priceLocale
		
		return formatter.string(from: tipProduct.price)
	}
	
	@MainActor
	func buyTip() {
		guard let tipProduct = tipProduct else { return }
		let payment = SKPayment(product: tipProduct)
//		let payment = SKMutablePayment(product: tipProduct)
//		payment.simulatesAskToBuyInSandbox = true
		Self.paymentQueue.add(payment)
		
		TipJarViewModel.shared.status = .confirming
	}
	
	// MARK: - Private
	
	private static let tipProductID = "com.loudsounddreams.LavaRock.tip"
	private lazy var tipProductRequest: SKProductsRequest = {
		let productIdentifiers: Set<String> = [Self.tipProductID]
		let result = SKProductsRequest(productIdentifiers: productIdentifiers)
		result.delegate = self
		return result
	}()
	private lazy var tipProduct: SKProduct? = nil
	private static let paymentQueue: SKPaymentQueue = .default()
	
	deinit {
		Self.paymentQueue.remove(self)
	}
}
extension PurchaseManager: SKProductsRequestDelegate {
	// StoreKit can call `SKProductsRequestDelegate` methods on any thread.
	
	func productsRequest(
		_ request: SKProductsRequest,
		didReceive response: SKProductsResponse
	) {
		DispatchQueue.main.async {
			response.products.forEach { product in
				switch product.productIdentifier {
				case Self.tipProductID:
					self.tipProduct = product
					
					TipJarViewModel.shared.status = .ready
				default:
					break
				}
			}
		}
	}
	
	func request(
		_ request: SKRequest,
		didFailWithError error: Error
	) {
		DispatchQueue.main.async {
			if self.tipProductRequest == request {
				TipJarViewModel.shared.status = .reload
			}
		}
	}
}
extension PurchaseManager: SKPaymentTransactionObserver {
	func paymentQueue(
		_ queue: SKPaymentQueue,
		updatedTransactions transactions: [SKPaymentTransaction])
	{
		DispatchQueue.main.async {
			transactions.forEach { transaction in
				switch transaction.payment.productIdentifier {
				case Self.tipProductID:
					self.handleTipTransaction(transaction)
				default:
					break
				}
			}
		}
	}
	
	@MainActor
	private func handleTipTransaction(_ tipTransaction: SKPaymentTransaction) {
		switch tipTransaction.transactionState {
		case .purchasing:
			break
		case .deferred:
			TipJarViewModel.shared.status = .ready
		case
				.failed,
				.restored:
			Self.paymentQueue.finishTransaction(tipTransaction)
			TipJarViewModel.shared.status = .ready
		case .purchased:
			Self.paymentQueue.finishTransaction(tipTransaction)
			TipJarViewModel.shared.status = .thankYou
		@unknown default:
			fatalError()
		}
	}
}
