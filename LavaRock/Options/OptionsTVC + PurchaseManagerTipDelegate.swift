//
//  OptionsTVC + PurchaseManagerTipDelegate.swift
//  LavaRock
//
//  Created by h on 2020-12-27.
//

import StoreKit

extension OptionsTVC: PurchaseManagerTipDelegate {
	final func didReceiveTipProduct(_ tipProduct: SKProduct) {
		DispatchQueue.main.async {
			self.refreshTipJarRows()
		}
	}
	
	final func didFailToReceiveTipProduct() {
		DispatchQueue.main.async {
			self.refreshTipJarRows()
		}
	}
	
	final func didUpdateTipTransaction(_ tipTransaction: SKPaymentTransaction) {
		switch tipTransaction.transactionState {
		case .purchasing:
			break
		case .deferred:
			cancelTip()
		case .failed:
			print("SKPaymentTransaction for a tip failed. Error: \(String(describing: tipTransaction.error))")
			cancelTip()
			finish(tipTransaction: tipTransaction)
		case .purchased:
			didReceiveTip()
			finish(tipTransaction: tipTransaction)
		case .restored:
			// Tips are consumable and don't need to be restored
			cancelTip()
			finish(tipTransaction: tipTransaction)
		@unknown default:
			fatalError()
		}
	}
	
	private func didReceiveTip() {
		tipJarIsShowingThankYou = true
		Task {
			try await Task.sleep(nanoseconds: 10_000_000_000)
			
			tipJarIsShowingThankYou = false
		}
	}
	
	private func cancelTip() {
		refreshTipJarRows()
	}
	
	private func finish(tipTransaction: SKPaymentTransaction) {
		SKPaymentQueue.default().finishTransaction(tipTransaction)
	}
}
