//
//  SettingsTVC.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit

final class SettingsTVC: UITableViewController {
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		TipJarViewModel.shared.ui = self
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if TipJarViewModel.shared.status == .notYetFirstLoaded {
			PurchaseManager.shared.requestTipProduct()
		}
		
		title = LRString.settings
	}
}
