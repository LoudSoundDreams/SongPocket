//
//  Notifications (LibraryTVC).swift
//  LavaRock
//
//  Created by h on 2020-08-29.
//

import UIKit
import MediaPlayer
import CoreData

extension LibraryTVC {
	
	// MARK: - Setup and Teardown
	
	func startObservingNotifications() {
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.LRWillSaveChangesFromAppleMusicLibrary,
			object: nil)
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.NSManagedObjectContextDidSave,
			object: managedObjectContext)
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(didObserve(_:)),
			name: Notification.Name.LRDidChangeAccentColor,
			object: nil)
	}
	
	func endObservingNotifications() {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: - Responding
	
	@objc func didObserve(_ notification: Notification) {
		switch notification.name {
		case .LRWillSaveChangesFromAppleMusicLibrary:
			willSaveChangesFromAppleMusicLibrary()
		case .NSManagedObjectContextDidSave:
			managedObjectContextDidSave(notification)
		case .LRDidChangeAccentColor:
			didChangeAccentColor()
		default:
			print("An instance of \(Self.self) observed the notification: \(notification.name)")
			print("… but the app is not set to do anything after observing that notification.")
		}
	}
	
	private func willSaveChangesFromAppleMusicLibrary() {
		guard respondsToWillSaveChangesFromAppleMusicLibraryNotifications else { return }
		shouldRespondToNextManagedObjectContextDidSaveNotification = true
	}
	
	@objc func managedObjectContextDidSave(_ notification: Notification) {
		guard shouldRespondToNextManagedObjectContextDidSaveNotification else { return }
		shouldRespondToNextManagedObjectContextDidSaveNotification = false
		
		var itemsToDeleteFromThisView = [NSManagedObject]()
		var itemsToRefreshInThisView = [NSManagedObject]()
		
		for key in [NSDeletedObjectsKey, NSInsertedObjectsKey, NSUpdatedObjectsKey] {
			guard let changedObjects = notification.userInfo?[key] as? Set<NSManagedObject> else {
				continue // to the next key
			}
			
			for object in changedObjects {
				guard object.entity.name == coreDataEntityName else {
					continue // to the next object
				}
				
				if key == NSDeletedObjectsKey {
					itemsToDeleteFromThisView.append(object)
					
				} else { // NSInsertedObjectsKey or NSUpdatedObjectsKey
					if containerOfData == nil || (containerOfData != nil && (object.value(forKey: "container") as? NSManagedObject) == containerOfData) {
						itemsToRefreshInThisView.append(object)
					}
				}
			}
		}
		
		print(Self.self)
		print(itemsToDeleteFromThisView)
		print(itemsToRefreshInThisView)
		
		deleteFromView(itemsToDeleteFromThisView)
		refreshInView(itemsToRefreshInThisView)
	}
	
	@objc func deleteFromView(_ items: [NSManagedObject]) {
//		print("The class “\(Self.self)” should override deleteFromView(items:). We would call it at this point.")
	}
	
	@objc func refreshInView(_ items: [NSManagedObject]) {
//		print("The class “\(Self.self)” should override refreshInView(items:). We would call it at this point.")
	}
	
	func didChangeAccentColor() {
		guard MPMediaLibrary.authorizationStatus() != .authorized else { return }
		tableView.reloadData()
	}
	
}
