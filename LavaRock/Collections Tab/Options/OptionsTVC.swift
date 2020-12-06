//
//  OptionsTVC.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit

final class OptionsTVC: UITableViewController {
	
	// MARK: - Table View Data Source
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return AccentColorManager.colorEntries.count
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
		case 0:
			return LocalizedString.accentColor
		default:
			return nil
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
		
		if rowColorEntry.userDefaultsKey == AccentColorManager.savedAccentColorKey() { // Don't use view.window.tintColor, because if Increase Contrast is enabled, it won't match any rowColorEntry.uiColor.
			cell.accessoryType = .checkmark
		} else {
			cell.accessoryType = .none
		}
		
		cell.accessibilityTraits.formUnion(.button)
		
		return cell
	}
	
	// MARK: - Events
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
		dismiss(animated: true, completion: nil)
	}
	
	@IBAction func doneWithOptionsSheet(_ sender: UIBarButtonItem) {
		dismiss(animated: true, completion: nil)
	}
	
}
