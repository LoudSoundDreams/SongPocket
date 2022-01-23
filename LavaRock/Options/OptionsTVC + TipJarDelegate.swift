//
//  OptionsTVC + TipJarDelegate.swift
//  LavaRock
//
//  Created by h on 2020-12-27.
//

import StoreKit

extension OptionsTVC: TipJarDelegate {
	final func statusBecameReload() {
		refreshTipJarRows()
	}
	
	final func statusBecameReady() {
		refreshTipJarRows()
	}
	
	final func tipTransactionUpdated(_ transaction: SKPaymentTransaction) {
		switch transaction.transactionState {
		case .purchasing:
			break
		case .failed:
			refreshTipJarRows()
			SKPaymentQueue.default().finishTransaction(transaction)
		case .deferred:
			refreshTipJarRows()
		case .purchased:
			SKPaymentQueue.default().finishTransaction(transaction)
			tipJarIsShowingThankYou = true
			Task {
				try await Task.sleep(nanoseconds: 10_000_000_000)
				
				tipJarIsShowingThankYou = false
			}
		case .restored:
			refreshTipJarRows()
			SKPaymentQueue.default().finishTransaction(transaction)
		@unknown default:
			fatalError()
		}
	}
}
