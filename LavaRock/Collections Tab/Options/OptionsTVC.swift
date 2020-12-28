//
//  OptionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit

final class OptionsTVC: UITableViewController {
	
	// MARK: - Types
	
	enum TipStatus {
		case notReady, ready, purchasing, thankYou
	}
	
	// MARK: - Properties
	
	// Variables
	final var tipStatus: TipStatus = {
		if PurchaseManager.shared.tipProduct == nil { // Keep tipProduct in PurchaseManager, not here, so that we don't have to download it every time we open the Options sheet.
			return .notReady
		} else {
			return .ready
		}
	}()
	
	// MARK: - Setup
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		PurchaseManager.shared.tipDelegate = self
	}
	
	final override func viewDidLoad() {
		super.viewDidLoad()
		
		if tipStatus == .notReady {
			PurchaseManager.shared.requestAllSKProducts() // It should be safe to do this at this point, even if we both receive the response and refresh the table view extremely soon.
		}
	}
	
}
