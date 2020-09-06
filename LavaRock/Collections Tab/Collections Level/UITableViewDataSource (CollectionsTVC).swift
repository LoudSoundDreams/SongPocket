//
//  UITableViewDataSource (CollectionsTVC).swift
//  LavaRock
//
//  Created by h on 2020-08-30.
//

import UIKit
import MediaPlayer

extension CollectionsTVC {
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard MPMediaLibrary.authorizationStatus() == .authorized else {
			return super.tableView(tableView, cellForRowAt: indexPath)
		}
		
		// Get the data to put into the cell.
//		guard let collection = fetchedResultsController?.object(at: indexPath) as? Collection else {
//			return UITableViewCell()
//		}
		let collection = indexedLibraryItems[indexPath.row - numberOfRowsAboveIndexedLibraryItems] as! Collection
		
//		print("According to our records, the collection “\(collection.title)” should be at row index \(collection.index); we're making a cell for it at row index \(indexPath.row)")
		
		// Make, configure, and return the cell.
		let cell = tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier, for: indexPath)
		if #available(iOS 14, *) {
			var configuration = cell.defaultContentConfiguration()
			configuration.text = collection.title
			
			if let moveAlbumsClipboard = moveAlbumsClipboard {
				if collection.objectID == moveAlbumsClipboard.idOfCollectionThatAlbumsAreBeingMovedOutOf {
					configuration.textProperties.color = .placeholderText // A proper way to make cells look disabled would be better. This is slightly different from the old cell.textLabel.isEnabled = false.
					// TO DO: Tell VoiceOver that this cell is disabled.
					cell.selectionStyle = .none
				}
			}
			
			cell.contentConfiguration = configuration
			
		} else { // iOS 13 and earlier
			cell.textLabel?.text = collection.title
			
			if let moveAlbumsClipboard = moveAlbumsClipboard {
				if collection.objectID == moveAlbumsClipboard.idOfCollectionThatAlbumsAreBeingMovedOutOf {
					cell.textLabel?.isEnabled = false
					cell.selectionStyle = .none
				}
			}
		}
		return cell
	}
	
}
