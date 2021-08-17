//
//  protocol NoItemsBackgroundManager.swift
//  LavaRock
//
//  Created by h on 2021-08-01.
//

import UIKit

protocol NoItemsBackgroundManager {
	var noItemsBackgroundView: UITableViewCell? { get }
	
	var tableView: UITableView! { get }
	var viewModel: LibraryViewModel { get }
}

extension NoItemsBackgroundManager {
	
	// Call this in UITableViewDataSource.tableView(_:numberOfRowsInSection:).
	// - Don't call this in UITableViewDataSource.numberOfSections(in:), because VoiceOver will move focus from the tab bar directly to the navigation bar title, skipping over the placeholder. (It will move focus to the placeholder if you tap there, but then you won't be able to move focus out until you tap elsewhere.)
	// - If you call this in numberOfRowsInSection, then VoiceOver moves focus from the tab bar to the placeholder, then to the navigation bar title, as expected.
	func setOrRemoveNoItemsBackground() {
		if viewModel.isEmpty() {
			tableView.backgroundView = noItemsBackgroundView // Don't use dequeueReusableCell within numberOfRowsInSection to create the placeholder view as needed, because that might call numberOfRowsInSection, causing an infinite loop.
		} else {
			tableView.backgroundView = nil
		}
	}
	
}
