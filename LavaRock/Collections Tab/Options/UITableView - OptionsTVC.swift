//
//  UITableView - OptionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-12-27.
//

import UIKit

// MARK: - All Sections

extension OptionsTVC {
	
	private enum Section: Int, CaseIterable {
		case accentColor, tipJar
	}
	
	// MARK: Numbers
	
	final override func numberOfSections(in tableView: UITableView) -> Int {
		return Section.allCases.count
	}
	
	final override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case Section.accentColor.rawValue:
			return AccentColorManager.colorEntries.count
		case Section.tipJar.rawValue:
			return 1
		default:
			return 0
		}
	}
	
	// MARK: Headers and Footers
	
	final override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
		case Section.accentColor.rawValue:
			return LocalizedString.accentColor
		case Section.tipJar.rawValue:
			return LocalizedString.tipJar
		default:
			return nil
		}
	}
	
	final override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		switch section {
		case Section.tipJar.rawValue:
			return LocalizedString.tipJarFooter
		default:
			return nil
		}
	}
	
	// MARK: Cells
	
	final override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch indexPath.section {
		case Section.accentColor.rawValue:
			return accentColorCell(forRowAt: indexPath)
		case Section.tipJar.rawValue:
			return tipJarCell(forRowAt: indexPath)
		default:
			return UITableViewCell()
		}
	}
	
	final override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if
			PurchaseManager.shared.tipStatus == .confirming,
			indexPath.section == Section.tipJar.rawValue
		{
			cell.isSelected = true
		}
	}
	
	// MARK: Selecting
	
	final override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
		switch indexPath.section {
		case Section.accentColor.rawValue:
			return indexPath
		case Section.tipJar.rawValue:
			return canSelectTipJarRow() ? indexPath : nil
		default:
			return indexPath
		}
	}
	
	final override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		switch indexPath.section {
		case Section.accentColor.rawValue:
			didSelectAccentColorRow(at: indexPath)
		case Section.tipJar.rawValue:
			didSelectTipJarRow(at: indexPath)
		default:
			break
		}
	}
	
	// MARK: Events
	
	@IBAction func doneWithOptionsSheet(_ sender: UIBarButtonItem) {
		dismiss(animated: true, completion: nil)
	}
	
}

// MARK: - Accent Color Section

extension OptionsTVC {
	
	// MARK: Cells
	
	private func accentColorCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		let index = indexPath.row
		guard
			index >= 0,
			index <= AccentColorManager.colorEntries.count - 1
		else {
			return UITableViewCell()
		}
		let rowColorEntry = AccentColorManager.colorEntries[index]
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "Color Cell", for: indexPath)
		
		if #available(iOS 14.0, *) {
			var configuration = cell.defaultContentConfiguration()
			configuration.text = rowColorEntry.displayName
			configuration.textProperties.color = rowColorEntry.uiColor
			cell.contentConfiguration = configuration
		} else { // iOS 13 and earlier
			cell.textLabel?.text = rowColorEntry.displayName
			cell.textLabel?.textColor = rowColorEntry.uiColor
		}
		
		if rowColorEntry.userDefaultsValue == AccentColorManager.savedUserDefaultsValue() { // Don't use view.window.tintColor, because if Increase Contrast is enabled, it won't match any rowColorEntry.uiColor.
			cell.accessoryType = .checkmark
		} else {
			cell.accessoryType = .none
		}
		
		cell.accessibilityTraits.formUnion(.button)
		
		return cell
	}
	
	// MARK: Selecting
	
	private func didSelectAccentColorRow(at indexPath: IndexPath) {
		let index = indexPath.row
		guard
			index >= 0,
			index <= AccentColorManager.colorEntries.count - 1
		else {
			tableView.deselectRow(at: indexPath, animated: true)
			return
		}
		let selectedColorEntry = AccentColorManager.colorEntries[index]
		
		AccentColorManager.setAccentColor(selectedColorEntry, in: view.window)
		tableView.reloadData()
	}
	
}

// MARK: - Tip Jar Section

extension OptionsTVC {
	
	// MARK: Cells
	
	private func tipJarCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		switch PurchaseManager.shared.tipStatus {
		case .loading:
			let cell = tableView.dequeueReusableCell(withIdentifier: "Tip Loading", for: indexPath)
			return cell
		case .reload:
			return tipReloadCell()
		case .ready:
			if shouldShowTemporaryThankYouMessage {
				return tipThankYouCell()
			} else {
				return tipReadyCell()
			}
		case .confirming:
			let cell = tableView.dequeueReusableCell(withIdentifier: "Tip Purchasing", for: indexPath)
			return cell
		}
	}
	
	private func tipReloadCell() -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: "Tip Reload") as? TipReloadCell else {
			return UITableViewCell()
		}
		
		cell.reloadLabel.textColor = view.window?.tintColor
		
		return cell
	}
	
	private func tipReadyCell() -> UITableViewCell {
		guard
			let cell = tableView.dequeueReusableCell(withIdentifier: "Tip Ready") as? TipReadyCell,
			let tipProduct = PurchaseManager.shared.tipProduct,
			let priceFormatter = PurchaseManager.shared.priceFormatter
		else {
			return UITableViewCell()
		}
		
		cell.tipNameLabel.text = tipProduct.localizedTitle
		cell.tipNameLabel.textColor = view.window?.tintColor
		
		let localizedPriceString = priceFormatter.string(from: tipProduct.price)
		cell.tipPriceLabel.text = localizedPriceString
		
		return cell
	}
	
	private func tipThankYouCell() -> UITableViewCell {
		guard
			let cell = tableView.dequeueReusableCell(withIdentifier: "Tip Thank You") as? TipThankYouCell
		else {
			return UITableViewCell()
		}
		
		let savedColorEntry = AccentColorManager.savedOrDefaultColorEntry()
		let heartEmoji = savedColorEntry.heartEmoji
		let thankYouMessage =
			heartEmoji +
			LocalizedString.tipThankYouMessageWithPaddingSpaces +
			heartEmoji
		cell.thankYouLabel.text = thankYouMessage
		
		return cell
	}
	
	// MARK: Selecting
	
	private func canSelectTipJarRow() -> Bool {
		switch PurchaseManager.shared.tipStatus {
		case .loading, .confirming:
			return false
		case .reload:
			return true
		case .ready:
			return !shouldShowTemporaryThankYouMessage
		}
	}
	
	private func didSelectTipJarRow(at indexPath: IndexPath) {
		switch PurchaseManager.shared.tipStatus {
		case .loading, .confirming: // Should never run
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
		let tipJarIndexPaths = self.tableView.indexPathsForRowsIn(
			section: Section.tipJar.rawValue,
			firstRow: 0)
		self.tableView.reloadRows(at: tipJarIndexPaths, with: .fade)
	}
	
}
