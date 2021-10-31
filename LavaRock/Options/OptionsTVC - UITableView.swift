//
//  OptionsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-12-27.
//

import UIKit

extension OptionsTVC {
	
	private enum Section: Int, CaseIterable {
		case accentColor
		case tipJar
	}
	
	final func refreshTipJarRows() {
		tableView.reloadSections([Section.tipJar.rawValue], with: .fade)
	}
	
	// MARK: - All Sections
	
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
	
	// MARK: - Accent Color Section
	
	// MARK: Cells
	
	private func accentColorCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		let indexOfAccentColor = indexPath.row
		let accentColor = AccentColor.all[indexOfAccentColor]
		
		// Make, configure, and return the cell.
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Accent Color",
			for: indexPath) as? AccentColorCell
		else {
			return UITableViewCell()
		}
		cell.accentColor = accentColor
		return cell
	}
	
	// MARK: Selecting
	
	private func didSelectAccentColorRow(at indexPath: IndexPath) {
		// Set the new accent color.
		let indexOfAccentColor = indexPath.row
		let selectedAccentColor = AccentColor.all[indexOfAccentColor]
		selectedAccentColor.saveAsPreference() // Do this before calling `AccentColor.set`, so that instances that override `tintColorDidChange` can get the new value for `AccentColor.savedPreference`.
		if let window = view.window {
			selectedAccentColor.set(in: window)
		}
		
		// Refresh the UI.
		tableView.deselectRow(at: indexPath, animated: true)
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
		case
				.notYetFirstLoaded,
				.loading,
				.confirming:
			// Should never run
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
	
}
