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
	private static let nonselectableAppearanceRows: [Int] = [5]
	private static let tipJarRow = 0
	
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
			case 5:
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
				switch indexPath.row {
					case Self.tipJarRow:
						switch TipJarViewModel.shared.status {
							case
									.notYetFirstLoaded,
									.loading,
									.confirming,
									.thankYou:
								return nil
							case
									.reload,
									.ready:
								return indexPath
						}
					default:
						return indexPath
				}
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
		let indexOfAccentColor = indexPath.row
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
		let indexOfAccentColor = indexPath.row
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
				
				cell.selectionStyle = .none
				cell.contentConfiguration = UIHostingConfiguration {
					LabeledContent(LRString.tipJar, value: LRString.loadingEllipsis)
						.foregroundStyle(.secondary) // Seems to not affect `LabeledContent`’s `value:` argument
						.alignmentGuide(.listRowSeparatorTrailing) { viewDimensions in
							viewDimensions[.trailing]
						}
				}
				
				return cell
				
			case .reload:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(
					withIdentifier: "Tip Reload",
					for: indexPath)
				
				cell.contentConfiguration = UIHostingConfiguration {
					LabeledContent {
						Text(LRString.reload)
					} label: {
						Text(LRString.tipJar)
							.foregroundStyle(Color.accentColor)
					}
					.alignmentGuide(.listRowSeparatorTrailing) { viewDimensions in
						viewDimensions[.trailing]
					}
					.accessibilityAddTraits(.isButton)
				}
				
				return cell
				
			case .ready:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(
					withIdentifier: "Tip Ready",
					for: indexPath)
				
				cell.contentConfiguration = UIHostingConfiguration {
					LabeledContent {
						Text(PurchaseManager.shared.tipPrice ?? "")
					} label: {
						Text(LRString.tipJar)
							.foregroundStyle(Color.accentColor)
					}
					.alignmentGuide(.listRowSeparatorTrailing) { viewDimensions in
						viewDimensions[.trailing]
					}
					.accessibilityAddTraits(.isButton)
				}
				
				return cell
				
			case .confirming:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(
					withIdentifier: "Tip Confirming",
					for: indexPath)
				
				cell.selectionStyle = .none
				cell.contentConfiguration = UIHostingConfiguration {
					LabeledContent(LRString.tipJar, value: LRString.confirmingEllipsis)
						.foregroundStyle(.secondary)
						.alignmentGuide(.listRowSeparatorTrailing) { viewDimensions in
							viewDimensions[.trailing]
						}
				}
				
				return cell
				
			case .thankYou:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(
					withIdentifier: "Tip Thank You",
					for: indexPath)
				
				cell.selectionStyle = .none
				cell.contentConfiguration = UIHostingConfiguration {
					TipThankYouView()
						.alignmentGuide(.listRowSeparatorTrailing) { viewDimensions in
							viewDimensions[.trailing]
						}
				}
				
				return cell
		}
	}
}
struct TipThankYouView: View {
	@ObservedObject private var theme: Theme = .shared
	
	var body: some View {
		LabeledContent(
			LRString.tipJar,
			value: LRString.thankYouExclamationMark
			+ " "
			+ theme.accentColor.heartEmoji
		)
		.foregroundStyle(.secondary)
	}
}
