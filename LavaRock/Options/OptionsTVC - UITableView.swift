//
//  OptionsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-12-27.
//

import UIKit

extension OptionsTVC {
	
	// MARK: - Types
	
	private enum OptionsSection: Int, CaseIterable {
		case accentColor
		case tipJar
	}
	
	// MARK: - Events
	
	@IBAction func doneWithOptionsSheet(_ sender: UIBarButtonItem) {
		dismiss(animated: true)
	}
	
	// MARK: - All Sections
	
	// MARK: Numbers
	
	final override func numberOfSections(in tableView: UITableView) -> Int {
		return OptionsSection.allCases.count
	}
	
	final override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		guard let sectionCase = OptionsSection(rawValue: section) else {
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
		guard let sectionCase = OptionsSection(rawValue: section) else {
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
		guard let sectionCase = OptionsSection(rawValue: section) else {
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
		guard let sectionCase = OptionsSection(rawValue: indexPath.section) else {
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
			indexPath.section == OptionsSection.tipJar.rawValue
		{
			cell.isSelected = true
		}
	}
	
	// MARK: Selecting
	
	final override func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		guard let sectionCase = OptionsSection(rawValue: indexPath.section) else { return }
		switch sectionCase {
		case .accentColor:
			didSelectAccentColorRow(at: indexPath)
		case .tipJar:
			didSelectTipJarRow(at: indexPath)
		}
	}
	
	// MARK: - Accent Color Section
	
	// MARK: Cells
	
	// The cell in the storyboard is completely default except for the reuse identifier.
	private func accentColorCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		let indexOfAccentColor = indexPath.row
		let accentColor = AccentColor.all[indexOfAccentColor]
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "Accent Color", for: indexPath)
		
		var configuration = UIListContentConfiguration.cell()
		configuration.text = accentColor.displayName
		configuration.textProperties.color = accentColor.uiColor
		cell.contentConfiguration = configuration
		
		if accentColor == AccentColor.savedPreference() { // Don't use view.window.tintColor, because if Increase Contrast is enabled, it won't match any rowAccentColor.uiColor.
			cell.accessoryType = .checkmark
		} else {
			cell.accessoryType = .none
		}
		
		cell.accessibilityTraits.formUnion(.button)
		
		return cell
	}
	
	// MARK: Selecting
	
	private func didSelectAccentColorRow(at indexPath: IndexPath) {
		// Set the new accent color.
		let indexOfAccentColor = indexPath.row
		let selectedAccentColor = AccentColor.all[indexOfAccentColor]
		selectedAccentColor.saveAsPreference() // Do this before calling `AccentColor.set`, so that instances that override `tintColorDidChange` will get the new value for `AccentColor.savedPreference`.
		if let window = view.window {
			selectedAccentColor.set(in: window)
		}
		
		// Refresh the UI.
		
		guard let selectedIndexPath = tableView.indexPathForSelectedRow else {
			// Should never run
			tableView.reloadData()
			return
		}
		
		
//		tableView.reloadData()
//		tableView.performBatchUpdates {
//			tableView.selectRow(at: selectedIndexPath, animated: false, scrollPosition: .none)
//		} completion: { _ in
//			self.tableView.deselectRow(at: selectedIndexPath, animated: true) // As of iOS 14.7 developer beta 2, this animation is broken (under some conditions). The row stays completely highlighted for the period of time when it should be animating, then un-highlights instantly with no animation, which looks terrible.
//		}
		
		
		// Move the checkmark to the selected accent color.
		let colorIndexPaths = tableView.indexPathsForRows(
			inSection: OptionsSection.accentColor.rawValue,
			firstRow: 0)
		colorIndexPaths.forEach { colorIndexPath in
			guard let colorCell = tableView.cellForRow(at: colorIndexPath) else {
				// Should never run
				tableView.reloadRows(at: [colorIndexPath], with: .none)
				return
			}
			
			if colorIndexPath == selectedIndexPath {
				colorCell.accessoryType = .checkmark
				tableView.deselectRow(at: selectedIndexPath, animated: true)
			} else {
//				tableView.reloadRows(at: [colorIndexPath], with: .none)
				colorCell.accessoryType = .none // Don't use reloadRows, because as of iOS 14.7 developer beta 2, that breaks tableView.deselectRow's animation.
			}
		}
	}
	
	// MARK: - Tip Jar Section
	
	// MARK: Cells
	
	private func tipJarCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		switch PurchaseManager.shared.tipStatus {
		case .notYetFirstLoaded, .loading:
			return tableView.dequeueReusableCell(withIdentifier: "Tip Loading", for: indexPath)
		case .reload:
			return tableView.dequeueReusableCell(
				withIdentifier: "Tip Reload",
				for: indexPath) as? TipReloadCell ?? UITableViewCell()
		case .ready:
			if isTipJarShowingThankYou {
				return tableView.dequeueReusableCell(
					withIdentifier: "Tip Thank You",
					for: indexPath) as? TipThankYouCell ?? UITableViewCell()
			} else {
				return tableView.dequeueReusableCell(
					withIdentifier: "Tip Ready",
					for: indexPath) as? TipReadyCell ?? UITableViewCell()
			}
		case .confirming:
			return tableView.dequeueReusableCell(withIdentifier: "Tip Confirming", for: indexPath)
		}
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
			inSection: OptionsSection.tipJar.rawValue,
			firstRow: 0)
		tableView.reloadRows(at: tipJarIndexPaths, with: .fade)
	}
	
}
