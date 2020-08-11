//
//  LibraryViewerTableViewController.swift
//  LavaRock
//
//  Created by h on 2020-08-10.
//

import UIKit
import MediaPlayer

class LibraryViewerTableViewController: UITableViewController {
	
	// Constants
	static let artworkSize = CGSize(width: 66, height: 66)
	
	// Variables
	var items: [MPMediaItem]?
	

	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.tableFooterView = UIView()
		
		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false
		
		if MPMediaLibrary.authorizationStatus() == .authorized {
			loadSongs()
		} else {
			return
		}
	}
	
	func loadSongs() {
		items = MPMediaQuery.playlists().items
//		tableView.reloadData()
	}
	
	// MARK: Events
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		/*
		Special cases:
		- No access to Music library: 
		*/
		tableView.deselectRow(at: indexPath, animated: true)
	}

    // MARK: - Table view data source
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// Remember to accommodate for situations where the user hasn't allowed access to their Music library (use "Allow Access to Music Library" cell as button), and where the user has no songs in their Music library (use "Add some songs to the Music app" label as background view).
		return items?.count ?? 1
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		// TO DO: deduplicate this. Make this class a subclass of LibraryTVC.
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			let cell = tableView.dequeueReusableCell(withIdentifier: "Allow Access Cell", for: indexPath)
			if #available(iOS 14.0, *) {
				var configuration = UIListContentConfiguration.cell()
				configuration.text = "Allow Access to Music Library"
				configuration.textProperties.color = view.window!.tintColor
				cell.contentConfiguration = configuration
			} else { // iOS 13 and earlier
				cell.textLabel?.textColor = view.window?.tintColor
			}
			return cell
		}
		
//		guard items != nil else {
//			let cell = tableView.dequeueReusableCell(withIdentifier: "No Items Cell", for: indexPath)
//
//
//		}
		
		// Get the data to put into the cell.
		guard let item = items?[indexPath.row] else {
			return UITableViewCell()
		}
		let itemTitle = item.title
		let itemSubtitle = item.albumTitle
		let itemArtwork = item.artwork?.image(at: Self.artworkSize)
		
		if #available(iOS 14.0, *) {
			
			// Make the cell.
			let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
			var cc = UIListContentConfiguration.subtitleCell()
			
			// Put the data into the cell.
			cc.text = itemTitle
			cc.secondaryText = itemSubtitle
			cc.image = itemArtwork
			
			// Style the cell.
//			if indexPath.row == indexOfHighlightedItem {
//				cc.textProperties.color = accentColor
//			}
			cc.secondaryTextProperties.color = .secondaryLabel
			cc.imageProperties.maximumSize = Self.artworkSize
			
			// Return the cell.
			cell.contentConfiguration = cc
			return cell
			
		} else { // iOS 13 and earlier
			
			let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
			
			cell.textLabel?.text = itemTitle
			cell.detailTextLabel?.text = itemSubtitle
			cell.imageView?.image = itemArtwork
			
//			if indexPath.row == indexOfHighlightedItem {
//				cell.textLabel?.textColor = accentColor
//			} else {
//				cell.textLabel?.textColor = nil
//			}
			
			return cell
			
		}
		
	}

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
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

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
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
