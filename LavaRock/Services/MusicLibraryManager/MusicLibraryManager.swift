//
//  MusicLibraryManager.swift
//  LavaRock
//
//  Created by h on 2020-08-10.
//

import MediaPlayer

final class MusicLibraryManager { // This is a class and not a struct because it should end observing notifications in a deinitializer.
	
	private init() {}
	static let shared = MusicLibraryManager()
	
	let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
	
	private var library: MPMediaLibrary? = nil
	
	final func setUpAndMergeChanges() {
		guard MPMediaLibrary.authorizationStatus() == .authorized else { return }
		
		library = MPMediaLibrary.default()
		mergeChanges()
		
		NotificationCenter.default.removeAndAddObserver(
			self,
			selector: #selector(mediaLibraryDidChange),
			name: .MPMediaLibraryDidChange,
			object: nil)
		
		library?.beginGeneratingLibraryChangeNotifications()
	}
	@objc private func mediaLibraryDidChange() { mergeChanges() }
	
	deinit {
		NotificationCenter.default.removeObserver(self)
		
		library?.endGeneratingLibraryChangeNotifications()
	}
	
}
