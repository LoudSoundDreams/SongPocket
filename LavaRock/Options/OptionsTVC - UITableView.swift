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
	
	static let indexPathsOfLightingRows = [
		IndexPath(row: 0, section: Section.theme.rawValue),
	]
	
	final func freshenTipJarRows() {
		let tipJarIndexPaths = tableView.indexPathsForRows(
			in: SectionIndex(Section.tipJar.rawValue),
			first: RowIndex(0))
		tableView.reloadRows(at: tipJarIndexPaths, with: .fade) // Don’t use `reloadSections`, because that makes the header and footer fade out and back in.
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
			return Self.indexPathsOfLightingRows.count + AccentColor.allCases.count
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
			if Self.indexPathsOfLightingRows.contains(indexPath) {
				return tableView.dequeueReusableCell(
					withIdentifier: "Lighting",
					for: indexPath) as? LightingCell ?? UITableViewCell()
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
			if Self.indexPathsOfLightingRows.contains(indexPath) {
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
			if Self.indexPathsOfLightingRows.contains(indexPath) {
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
		let indexOfAccentColor = indexPath.row - Self.indexPathsOfLightingRows.count
		let accentColor = AccentColor.allCases[indexOfAccentColor]
		
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Accent Color",
			for: indexPath) as? AccentColorCell
		else { return UITableViewCell() }
		cell.accentColor = accentColor
		return cell
	}
	
	private func didSelectAccentColorRow(at indexPath: IndexPath) {
		let indexOfAccentColor = indexPath.row - Self.indexPathsOfLightingRows.count
		let selected = AccentColor.allCases[indexOfAccentColor]

		Theme.shared.accentColor = selected
		
		view.window?.tintColor = selected.uiColor
		// As of build 455, setting `Theme.shared.accentColor` triggers `updateUIViewController`, which sets the window’s `tintColor`, but not until later.
		// You must set the window’s `tintColor` before deselecting the row. Only doing so after breaks the animation for deselecting the row.
		// Also, you must set the window’s `tintColor` after setting `AccentColor.savedPreference`, so that instances that override `tintColorDidChange` get its new value.
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	// MARK: - Tip Jar Section
	
	private func tipJarCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		switch TipJarViewModel.shared.status {
		case .notYetFirstLoaded, .loading:
			return tableView.dequeueReusableCell(
				withIdentifier: "Tip Loading",
				for: indexPath) as? TipLoadingCell ?? UITableViewCell()
		case .reload:
			return tableView.dequeueReusableCell(
				withIdentifier: "Tip Reload",
				for: indexPath) as? TipReloadCell ?? UITableViewCell()
		case .ready:
			return tableView.dequeueReusableCell(
				withIdentifier: "Tip Ready",
				for: indexPath) as? TipReadyCell ?? UITableViewCell()
		case .confirming:
			return tableView.dequeueReusableCell(
				withIdentifier: "Tip Confirming",
				for: indexPath) as? TipConfirmingCell ?? UITableViewCell()
		case .thankYou:
			return tableView.dequeueReusableCell(
				withIdentifier: "Tip Thank You",
				for: indexPath) as? TipThankYouCell ?? UITableViewCell()
		}
	}
	
	private func didSelectTipJarRow(at indexPath: IndexPath) {
		switch TipJarViewModel.shared.status {
		case
				.notYetFirstLoaded,
				.loading,
				.confirming,
				.thankYou:
			// Should never run
			break
		case .reload:
			PurchaseManager.shared.requestTipProduct()
		case .ready:
			PurchaseManager.shared.buyTip()
		}
	}
}
