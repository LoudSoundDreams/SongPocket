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
		return AccentColorManager.accentColorTuples.count
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
		case 0:
			return "Accent Color"
		default:
			return nil
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard
			let rowColorName = AccentColorManager.colorName(forIndex: indexPath.row),
			let rowUIColor = AccentColorManager.uiColor(forIndex: indexPath.row)
		else {
			return UITableViewCell()
		}
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "Color Cell", for: indexPath)
		
		if #available(iOS 14.0, *) {
			var configuration = cell.defaultContentConfiguration()
			configuration.text = rowColorName
			configuration.textProperties.color = rowUIColor
			
			cell.contentConfiguration = configuration
			
		} else { // iOS 13 and earlier
			cell.textLabel?.text = rowColorName
			cell.textLabel?.textColor = rowUIColor
			
		}
		
		if rowUIColor == view.window?.tintColor { // Check against the actual current tintColor here, not the saved accent color name in UserDefaults. This will help you notice if the saved accent color name doesn't match any of the row colors, because in that case, none of the rows will have a checkmark.
			cell.accessoryType = .checkmark
		} else {
			cell.accessoryType = .none
		}
		
		return cell
	}
	
	// MARK: - Events
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let rowColorName = AccentColorManager.colorName(forIndex: indexPath.row) else {
			tableView.deselectRow(at: indexPath, animated: true)
			return
		}
		
		AccentColorManager.setAccentColor(rowColorName, in: view.window)
		tableView.reloadData()
		dismiss(animated: true, completion: nil)
	}
	
	@IBAction func dismissOptionsSheet(_ sender: UIBarButtonItem) {
		dismiss(animated: true, completion: nil)
	}
	
}
