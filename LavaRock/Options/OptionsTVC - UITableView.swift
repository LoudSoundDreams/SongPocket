//
//  OptionsTVC - UITableView.swift
//  LavaRock
//
//  Created by h on 2020-12-27.
//

import UIKit
import SwiftUI

extension OptionsTVC {
	private enum Section: Int, CaseIterable {
		case theme
		case avatar
		case tipJar
	}
	
	static let indexPathsOfLightingRows = [
		IndexPath(row: 0, section: Section.theme.rawValue),
	]
	
	func freshenTipJarRows() {
		let tipJarIndexPaths = tableView.indexPathsForRows(
			inSection: Section.tipJar.rawValue,
			firstRow: 0)
		tableView.reloadRows(at: tipJarIndexPaths, with: .fade) // Don’t use `reloadSections`, because that makes the header and footer fade out and back in.
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
		case .theme:
			return Self.indexPathsOfLightingRows.count + AccentColor.allCases.count
		case .avatar:
			return 1
		case .tipJar:
			return 1
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
		case .theme:
			return LRString.theme
		case .avatar:
			return LRString.avatar
		case .tipJar:
			return LRString.tipJar
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
		case .theme:
			return nil
		case .avatar:
			return nil
		case .tipJar:
			return LRString.tipJarFooter
		}
	}
	
	// MARK: Cells
	
	override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		guard let sectionCase = Section(rawValue: indexPath.section) else { return UITableViewCell() }
		switch sectionCase {
		case .theme:
			if Self.indexPathsOfLightingRows.contains(indexPath) {
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
			} else {
				return accentColorCell(forRowAt: indexPath)
			}
		case .avatar:
			// The cell in the storyboard is completely default except for the reuse identifier.
			let cell = tableView.dequeueReusableCell(
				withIdentifier: "Avatar",
				for: indexPath)
			
			cell.selectionStyle = .none
			cell.contentConfiguration = UIHostingConfiguration {
				AvatarPicker()
			}
			
			return cell
			
		case .tipJar:
			return tipJarCell(forRowAt: indexPath)
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
		case .theme:
			if Self.indexPathsOfLightingRows.contains(indexPath) {
				return nil
			} else {
				return indexPath
			}
		case .avatar:
			return nil
		case .tipJar:
			return indexPath
		}
	}
	
	override func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		guard let sectionCase = Section(rawValue: indexPath.section) else { return }
		switch sectionCase {
		case .theme:
			if Self.indexPathsOfLightingRows.contains(indexPath) {
				// Should never run
				tableView.deselectRow(at: indexPath, animated: true)
			} else {
				didSelectAccentColorRow(at: indexPath)
			}
		case .avatar: // Should never run
			tableView.deselectRow(at: indexPath, animated: true)
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
		cell.representee = accentColor
		return cell
	}
	
	private func didSelectAccentColorRow(at indexPath: IndexPath) {
		let indexOfAccentColor = indexPath.row - Self.indexPathsOfLightingRows.count
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
