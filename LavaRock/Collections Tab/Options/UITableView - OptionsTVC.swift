//
//  UITableView - OptionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-12-27.
//

import UIKit

extension OptionsTVC {
	
	private enum Section: Int, CaseIterable {
		case accentColor, tipJar
	}
	
	// MARK: - Numbers
	
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
	
	// MARK: - Headers and Footers
	
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
	
	// MARK: - Cells
	
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
		
		if rowColorEntry.userDefaultsKey == AccentColorManager.savedUserDefaultsKey() { // Don't use view.window.tintColor, because if Increase Contrast is enabled, it won't match any rowColorEntry.uiColor.
			cell.accessoryType = .checkmark
		} else {
			cell.accessoryType = .none
		}
		
		cell.accessibilityTraits.formUnion(.button)
		
		return cell
	}
	
	private func tipJarCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		switch tipStatus {
		case .notReady:
			let cell = tableView.dequeueReusableCell(withIdentifier: "Tip Loading", for: indexPath)
			return cell
		case .ready:
			return tipReadyCell()
		case .purchasing:
			let cell = tableView.dequeueReusableCell(withIdentifier: "Tip Purchasing", for: indexPath)
			return cell
		case .thankYou:
			return tipThankYouCell()
		}
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
		
		let heartEmoji = AccentColorManager.heartEmojiMatchingSavedAccentColor()
		let thankYouMessage =
			heartEmoji +
			LocalizedString.tipThankYouMessageWithPaddingSpaces +
			heartEmoji
		cell.thankYouLabel.text = thankYouMessage
		
		return cell
	}
	
	// MARK: - Selecting
	
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
	
	private func canSelectTipJarRow() -> Bool {
		switch tipStatus {
		case .notReady:
			return false
		case .ready:
			return true
		case .purchasing:
			return false
		case .thankYou:
			return false
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
//		dismiss(animated: true, completion: nil)
	}
	
	private func didSelectTipJarRow(at indexPath: IndexPath) {
		switch tipStatus {
		case .notReady:
			tableView.deselectRow(at: indexPath, animated: true)
		case .ready:
			beginleaveTip()
		case .purchasing:
			break
		case .thankYou:
			tableView.deselectRow(at: indexPath, animated: true)
		}
	}
	
	private func beginleaveTip() {
		tipStatus = .purchasing
		refreshTipJarRows()
		
		let tipProduct = PurchaseManager.shared.tipProduct
		PurchaseManager.shared.addToPaymentQueue(tipProduct)
	}
	
	// MARK: - Events
	
	final func deselectTipJarRows(animated: Bool) {
		let indexPaths = tipJarIndexPaths()
		tableView.deselectRows(at: indexPaths, animated: animated)
	}
	
	final func refreshTipJarRows() {
		let indexPathsToRefresh = tipJarIndexPaths()
		let indexPathsToRefreshThatWereSelected = indexPathsToRefresh.filter { indexPath in
			tableView.cellForRow(at: indexPath)?.isSelected ?? false
		}
		
		tableView.reloadRows(at: indexPathsToRefresh, with: .fade)
		tableView.selectRows(at: indexPathsToRefreshThatWereSelected, animated: false)
	}
	
	private func tipJarIndexPaths() -> [IndexPath] {
		let tipJarIndexPaths = tableView.indexPathsForRowsIn(
			section: Section.tipJar.rawValue,
			firstRow: 0)
		return tipJarIndexPaths
	}
	
	@IBAction func doneWithOptionsSheet(_ sender: UIBarButtonItem) {
		dismiss(animated: true, completion: nil)
	}
	
}
