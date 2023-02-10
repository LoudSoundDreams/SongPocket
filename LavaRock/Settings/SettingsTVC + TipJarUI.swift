//
//  SettingsTVC + TipJarUI.swift
//  LavaRock
//
//  Created by h on 2020-12-27.
//

extension SettingsTVC: TipJarUI {
	func statusBecameLoading() {
		freshenTipJarRows()
	}
	func statusBecameReload() {
		freshenTipJarRows()
	}
	func statusBecameReady() {
		freshenTipJarRows()
	}
	func statusBecameConfirming() {
		freshenTipJarRows()
	}
	func statusBecameThankYou() {
		freshenTipJarRows()
	}
}
