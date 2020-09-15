//
//  UITableViewDataSource - QueueTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-14.
//

import UIKit
import CoreData
import MediaPlayer

extension QueueTVC {
	
	// MARK: - Cells
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		refreshButtons()
		
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return noContentRowsAndSetTableViewPlaceholder()
		}
		
		let numberOfQueueEntries = QueueController.shared.entries.count
		if numberOfQueueEntries > 0 {
			tableView.backgroundColor = nil
			return numberOfQueueEntries + numberOfNonQueueEntryCells
		} else {
			return noContentRowsAndSetTableViewPlaceholder()
		}
	}
	
	private func noContentRowsAndSetTableViewPlaceholder() -> Int {
		if let noItemsView = tableView.dequeueReusableCell(withIdentifier: "No Items Cell") {
			tableView.backgroundView = noItemsView
		}
		return numberOfNonQueueEntryCells
	}
	
	/*
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
	let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
	
	// Configure the cell...
	
	return cell
	}
	*/
	
	// MARK: - Editing
	
	/*
	// Override to support conditional editing of the table view.
	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
	// Return false if you do not want the specified item to be editable.
	return true
	}
	*/
	
	/*
	// Override to support editing the table view.
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
	if editingStyle == .delete {
	// Delete the row from the data source
	tableView.deleteRows(at: [indexPath], with: .fade)
	} else if editingStyle == .insert {
	// Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
	}
	}
	*/
	
	/*
	// Override to support conditional rearranging of the table view.
	override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
	// Return false if you do not want the item to be re-orderable.
	return true
	}
	*/
	
	/*
	// Override to support rearranging the table view.
	override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
	
	}
	*/
	
}
