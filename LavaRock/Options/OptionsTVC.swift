//
//  OptionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit

final class OptionsTVC: UITableViewController {
	
	// MARK: - Properties
	
	// Variables
	final var shouldShowTemporaryThankYouMessage = false
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		PurchaseManager.shared.tipDelegate = self
	}
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		if PurchaseManager.shared.tipStatus == .notYetFirstLoaded {
			PurchaseManager.shared.requestAllSKProducts() // It should be safe to do this at this point, even if we both receive the response and refresh the table view extremely soon.
		}
	}
	
}
