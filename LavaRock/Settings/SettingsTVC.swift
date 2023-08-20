//
//  SettingsTVC.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit
import SwiftUI

final class SettingsTVC: UITableViewController {
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		TipJarViewModel.shared.ui = self
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if TipJarViewModel.shared.status == .notYetFirstLoaded {
			PurchaseManager.shared.requestTipProduct()
		}
		
		navigationItem.leftBarButtonItem = UIBarButtonItem(
			systemItem: .close,
			primaryAction: UIAction { [weak self] action in
				self?.dismiss(animated: true)
			}
		)
		
		title = LRString.about
	}
}
extension SettingsTVC {
	private static let tipJarRow = 0
	
	override func tableView(
		_ tableView: UITableView,
		numberOfRowsInSection section: Int
	) -> Int {
		return 2
	}
	
	override func tableView(
		_ tableView: UITableView,
		cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		switch indexPath.row {
			case Self.tipJarRow:
				return tipJarCell(forRowAt: indexPath)
			default:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Contact", for: indexPath)
				cell.contentConfiguration = UIHostingConfiguration {
					LabeledContent {
						Text(verbatim: "linus@songpocket.app")
					} label: {
						Text(LRString.sayHi)
							.foregroundStyle(Color.accentColor)
					}
				}
				return cell
		}
	}
	
	override func tableView(
		_ tableView: UITableView,
		willSelectRowAt indexPath: IndexPath
	) -> IndexPath? {
		switch indexPath.row {
			case Self.tipJarRow:
				switch TipJarViewModel.shared.status {
					case .notYetFirstLoaded, .loading, .confirming, .thankYou:
						return nil
					case .reload, .ready:
						return indexPath
				}
			default:
				return indexPath
		}
	}
	
	override func tableView(
		_ tableView: UITableView,
		didSelectRowAt indexPath: IndexPath
	) {
		switch indexPath.row {
			case Self.tipJarRow:
				switch TipJarViewModel.shared.status {
					case .notYetFirstLoaded, .loading, .confirming, .thankYou:
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
	
	private func tipJarCell(forRowAt indexPath: IndexPath) -> UITableViewCell {
		switch TipJarViewModel.shared.status {
			case .notYetFirstLoaded, .loading:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Tip Loading", for: indexPath)
				cell.selectionStyle = .none
				cell.contentConfiguration = UIHostingConfiguration {
					LabeledContent(LRString.leaveTip, value: LRString.loadingEllipsis)
						.foregroundStyle(.secondary) // Seems to not affect `LabeledContent`’s `value:` argument
						.alignmentGuide_separatorTrailing()
				}
				return cell
			case .reload:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Tip Reload", for: indexPath)
				cell.contentConfiguration = UIHostingConfiguration {
					LabeledContent {
						Text(LRString.reload)
					} label: {
						Text(LRString.leaveTip)
							.foregroundStyle(Color.accentColor)
					}
					.alignmentGuide_separatorTrailing()
					.accessibilityAddTraits(.isButton)
				}
				return cell
			case .ready:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Tip Ready", for: indexPath)
				cell.contentConfiguration = UIHostingConfiguration {
					LabeledContent {
						Text(PurchaseManager.shared.tipPrice ?? "")
					} label: {
						Text(LRString.leaveTip)
							.foregroundStyle(Color.accentColor)
					}
					.alignmentGuide_separatorTrailing()
					.accessibilityAddTraits(.isButton)
				}
				return cell
			case .confirming:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Tip Confirming", for: indexPath)
				cell.selectionStyle = .none
				cell.contentConfiguration = UIHostingConfiguration {
					LabeledContent(LRString.leaveTip, value: LRString.confirmingEllipsis)
						.foregroundStyle(.secondary)
						.alignmentGuide_separatorTrailing()
				}
				return cell
			case .thankYou:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Tip Thank You", for: indexPath)
				cell.selectionStyle = .none
				cell.contentConfiguration = UIHostingConfiguration {
					TipThankYouView()
						.alignmentGuide_separatorTrailing()
				}
				return cell
		}
	}
}
struct TipThankYouView: View {
	@ObservedObject private var theme: Theme = .shared
	var body: some View {
		LabeledContent(
			LRString.leaveTip,
			value: LRString.thankYouExclamationMark
			+ " "
			+ theme.accentColor.heartEmoji
		)
		.foregroundStyle(.secondary)
	}
}
extension SettingsTVC: TipJarUI {
	func statusBecameLoading() {
		freshenTipJarRows()
	}
	func statusBecameReload() {
		freshenTipJarRows()
	}
	func statusBecameReady() {
		freshenTipJarRows()
	}
	func statusBecameConfirming() {
		freshenTipJarRows()
	}
	func statusBecameThankYou() {
		freshenTipJarRows()
	}
	
	private func freshenTipJarRows() {
		tableView.reloadRows( // Don’t use `reloadSections`, because that makes the header and footer fade out and back in.
			at: [IndexPath(row: Self.tipJarRow, section: 0)],
			with: .fade)
	}
}
