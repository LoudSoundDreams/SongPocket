//
//  PurchaseManagerTipDelegate - OptionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-12-27.
//

import StoreKit

extension OptionsTVC: PurchaseManagerTipDelegate {
	
	final func didReceiveTipProduct(_ tipProduct: SKProduct) {
		if tipStatus != .ready {
			DispatchQueue.main.async {
				self.tipStatus = .ready
				self.refreshTipJarRows()
			}
		}
	}
	
	final func didUpdateTipTransaction(_ tipTransaction: SKPaymentTransaction) {
		switch tipTransaction.transactionState {
		case .purchasing, .deferred:
			break
		case .failed:
			print("SKPaymentTransaction for a tip failed. Error: \(String(describing: tipTransaction.error))")
			deselectAllRows()
			finish(tipTransaction: tipTransaction)
		case .purchased:
			didReceiveTip()
			finish(tipTransaction: tipTransaction)
		case .restored:
			deselectAllRows()
			finish(tipTransaction: tipTransaction) // Tips are consumable and don't need to be restored
		@unknown default:
			fatalError()
		}
	}
	
	private func didReceiveTip() {
		tipStatus = .thankYou
		refreshTipJarRows()
		DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: { [weak self] in // Don't retain this view controller just do do this work.
			self?.tipStatus = .ready
			self?.refreshTipJarRows()
		})
	}
	
	private func deselectAllRows() {
		tableView.deselectAllRows(animated: true)
	}
	
	private func finish(tipTransaction: SKPaymentTransaction) {
		SKPaymentQueue.default().finishTransaction(tipTransaction)
	}
	
}
