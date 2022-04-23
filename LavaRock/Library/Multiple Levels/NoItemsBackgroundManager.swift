//
//  NoItemsBackgroundManager.swift
//  LavaRock
//
//  Created by h on 2021-08-01.
//

import UIKit

@MainActor
protocol NoItemsBackgroundManager {
	var noItemsBackgroundView: UITableViewCell? { get }
	
	var tableView: UITableView! { get }
	var viewModel: LibraryViewModel { get }
}
extension NoItemsBackgroundManager {
	// Call this in `UITableViewDataSource.numberOfSections(in:)`.
	func setOrRemoveNoItemsBackground() {
		if viewModel.isEmpty() {
			tableView.backgroundView = noItemsBackgroundView // Don’t use `dequeueReusableCell` within `numberOfRowsInSection` to create the placeholder view as needed, because that might call `numberOfRowsInSection`, causing an infinite loop.
		} else {
			tableView.backgroundView = nil
		}
	}
}
