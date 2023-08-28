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
		
		title = LRString.options
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
					ContactRow()
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
					TipLoadingRow()
						.alignmentGuide_separatorTrailing()
				}
				return cell
			case .reload:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Tip Reload", for: indexPath)
				cell.contentConfiguration = UIHostingConfiguration {
					TipReloadRow()
						.alignmentGuide_separatorTrailing()
				}
				return cell
			case .ready:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Tip Ready", for: indexPath)
				cell.contentConfiguration = UIHostingConfiguration {
					TipReadyRow()
						.alignmentGuide_separatorTrailing()
				}
				return cell
			case .confirming:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Tip Confirming", for: indexPath)
				cell.selectionStyle = .none
				cell.contentConfiguration = UIHostingConfiguration {
					TipConfirmingRow()
						.alignmentGuide_separatorTrailing()
				}
				return cell
			case .thankYou:
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Tip Thank You", for: indexPath)
				cell.selectionStyle = .none
				cell.contentConfiguration = UIHostingConfiguration {
					TipThankYouRow()
						.alignmentGuide_separatorTrailing()
				}
				return cell
		}
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
