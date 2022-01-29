//
//  OptionsTVC + TipJarUI.swift
//  LavaRock
//
//  Created by h on 2020-12-27.
//

extension OptionsTVC: TipJarUI {
	final func statusBecameLoading() {
		freshenTipJarRows()
	}
	final func statusBecameReload() {
		freshenTipJarRows()
	}
	final func statusBecameReady() {
		freshenTipJarRows()
	}
	final func statusBecameConfirming() {
		freshenTipJarRows()
	}
	final func statusBecameThankYou() {
		freshenTipJarRows()
	}
}
