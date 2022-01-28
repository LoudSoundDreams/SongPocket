//
//  OptionsTVC + TipJarDelegate.swift
//  LavaRock
//
//  Created by h on 2020-12-27.
//

import StoreKit

extension OptionsTVC: TipJarDelegate {
	final func statusBecameLoading() {
		refreshTipJarRows()
	}
	final func statusBecameReload() {
		refreshTipJarRows()
	}
	final func statusBecameReady() {
		refreshTipJarRows()
	}
	final func statusBecameConfirming() {
		refreshTipJarRows()
	}
	final func statusBecameThankYou() {
		refreshTipJarRows()
	}
}
