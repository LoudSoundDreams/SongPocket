//
//  OptionsTVC + TipJarUI.swift
//  LavaRock
//
//  Created by h on 2020-12-27.
//

@MainActor
extension OptionsTVC: TipJarUI {
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
