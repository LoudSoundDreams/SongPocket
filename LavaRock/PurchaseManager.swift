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

final class PurchaseManager: NSObject {
	
	// MARK: Types
	
	enum ProductIdentifier: String, CaseIterable {
		case tip = "com.loudsounddreams.LavaRock.tip"
	}
	
	enum TipStatus {
		case notYetFirstLoaded, loading, reload, ready, confirming
	}
	
	// MARK: Properties
	
	// Constants
	static let shared = PurchaseManager()
	
	// Variables
	lazy var tipStatus: TipStatus = .notYetFirstLoaded
	lazy var savedSKProductsRequest: SKProductsRequest? = nil
	lazy var priceFormatter: NumberFormatter? = nil
	lazy var tipProduct: SKProduct? = nil
	weak var tipDelegate: PurchaseManagerTipDelegate?
	// For testing only
//	lazy var isTestingDidFailToReceiveAnySKProducts = true
	
	// MARK: Setup and Teardown
	
	private override init() { }
	
	deinit {
		endObservingPaymentTransactions()
	}
	
	final func beginObservingPaymentTransactions() {
		SKPaymentQueue.default().add(self)
	}
	
	private func endObservingPaymentTransactions() {
		SKPaymentQueue.default().remove(self)
	}
	
	// MARK: Other
	
	final func requestAllSKProducts() {
		tipStatus = .loading
		var setOfIdentifiers = Set<String>()
		for identifier in ProductIdentifier.allCases {
			setOfIdentifiers.insert(identifier.rawValue)
		}
		let productsRequest = SKProductsRequest(productIdentifiers: setOfIdentifiers)
		productsRequest.delegate = self
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
	
}

// MARK: - SKProductsRequestDelegate

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
		
		guard response.products.count >= 1 else {
			didFailToReceiveAnySKProducts()
			return
		}
		
		if let priceLocale = response.products.first?.priceLocale {
			setUpPriceFormatter(locale: priceLocale)
		}
		for product in response.products {
			switch product.productIdentifier {
			case ProductIdentifier.tip.rawValue:
				tipProduct = product
				tipStatus = .ready
				tipDelegate?.didReceiveTipProduct(product)
			default:
				break
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
		for identifier in ProductIdentifier.allCases {
			switch identifier {
			case .tip:
				tipStatus = .reload
				tipDelegate?.didFailToReceiveTipProduct()
			}
		}
	}
	
	private func setUpPriceFormatter(locale: Locale) {
		let formatter = NumberFormatter()
		formatter.numberStyle = .currency
		formatter.locale = locale
		priceFormatter = formatter
	}
	
}

// MARK: SKPaymentTransasctionObserver

extension PurchaseManager: SKPaymentTransactionObserver {
	
	func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
		for transaction in transactions {
			switch transaction.payment.productIdentifier {
			case ProductIdentifier.tip.rawValue:
				switch transaction.transactionState {
				case .purchasing:
					break
				case .deferred, .failed, .purchased, .restored:
					tipStatus = .ready
				@unknown default:
					fatalError()
				}
				tipDelegate?.didUpdateTipTransaction(transaction)
			default:
				break
			}
		}
	}
	
}
