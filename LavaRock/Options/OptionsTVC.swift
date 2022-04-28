//
//  OptionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit

final class OptionsTVC: UITableViewController {
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		TipJarViewModel.shared.ui = self
	}
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		if TipJarViewModel.shared.status == .notYetFirstLoaded {
			PurchaseManager.shared.requestTipProduct()
		}
	}
	
	@IBAction private func doneWithOptionsSheet(_ sender: UIBarButtonItem) {
		dismiss(animated: true)
	}
}
