//
//  OptionsTableViewController.swift
//  LavaRock
//
//  Created by h on 2020-07-29.
//

import UIKit

class OptionsTableViewController: UITableViewController {
	
	// MARK: Data Source
	
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
		let rowColorName = AccentColorManager.accentColorTuples[indexPath.row].0
		let rowUIColor = AccentColorManager.accentColorTuples[indexPath.row].1
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "Color Cell", for: indexPath)
		
		if rowUIColor == view.window?.tintColor {
			cell.accessoryType = .checkmark
		} else {
			cell.accessoryType = .none
		}
		
		if #available(iOS 14.0, *) {
			var configuration = cell.defaultContentConfiguration()
			configuration.text = rowColorName
			configuration.textProperties.color = rowUIColor
			
			cell.contentConfiguration = configuration
			
		} else { // iOS 13 and earlier
			cell.textLabel?.text = rowColorName
			cell.textLabel?.textColor = rowUIColor
			
		}
		
		return cell
	}
	
	// MARK: Events
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let rowColorName = AccentColorManager.accentColorTuples[indexPath.row].0
		let rowUIColor = AccentColorManager.accentColorTuples[indexPath.row].1
		
		view.window?.tintColor = rowUIColor
		UserDefaults.standard.set(rowColorName, forKey: "accentColorName")
		tableView.reloadData()
	}
	
	@IBAction func dismissOptionsSheet(_ sender: UIBarButtonItem) {
		dismiss(animated: true, completion: nil)
	}
	
}
