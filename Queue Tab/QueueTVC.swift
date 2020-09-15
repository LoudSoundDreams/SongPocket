//
//  QueueTVC.swift
//  LavaRock
//
//  Created by h on 2020-09-14.
//

import UIKit
import CoreData

final class QueueTVC: UITableViewController {
	
	// MARK: - Properties
	
	// "Constants"
	@IBOutlet var clearButton: UIBarButtonItem!
	@IBOutlet var goToPreviousSongButton: UIBarButtonItem!
	@IBOutlet var restartCurrentSongButton: UIBarButtonItem!
	@IBOutlet var playPauseButton: UIBarButtonItem!
	@IBOutlet var goToNextSongButton: UIBarButtonItem!
	let cellReuseIdentifier = "Cell"
	let numberOfNonQueueEntryCells = 0
//	let coreDataFetchRequest: NSFetchRequest<QueueEntry> = {
//		let request = NSFetchRequest<QueueEntry>(entityName: "QueueEntry")
//		request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
//		return request
//	}()
	
	// Variables
//	let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//	var indexedQueueEntries = [QueueEntry]() {
//		didSet {
//			for index in 0 ..< indexedQueueEntries.count {
//				indexedQueueEntries[index].index = Int64(index)
//			}
//		}
//	}
	
	// MARK: - Setup
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
//		beginObservingNotifications()
		// load data
		setUpUI()
    }
	
	// MARK: Setting Up UI
	
	private func setUpUI() {
		isEditing = true
		
		refreshButtons()
		
		tableView.separatorInsetReference = .fromAutomaticInsets
		tableView.separatorInset.left = 44
		tableView.tableFooterView = UIView()
	}
	
	// MARK: Teardown
	
//	deinit {
//		endObservingNotifications()
//	}
	
	// MARK: - Events
	
	func refreshButtons() {
//		clearButton.isEnabled = indexedQueueEntries.count > 0
//		goToPreviousSongButton.isEnabled = indexedQueueEntries.count > 0
//		restartCurrentSongButton.isEnabled = indexedQueueEntries.count > 0
//		playPauseButton.isEnabled = indexedQueueEntries.count > 0
//		goToNextSongButton.isEnabled = indexedQueueEntries.count > 0
		
	}
	
}
