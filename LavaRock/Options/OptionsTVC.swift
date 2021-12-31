//
//  OptionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit

final class OptionsTVC: UITableViewController {
	final var tipJarIsShowingThankYou = false
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		PurchaseManager.shared.tipDelegate = self
	}
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		if PurchaseManager.shared.tipStatus == .notYetFirstLoaded {
			PurchaseManager.shared.requestAllSKProducts()
		}
	}
	
	@IBAction private func doneWithOptionsSheet(_ sender: UIBarButtonItem) {
		dismiss(animated: true)
	}
}
