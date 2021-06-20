//
//  OptionsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-12-27.
//

import UIKit

// MARK: - All Sections

extension OptionsTVC {
	
	private enum Section: Int, CaseIterable {
		case accentColor
		case tipJar
	}
	
	// MARK: Numbers
	
	final override func numberOfSections(in tableView: UITableView) -> Int {
		return Section.allCases.count
	}
	
	final override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		guard let sectionCase = Section(rawValue: section) else {
			return 0
		}
		switch sectionCase {
		case .accentColor:
			return AccentColor.all.count
		case .tipJar:
			return 1
		}
	}
	
	// MARK: Headers and Footers
	
	final override func tableView(
		_ tableView: UITableView,
		titleForHeaderInSection section: Int
	) -> String? {
		guard let sectionCase = Section(rawValue: section) else {
			return nil
		}
		switch sectionCase {
		case .accentColor:
			return LocalizedString.accentColor
		case .tipJar:
			return LocalizedString.tipJar
		}
	}
	
	final override func tableView(
		_ tableView: UITableView,
		titleForFooterInSection section: Int
	) -> String? {
		guard let sectionCase = Section(rawValue: section) else {
			return nil
		}
		switch sectionCase {
		case .accentColor:
			return nil
		case .tipJar:
			return LocalizedString.tipJarFooter
		}
	}
	
	// MARK: Cells
	
	final override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		guard let sectionCase = Section(rawValue: indexPath.section) else {
			return UITableViewCell()
		}
		switch sectionCase {
		case .accentColor:
			return accentColorCell(forRowAt: indexPath)
		case .tipJar:
			return tipJarCell(forRowAt: indexPath)
		}
	}
	
	final override func tableView(
		_ tableView: UITableView,
		willDisplay cell: UITableViewCell,
		forRowAt indexPath: IndexPath
	) {
		if
			PurchaseManager.shared.tipStatus == .confirming,
			indexPath.section == Section.tipJar.rawValue
		{
			cell.isSelected = true
		}
	}
	
	// MARK: Selecting
	
	final override func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		guard let sectionCase = Section(rawValue: indexPath.section) else { return }
		switch sectionCase {
		case .accentColor:
			didSelectAccentColorRow(at: indexPath)
		case .tipJar:
			didSelectTipJarRow(at: indexPath)
		}
	}
	
	// MARK: Events
	
	@IBAction func doneWithOptionsSheet(_ sender: UIBarButtonItem) {
		dismiss(animated: true)
	}
	
}

// MARK: - Accent Color Section

extension OptionsTVC {
	
	// MARK: Cells
	
	private func accentColorCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		let index = indexPath.row
		let rowAccentColor = AccentColor.all[index]
		
		let cell = tableView.dequeueReusableCell(
			withIdentifier: "Color Cell",
			for: indexPath)
		
		if #available(iOS 14, *) {
			var configuration = UIListContentConfiguration.cell()
			configuration.text = rowAccentColor.displayName
			configuration.textProperties.color = rowAccentColor.uiColor
			cell.contentConfiguration = configuration
		} else { // iOS 13 and earlier
			cell.textLabel?.text = rowAccentColor.displayName
			cell.textLabel?.textColor = rowAccentColor.uiColor
		}
		
		if rowAccentColor == AccentColor.savedPreference() { // Don't use view.window.tintColor, because if Increase Contrast is enabled, it won't match any rowAccentColor.uiColor.
			cell.accessoryType = .checkmark
		} else {
			cell.accessoryType = .none
		}
		
		cell.accessibilityTraits.formUnion(.button)
		
		return cell
	}
	
	// MARK: Selecting
	
	private func didSelectAccentColorRow(at indexPath: IndexPath) {
		let colorIndex = indexPath.row
		let selectedAccentColor = AccentColor.all[colorIndex]
		selectedAccentColor.set(in: view.window)
		
		func refreshCheckmarksOnAccentColorRows(selectedIndexPath: IndexPath) {
			if #available(iOS 14, *) { // See comment in the `else` block.
				
				func untickUnselectedAccentColorRows() {
					let accentColorIndexPaths = tableView.indexPathsForRows(
						inSection: Section.accentColor.rawValue,
						firstRow: 0)
					let unselectedAccentColorIndexPaths = accentColorIndexPaths.filter { accentColorIndexPath in
						accentColorIndexPath != selectedIndexPath // Don't use tableView.indexPathForSelectedRow, because we might have deselected the row already.
					}
					for unselectedIndexPath in unselectedAccentColorIndexPaths {
						if let unselectedCell = tableView.cellForRow(at: unselectedIndexPath) {
							unselectedCell.accessoryType = .none // Don't use reloadRows, because as of iOS 14.4 beta 1, that breaks tableView.deselectRow's animation.
						} else {
							tableView.reloadRows(at: [unselectedIndexPath], with: .none) // Should never run
						}
					}
				}
				
				func tickSelectedAccentColorRow() {
					if let selectedCell = tableView.cellForRow(at: selectedIndexPath) {
						selectedCell.accessoryType = .checkmark
						tableView.deselectRow(at: selectedIndexPath, animated: true)
					} else {
						tableView.reloadRows(at: [selectedIndexPath], with: .none) // Should never run
					}
				}
				
				func reloadAllOtherSections() {
					let allOtherSections = Section.allCases.filter { $0 != .accentColor }
					let allOtherSectionRawValues = allOtherSections.map { $0.rawValue }
					tableView.reloadSections(IndexSet(allOtherSectionRawValues), with: .none)
				}
				
				untickUnselectedAccentColorRows()
				tickSelectedAccentColorRow()
				reloadAllOtherSections()
				
			} else { // iOS 13
				tableView.reloadData()
				tableView.performBatchUpdates {
					tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
				} completion: { _ in
					self.tableView.deselectRow(at: selectedIndexPath, animated: true) // As of iOS 14.4 beta 1, this animation is broken (under some conditions). The row stays completely highlighted for period of time when it should be animating, then un-highlights instantly with no animation, which looks terrible.
				}
			}
		}
		
		if let selectedIndexPath = tableView.indexPathForSelectedRow {
			refreshCheckmarksOnAccentColorRows(selectedIndexPath: selectedIndexPath)
		} else {
			tableView.reloadData() // Should never run
		}
	}
	
}

// MARK: - Tip Jar Section

extension OptionsTVC {
	
	// MARK: Cells
	
	private func tipJarCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		switch PurchaseManager.shared.tipStatus {
		case .notYetFirstLoaded, .loading:
			let cell = tableView.dequeueReusableCell(
				withIdentifier: "Tip Loading",
				for: indexPath)
			return cell
		case .reload:
			return tipReloadCell(forRowAt: indexPath)
		case .ready:
			if shouldShowTemporaryThankYouMessage {
				return tipThankYouCell(forRowAt: indexPath)
			} else {
				return tipReadyCell(forRowAt: indexPath)
			}
		case .confirming:
			let cell = tableView.dequeueReusableCell(
				withIdentifier: "Tip Purchasing",
				for: indexPath)
			return cell
		}
	}
	
	private func tipReloadCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Tip Reload",
			for: indexPath)
				as? TipReloadCell
		else {
			return UITableViewCell()
		}
		
		cell.reloadLabel.textColor = view.window?.tintColor
		
		return cell
	}
	
	private func tipReadyCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		guard
			let cell = tableView.dequeueReusableCell(
				withIdentifier: "Tip Ready",
				for: indexPath)
				as? TipReadyCell,
			let tipProduct = PurchaseManager.shared.tipProduct,
			let tipPriceFormatter = PurchaseManager.shared.tipPriceFormatter
		else {
			return UITableViewCell()
		}
		
		cell.tipNameLabel.text = tipProduct.localizedTitle
		cell.tipNameLabel.textColor = view.window?.tintColor
		
		let localizedPriceString = tipPriceFormatter.string(from: tipProduct.price)
		cell.tipPriceLabel.text = localizedPriceString
		
		return cell
	}
	
	private func tipThankYouCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Tip Thank You",
			for: indexPath)
				as? TipThankYouCell
		else {
			return UITableViewCell()
		}
		
		let accentColor = AccentColor.savedPreferenceOrDefault()
		let heartEmoji = accentColor.heartEmoji
		let thankYouMessage =
			heartEmoji +
			LocalizedString.tipThankYouMessageWithPaddingSpaces +
			heartEmoji
		cell.thankYouLabel.text = thankYouMessage
		
		return cell
	}
	
	// MARK: Selecting
	
	private func didSelectTipJarRow(at indexPath: IndexPath) {
		switch PurchaseManager.shared.tipStatus {
		case .notYetFirstLoaded, .loading, .confirming: // Should never run
			break
		case .reload:
			reloadTipProduct()
		case .ready:
			beginleaveTip()
		}
	}
	
	private func reloadTipProduct() {
		PurchaseManager.shared.requestAllSKProducts()
		
		refreshTipJarRows()
	}
	
	private func beginleaveTip() {
		let tipProduct = PurchaseManager.shared.tipProduct
		PurchaseManager.shared.addToPaymentQueue(tipProduct)
		
		refreshTipJarRows()
	}
	
	// MARK: Events
	
	final func refreshTipJarRows() {
		let tipJarIndexPaths = tableView.indexPathsForRows(
			inSection: Section.tipJar.rawValue,
			firstRow: 0)
		tableView.reloadRows(at: tipJarIndexPaths, with: .fade)
	}
	
}
