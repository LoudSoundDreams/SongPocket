//
//  OptionsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-12-27.
//

import UIKit

extension OptionsTVC {
	private enum Section: Int, CaseIterable {
		case theme
		case tipJar
	}
	
	static let indexPathsOfAppearanceRows = [
		IndexPath(row: 0, section: Section.theme.rawValue),
	]
	
	final func refreshTipJarRows() {
		let tipJarIndexPaths = tableView.indexPathsForRows(
			inSection: Section.tipJar.rawValue,
			firstRow: 0)
		tableView.reloadRows(at: tipJarIndexPaths, with: .fade) // Don't use `reloadSections`, because that makes the header and footer fade out and back in.
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
		case .theme:
			return Self.indexPathsOfAppearanceRows.count + AccentColor.all.count
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
		case .theme:
			return LocalizedString.theme
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
		case .theme:
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
		guard let sectionCase = Section(rawValue: indexPath.section) else { return UITableViewCell() }
		switch sectionCase {
		case .theme:
			if Self.indexPathsOfAppearanceRows.contains(indexPath) {
				return tableView.dequeueReusableCell(
					withIdentifier: "Appearance",
					for: indexPath) as? AppearanceCell ?? UITableViewCell()
			} else {
				return accentColorCell(forRowAt: indexPath)
			}
		case .tipJar:
			return tipJarCell(forRowAt: indexPath)
		}
	}
	
	// MARK: Selecting
	
	final override func tableView(
		_ tableView: UITableView,
		willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		guard let sectionCase = Section(rawValue: indexPath.section) else {
			return nil
		}
		switch sectionCase {
		case .theme:
			if Self.indexPathsOfAppearanceRows.contains(indexPath) {
				return nil
			} else {
				return indexPath
			}
		case .tipJar:
			return indexPath
		}
	}
	
	final override func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		guard let sectionCase = Section(rawValue: indexPath.section) else { return }
		switch sectionCase {
		case .theme:
			if Self.indexPathsOfAppearanceRows.contains(indexPath) {
				tableView.deselectRow(at: indexPath, animated: true)
			} else {
				didSelectAccentColorRow(at: indexPath)
			}
		case .tipJar:
			didSelectTipJarRow(at: indexPath)
		}
	}
	
	// MARK: - Accent Color Section
	
	private func accentColorCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		let indexOfAccentColor = indexPath.row - Self.indexPathsOfAppearanceRows.count
		let accentColor = AccentColor.all[indexOfAccentColor]
		
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Accent Color",
			for: indexPath) as? AccentColorCell
		else { return UITableViewCell() }
		cell.accentColor = accentColor
		return cell
	}
	
	private func didSelectAccentColorRow(at indexPath: IndexPath) {
		// Set the new accent color.
		let indexOfAccentColor = indexPath.row - Self.indexPathsOfAppearanceRows.count
		let selected = AccentColor.all[indexOfAccentColor]
		selected.saveAsPreference() // Do this before calling `AccentColor.set`, so that instances that override `tintColorDidChange` can get the new value for `AccentColor.savedPreference`.
		view.window?.tintColor = selected.uiColor
		
		// Refresh the UI.
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	// MARK: - Tip Jar Section
	
	private func tipJarCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		switch PurchaseManager.shared.tipStatus {
		case .notYetFirstLoaded, .loading:
			return tableView.dequeueReusableCell(
				withIdentifier: "Tip Loading",
				for: indexPath) as? TipLoadingCell ?? UITableViewCell()
		case .reload:
			return tableView.dequeueReusableCell(
				withIdentifier: "Tip Reload",
				for: indexPath) as? TipReloadCell ?? UITableViewCell()
		case .ready:
			if tipJarIsShowingThankYou {
				return tableView.dequeueReusableCell(
					withIdentifier: "Tip Thank You",
					for: indexPath) as? TipThankYouCell ?? UITableViewCell()
			} else {
				return tableView.dequeueReusableCell(
					withIdentifier: "Tip Ready",
					for: indexPath) as? TipReadyCell ?? UITableViewCell()
			}
		case .confirming:
			return tableView.dequeueReusableCell(
				withIdentifier: "Tip Confirming",
				for: indexPath) as? TipConfirmingCell ?? UITableViewCell()
		}
	}
	
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
