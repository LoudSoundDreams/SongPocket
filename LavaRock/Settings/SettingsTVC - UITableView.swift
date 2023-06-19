//
//  SettingsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-12-27.
//

import UIKit
import SwiftUI

extension SettingsTVC {
	private enum Section: Int, CaseIterable {
		case appearance
		case support
	}
	private static let nonselectableAppearanceRows: [Int] = [0, 6]
	private static let tipJarRow = 1
	
	func freshenTipJarRows() {
		let tipJarIndexPath = IndexPath(
			row: Self.tipJarRow,
			section: Section.support.rawValue)
		tableView.reloadRows(at: [tipJarIndexPath], with: .fade) // Don’t use `reloadSections`, because that makes the header and footer fade out and back in.
	}
	
	// MARK: - All Sections
	
	// MARK: Numbers
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return Section.allCases.count
	}
	
	override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		guard let sectionCase = Section(rawValue: section) else {
			return 0
		}
		switch sectionCase {
			case .appearance:
				return AccentColor.allCases.count + Self.nonselectableAppearanceRows.count
			case .support:
				return 2
		}
	}
	
	// MARK: Headers and Footers
	
	override func tableView(
		_ tableView: UITableView,
		titleForHeaderInSection section: Int
	) -> String? {
		guard let sectionCase = Section(rawValue: section) else {
			return nil
		}
		switch sectionCase {
			case .appearance:
				return LRString.appearance
			case .support:
				return LRString.support
		}
	}
	
	override func tableView(
		_ tableView: UITableView,
		titleForFooterInSection section: Int
	) -> String? {
		guard let sectionCase = Section(rawValue: section) else {
			return nil
		}
		switch sectionCase {
			case .appearance:
				return nil
			case .support:
				return LRString.supportFooter
		}
	}
	
	// MARK: Cells
	
	override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		guard let sectionCase = Section(rawValue: indexPath.section) else { return UITableViewCell() }
		switch sectionCase {
			case .appearance:
				return appearanceCell(forRowAt: indexPath)
			case .support:
				return supportCell(forRowAt: indexPath)
		}
	}
	private func appearanceCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		let _ = Self.nonselectableAppearanceRows
		switch indexPath.row {
			case 0:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(
					withIdentifier: "Lighting",
					for: indexPath)
				
				cell.selectionStyle = .none
				cell.contentConfiguration = UIHostingConfiguration {
					LightingPicker()
						.alignmentGuide(.listRowSeparatorLeading) { viewDimensions in
							viewDimensions[.leading]
						}
						.alignmentGuide(.listRowSeparatorTrailing) { viewDimensions in
							viewDimensions[.trailing]
						}
				}
				
				return cell
				
			case 6:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(
					withIdentifier: "Avatar",
					for: indexPath)
				
				cell.selectionStyle = .none
				cell.contentConfiguration = UIHostingConfiguration {
					AvatarPicker()
				}
				
				return cell
				
			default:
				return accentColorCell(forRowAt: indexPath)
		}
	}
	private func supportCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		switch indexPath.row {
			case Self.tipJarRow:
				return tipJarCell(forRowAt: indexPath)
			default:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(
					withIdentifier: "Contact",
					for: indexPath)
				
				cell.selectedBackgroundView_add_tint()
				cell.contentConfiguration = UIHostingConfiguration {
					LabeledContent {
						Text(verbatim: "linus@songpocket.app")
					} label: {
						Text(LRString.contact)
							.foregroundStyle(Color.accentColor)
					}
				}
				
				return cell
		}
	}
	
	// MARK: Selecting
	
	override func tableView(
		_ tableView: UITableView,
		willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		guard let sectionCase = Section(rawValue: indexPath.section) else {
			return nil
		}
		switch sectionCase {
			case .appearance:
				if Self.nonselectableAppearanceRows.contains(indexPath.row) {
					return nil
				} else {
					return indexPath
				}
			case .support:
				return indexPath
		}
	}
	
	override func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		guard let sectionCase = Section(rawValue: indexPath.section) else { return }
		switch sectionCase {
			case .appearance:
				guard !Self.nonselectableAppearanceRows.contains(indexPath.row) else {
					// Should never run
					tableView.deselectRow(at: indexPath, animated: true)
					return
				}
				didSelectAccentColorRow(at: indexPath)
			case .support:
				switch indexPath.row {
					case Self.tipJarRow:
						didSelectTipJarRow(at: indexPath)
					default:
						let mailtoLink = URL(string: "mailto:linus@songpocket.app?subject=Songpocket%20Feedback")!
						UIApplication.shared.open(mailtoLink)
						
						tableView.deselectRow(at: indexPath, animated: true)
				}
		}
	}
	
	// MARK: - Accent Color Section
	
	private func accentColorCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		let _ = Self.nonselectableAppearanceRows
		let indexOfAccentColor = indexPath.row - 1
		let accentColor = AccentColor.allCases[indexOfAccentColor]
		
		guard let cell = tableView.dequeueReusableCell(
			withIdentifier: "Accent Color",
			for: indexPath) as? AccentColorCell
		else { return UITableViewCell() }
		cell.representee = accentColor
		return cell
	}
	
	private func didSelectAccentColorRow(at indexPath: IndexPath) {
		let _ = Self.nonselectableAppearanceRows
		let indexOfAccentColor = indexPath.row - 1
		let selected = AccentColor.allCases[indexOfAccentColor]
		
		Theme.shared.accentColor = selected
		view.window?.tintColor = selected.uiColor
		tableView.deselectRow(at: indexPath, animated: true) // Do this last, or the animation will break.
	}
	
	// MARK: - Tip Jar Section
	
	private func tipJarCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		switch TipJarViewModel.shared.status {
			case .notYetFirstLoaded, .loading:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(
					withIdentifier: "Tip Loading",
					for: indexPath)
				
				cell.isUserInteractionEnabled = false
				cell.contentConfiguration = UIHostingConfiguration {
					Text(LRString.loadingEllipsis)
						.foregroundColor(.secondary)
				}
				
				return cell
				
			case .reload:
				return tableView.dequeueReusableCell(
					withIdentifier: "Tip Reload",
					for: indexPath) as? TipReloadCell ?? UITableViewCell()
			case .ready:
				return tableView.dequeueReusableCell(
					withIdentifier: "Tip Ready",
					for: indexPath) as? TipReadyCell ?? UITableViewCell()
			case .confirming:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(
					withIdentifier: "Tip Confirming",
					for: indexPath)
				
				cell.isUserInteractionEnabled = false
				cell.contentConfiguration = UIHostingConfiguration {
					Text(LRString.confirmingEllipsis)
						.foregroundColor(.secondary)
				}
				
				return cell
				
			case .thankYou:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(
					withIdentifier: "Tip Thank You",
					for: indexPath)
				
				cell.isUserInteractionEnabled = false
				cell.contentConfiguration = UIHostingConfiguration {
					TipThankYouView()
				}
				
				return cell
		}
	}
	
	private struct TipThankYouView: View {
		@ObservedObject private var theme: Theme = .shared
		
		var body: some View {
			Text(theme.accentColor.tipThankYouMessage())
				.foregroundColor(.secondary)
				.multilineTextAlignment(.center)
				.frame(maxWidth: .infinity)
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
