//
//  PurchaseManager.swift
//  LavaRock
//
//  Created by h on 2020-12-27.
//

import StoreKit

protocol PurchaseManagerTipDelegate: AnyObject {
	func didReceiveTipProduct(_ tipProduct: SKProduct)
	func didFailToReceiveTipProduct()
	func didUpdateTipTransaction(_ tipTransaction: SKPaymentTransaction)
}

final class PurchaseManager: NSObject { // This type inherits from NSObject because that makes it easier to make it conform to SKProductsRequestDelegate and SKPaymentTransactionObserver, which inherit from NSObjectProtocol.
	
	private override init() {}
	
	enum TipStatus {
		case notYetFirstLoaded
		case loading
		case reload
		case ready
		case confirming
	}
	
	static let shared = PurchaseManager() // We can't make everything in this class static, because StoreKit only works with instances, not types.
	
	private(set) lazy var tipStatus: TipStatus = .notYetFirstLoaded
	private(set) lazy var tipProduct: SKProduct? = nil
	private(set) lazy var tipPriceFormatter: NumberFormatter? = nil
	weak var tipDelegate: PurchaseManagerTipDelegate?
	
	final func beginObservingPaymentTransactions() {
		SKPaymentQueue.default().add(self) // We can't make this method static, because StoreKit needs an instance here, not a type.
	}
	
	final func requestAllSKProducts() {
		tipStatus = .loading
		let identifiers = ProductIdentifier.allCases.map { $0.rawValue }
		let productsRequest = SKProductsRequest(productIdentifiers: Set(identifiers))
		productsRequest.delegate = self // We can't make this method static, because StoreKit needs an instance here, not a type.
		productsRequest.start()
		savedSKProductsRequest = productsRequest
	}
	
	final func addToPaymentQueue(_ skProduct: SKProduct?) {
		guard let skProduct = skProduct else { return }
		
		switch skProduct {
		case tipProduct:
			tipStatus = .confirming
		default:
			break
		}
		let skPayment = SKPayment(product: skProduct)
//		let skPayment = SKMutablePayment(product: skProduct)
//		skPayment.simulatesAskToBuyInSandbox = true
		SKPaymentQueue.default().add(skPayment)
	}
	
	// MARK: - PRIVATE
	
	private enum ProductIdentifier: String, CaseIterable {
		case tip = "com.loudsounddreams.LavaRock.tip"
	}
	
	private lazy var savedSKProductsRequest: SKProductsRequest? = nil
	// For testing only
//	private lazy var isTestingDidFailToReceiveAnySKProducts = true
	
	deinit {
		endObservingPaymentTransactions()
	}
	
	private func endObservingPaymentTransactions() {
		SKPaymentQueue.default().remove(self)
	}
	
}

extension PurchaseManager: SKProductsRequestDelegate {
	
	final func productsRequest(
		_ request: SKProductsRequest,
		didReceive response: SKProductsResponse
	) {
		// For testing only
//		if isTestingDidFailToReceiveAnySKProducts {
//			isTestingDidFailToReceiveAnySKProducts = false
//
//			didFailToReceiveAnySKProducts()
//			return
//		}
		
		guard !response.products.isEmpty else {
			didFailToReceiveAnySKProducts()
			return
		}
		
		response.products.forEach { product in
			let rawIdentifier = product.productIdentifier
			guard let productIdentifier = ProductIdentifier(rawValue: rawIdentifier) else { return }
			switch productIdentifier {
			case .tip:
				tipPriceFormatter = makePriceFormatter(locale: product.priceLocale)
				tipProduct = product
				tipStatus = .ready
				tipDelegate?.didReceiveTipProduct(product)
			}
		}
	}
	
	final func request(
		_ request: SKRequest,
		didFailWithError error: Error
	) {
		if request == savedSKProductsRequest {
			didFailToReceiveAnySKProducts()
		}
	}
	
	private func didFailToReceiveAnySKProducts() {
		ProductIdentifier.allCases.forEach {
			switch $0 {
			case .tip:
				tipStatus = .reload
				tipDelegate?.didFailToReceiveTipProduct()
			}
		}
	}
	
	private func makePriceFormatter(locale: Locale) -> NumberFormatter {
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		formatter.locale = locale
		return formatter
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
				case .deferred, .failed, .purchased, .restored:
					tipStatus = .ready
				@unknown default:
					fatalError()
				}
				tipDelegate?.didUpdateTipTransaction(transaction)
			}
		}
	}
	
}
