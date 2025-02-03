// 2020-04-28

import UIKit
import SwiftUI
import MusicKit

@MainActor @Observable final class Exhibit {
	init() {
		NotificationCenter.default.addObserver(self, selector: #selector(merged), name: .librarian_merged, object: nil)
	}
	
	@ObservationIgnored fileprivate private(set) var artifacts: [Artifact] =
	Exhibit.uAlbums_fresh().map { .row_album($0) } { didSet {
		signal_artifacts += 1
		NotificationCenter.default.post(name: .exhibit_artifacts, object: self)
	}}
	private var signal_artifacts = 0 // Value is meaningless; we’re setting this property to tell SwiftUI to redraw views. (As of iOS 18.3, setting it to the same value again does trigger observers, but I’m being safe.)
	
	var focus: Focus = .covers { didSet {
		refresh_artifacts()
		NotificationCenter.default.post(name: .exhibit_focus, object: self)
	}}
	
	var selection: Selection = .view
	
	var activated: USong? { didSet { // Only use this when `selection == .view` and `focus == .expanded`.
		NotificationCenter.default.post(name: .song_activation, object: nil)
	}}
	
	fileprivate(set) var length_artwork: CGFloat!
}
extension Exhibit {
	fileprivate enum Artifact {
		case row_album(UAlbum)
		case row_song(USong)
	}
	
	enum Focus {
		case covers
		case spotlight(UAlbum)
		case expanded(UAlbum)
	}
	
	enum Selection {
		case view
		case mode_albums(Set<UAlbum>)
		case mode_songs(Set<USong>)
	}
	
	// MARK: Artifacts
	
	@ObservationIgnored fileprivate var rowIDs: [AnyHashable] { artifacts }
	
	private static func uAlbums_fresh() -> [UAlbum] {
		guard MusicAuthorization.currentStatus == .authorized
		else { return [] } // Don’t show any albums; show a placeholder.
		return Librarian.the_albums.map { $0.uAlbum }
	}
	@objc private func merged() {
		// Merging might have removed the spotlighted or expanded album.
		switch focus {
			case .covers: break
			case .spotlight(let uA_spotlighted):
				if !Self.uAlbums_fresh().contains(uA_spotlighted)
				{ focus = .covers }
			case .expanded(let uA_expanded):
				if !Self.uAlbums_fresh().contains(uA_expanded)
				{ focus = .covers }
		}
		
		refresh_artifacts()
		
		// Merging might have removed selected items or the activated song.
		switch selection {
			case .view:
				if let activated, uSongs(with: [activated]).isEmpty {
					self.activated = nil
				}
			case .mode_albums(let old_selected):
				guard !uAlbums().isEmpty else {
					selection = .view
					break
				}
				let selectable = Set(uAlbums(with: old_selected))
				if old_selected != selectable {
					selection = .mode_albums(selectable)
				}
			case .mode_songs(let old_selected):
				guard !uSongs().isEmpty else {
					selection = .view
					break
				}
				let selectable = Set(uSongs(with: old_selected))
				if old_selected != selectable{
					selection = .mode_songs(selectable)
				}
		}
	}
	private func refresh_artifacts() { // 2do: Return a value instead.
		artifacts = {
			let uAs_fresh = Self.uAlbums_fresh()
			switch focus {
				case .covers, .spotlight:
					return uAs_fresh.map { .row_album($0) }
				case .expanded(let uA_expanded):
					var result: [Artifact] = []
					uAs_fresh.forEach { uAlbum in
						result.append(.row_album(uAlbum))
						
						if uAlbum == uA_expanded {
							guard
								let album_expanded = Librarian.album_with_uAlbum[uAlbum]?.referencee
							else { return }
							let to_inline: [USong] = album_expanded.uSongs
							result.append(contentsOf: to_inline.map { .row_song($0) })
						}
					}
					return result
			}
		}()
	}
	
	func message_status() -> String {
		guard !Global.shared.librarian_is_merging
		else { return InterfaceText._Updating_library_ellipsis }
		switch selection {
			case .mode_albums(let uAs_selected):
				return InterfaceText.NUMBER_albums_selected(uAs_selected.count)
			case .mode_songs(let uSs_selected):
				return InterfaceText.NUMBER_songs_selected(uSs_selected.count)
			case .view:
				break
		}
		switch focus {
			case .spotlight: return ""
			case .covers:
				let total_albums = uAlbums().count
				return InterfaceText.NUMBER_albums(total_albums)
			case .expanded:
				let total_songs = uSongs().count
				return InterfaceText.NUMBER_songs(total_songs)
		}
	}
	
	func uSongs_focused() -> [USong] { // In display order.
		let _ = signal_artifacts
		switch selection {
			case .mode_songs(let uSs_selected): return uSongs(with: uSs_selected)
			case .mode_albums(let uAs_selected):
				var result: [USong] = []
				uAlbums(with: uAs_selected).forEach { uAlbum in // Order matters.
					guard let lrAlbum = Librarian.album_with_uAlbum[uAlbum]?.referencee
					else { return }
					result.append(contentsOf: lrAlbum.uSongs)
				}
				return result
			case .view:
				break
		}
		switch focus {
			case .spotlight: return []
			case .expanded: return uSongs()
			case .covers:
				var result: [USong] = []
				uAlbums().forEach { uAlbum in
					guard let lrAlbum = Librarian.album_with_uAlbum[uAlbum]?.referencee
					else { return  }
					result.append(contentsOf: lrAlbum.uSongs)
				}
				return result
		}
	}
	
	func uAlbums(with chosen: Set<UAlbum>? = nil) -> [UAlbum] {
		let _ = signal_artifacts
		return artifacts.compactMap { switch $0 { // `compactMap` rather than `filter` because we’re returning a different type.
			case .row_song: return nil
			case .row_album(let uAlbum):
				guard let chosen else { return uAlbum }
				guard chosen.contains(uAlbum) else { return nil }
				return uAlbum
		}}
	}
	private func uSongs(with chosen: Set<USong>? = nil) -> [USong] {
		let _ = signal_artifacts
		return artifacts.compactMap { switch $0 {
			case .row_album: return nil
			case .row_song(let uSong):
				guard let chosen else { return uSong }
				guard chosen.contains(uSong) else { return nil }
				return uSong
		}}
	}
	
	// MARK: Select
	
	func has_selected_album(_ uAlbum: UAlbum) -> Bool {
		switch selection {
			case .view, .mode_songs: return false
			case .mode_albums(let uAs_selected):
				return uAs_selected.contains(uAlbum)
		}
	}
	func has_selected_song(_ uSong: USong? = nil) -> Bool {
		switch selection {
			case .view, .mode_albums: return false
			case .mode_songs(let uSs_selected):
				guard let uSong else { return true }
				return uSs_selected.contains(uSong)
		}
	}
	func end_selecting_animated() {
		withAnimation {
			selection = .view
		}
	}
	
	func has_album_range(from uA_anchor: UAlbum, forward: Bool) -> Bool {
		guard let i_anchor = uAlbums().firstIndex(where: { $0 == uA_anchor }) else { return false }
		let i_neighbor: Int = forward ? (i_anchor+1) : (i_anchor-1)
		guard uAlbums().indices.contains(i_neighbor) else { return false }
		switch selection {
			case .mode_songs, .view: return true
			case .mode_albums(let uAs_selected):
				let anchor_is_selected = uAs_selected.contains(uA_anchor)
				let neighbor_is_selected = uAs_selected.contains(uAlbums()[i_neighbor])
				return anchor_is_selected == neighbor_is_selected
		}
	}
	func has_song_range(from uS_anchor: USong, forward: Bool) -> Bool {
		guard let i_anchor = uSongs().firstIndex(where: { $0 == uS_anchor }) else { return false }
		let i_neighbor: Int = forward ? (i_anchor+1) : (i_anchor-1)
		guard uSongs().indices.contains(i_neighbor) else { return false }
		switch selection {
			case .mode_albums: return false
			case .view: return true
			case .mode_songs(let uSs_selected):
				let anchor_is_selected = uSs_selected.contains(uS_anchor)
				let neighbor_is_selected = uSs_selected.contains(uSongs()[i_neighbor])
				return anchor_is_selected == neighbor_is_selected
		}
	}
	
	func change_album_range(from uA_anchor: UAlbum, forward: Bool) {
		guard let i_anchor = uAlbums().firstIndex(where: { $0 == uA_anchor })
		else { return }
		let old_selected: Set<UAlbum> = { switch selection {
			case .mode_songs, .view: return []
			case .mode_albums(let uAs_selected): return uAs_selected
		}}()
		let inserting: Bool = !old_selected.contains(uA_anchor)
		let new_selected: Set<UAlbum> = {
			var result = old_selected
			var i_in_range = i_anchor
			while true {
				guard uAlbums().indices.contains(i_in_range) else { break }
				let uA_in_range = uAlbums()[i_in_range]
				
				if inserting {
					guard !result.contains(uA_in_range) else { break }
					result.insert(uA_in_range)
				} else {
					guard result.contains(uA_in_range) else { break }
					result.remove(uA_in_range)
				}
				if forward { i_in_range += 1 } else { i_in_range -= 1 }
			}
			return result
		}()
		switch selection {
			case .mode_songs: return
			case .view, .mode_albums:
				selection = .mode_albums(new_selected)
		}
	}
	func change_song_range(from uS_anchor: USong, forward: Bool) {
		guard let i_anchor = uSongs().firstIndex(where: { $0 == uS_anchor })
		else { return }
		let old_selected: Set<USong> = { switch selection {
			case .mode_albums, .view: return []
			case .mode_songs(let uAs_selected): return uAs_selected
		}}()
		let inserting: Bool = !old_selected.contains(uS_anchor)
		let new_selected: Set<USong> = {
			var result = old_selected
			var i_in_range = i_anchor
			while true {
				guard uSongs().indices.contains(i_in_range) else { break }
				let uS_in_range = uSongs()[i_in_range]
				
				if inserting {
					guard !result.contains(uS_in_range) else { break }
					result.insert(uS_in_range)
				} else {
					guard result.contains(uS_in_range) else { break }
					result.remove(uS_in_range)
				}
				if forward { i_in_range += 1 } else { i_in_range -= 1 }
			}
			return result
		}()
		switch selection {
			case .mode_albums: return
			case .view, .mode_songs:
				selection = .mode_songs(new_selected)
		}
	}
	
	// MARK: Sort
	
	func sort_albums(by albumOrder: AlbumOrder) {
		Librarian.sort_albums(uAlbums_to_sort(), by: albumOrder)
		refresh_artifacts()
	}
	func sort_songs(by songOrder: SongOrder) {
		Librarian.sort_songs(uSongs_to_sort(), by: songOrder)
		refresh_artifacts()
	}
	
	func can_sort_albums(by albumOrder: AlbumOrder) -> Bool {
		let to_sort = uAlbums_to_sort()
		guard to_sort.count >= 2 else { return false }
		
		switch selection {
			case .mode_songs, .view: break
			case .mode_albums(let uAs_selected):
				let rs_selected = uAlbums().indices(where: { uAlbum in
					uAs_selected.contains(uAlbum)
				})
				guard rs_selected.ranges.count <= 1 else { return false }
		}
		
		switch albumOrder {
			case .random, .reverse, .recently_added: return true
			case .recently_released: return to_sort.contains {
				nil != AppleCatalog.shared.albumInfo(uAlbum: $0)?._date_released
			}
		}
	}
	func can_sort_songs(by songOrder: SongOrder) -> Bool {
		guard uSongs_to_sort().count >= 2 else { return false }
		
		switch selection {
			case .mode_albums, .view: break
			case .mode_songs(let uSs_selected):
				let rs_selected = uSongs().indices(where: { uSong in
					uSs_selected.contains(uSong)
				})
				guard rs_selected.ranges.count <= 1 else { return false }
		}
		
		return true
	}
	
	private func uAlbums_to_sort() -> Set<UAlbum> {
		let _ = signal_artifacts // In case, for example, after first merge.
		switch selection {
			case .mode_songs: return []
			case .view: return Set(uAlbums()) // Implicitly select all.
			case .mode_albums(let uAs_selected): return uAs_selected
		}
	}
	private func uSongs_to_sort() -> Set<USong> {
		let _ = signal_artifacts // In case, for example, focus is an expanded album with 1 song, and merging adds a 2nd song.
		switch selection {
			case .mode_albums: return []
			case .view: return Set(uSongs())
			case .mode_songs(let uSs_selected): return uSs_selected
		}
	}
	
	// MARK: Reorder
	
	func can_reorder_selection(up: Bool) -> Bool {
		switch selection {
			case .view: return false
			case .mode_albums(let uAs_selected):
				guard !uAs_selected.isEmpty else { return false }
				// If the selected albums are the topmost N albums, then they’re already at the top.
				let at_limit: [UAlbum] = {
					if up
					{ return Array(uAlbums().prefix(uAs_selected.count)) }
					return uAlbums().suffix(uAs_selected.count)
				}()
				return !at_limit.allSatisfy { uAs_selected.contains($0) }
			case .mode_songs(let uSs_selected):
				guard !uSs_selected.isEmpty else { return false }
				let at_limit: [USong] = {
					if up
					{ return Array(uSongs().prefix(uSs_selected.count)) }
					return uSongs().suffix(uSs_selected.count)
				}()
				return !at_limit.allSatisfy { uSs_selected.contains($0) }
		}
	}
	
	func reorder_selection(up: Bool, to_limit: Bool) {
		switch selection {
			case .view: return
			case .mode_albums(let uAs_selected):
				if up {
					Librarian.promote_albums(uAs_selected, to_limit: to_limit)
				} else {
					Librarian.demote_albums(uAs_selected, to_limit: to_limit)
				}
			case .mode_songs(let uSs_selected):
				if up {
					Librarian.promote_songs(uSs_selected, to_limit: to_limit)
				} else {
					Librarian.demote_songs(uSs_selected, to_limit: to_limit)
				}
		}
		refresh_artifacts()
		if to_limit {
			switch selection {
				case .view: break
				case .mode_albums: selection = .mode_albums([])
				case .mode_songs: selection = .mode_songs([])
			}
		}
	}
}
extension Exhibit.Artifact: Hashable {}
extension Exhibit.Focus: Equatable {}
extension Exhibit.Selection: Equatable {}

// MARK: - View controller

final class ExhibitTVC: LRTableViewController {
	static func init_please() -> Self {
		return UIStoryboard(name: "ExhibitTVC", bundle: nil).instantiateInitialViewController() as! Self
	}
	private let exhibit = Exhibit()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		Global.shared.showcase = exhibit // Ideally, whoever initializes this view should also initialize this.
		Global.shared.gallery = self
		
		view.backgroundColor = .clear
		tableView.separatorStyle = .none
		
		NotificationCenter.default.addObserver(self, selector: #selector(reflect_artifacts), name: .exhibit_artifacts, object: exhibit)
		NotificationCenter.default.addObserver(self, selector: #selector(reflect_focus), name: .exhibit_focus, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(reflect_activation), name: .song_activation, object: nil)
	}
	
	override func viewIsAppearing(_ animated: Bool) {
		super.viewIsAppearing(animated)
		exhibit.length_artwork = Self.length_square_fitting(
			size_frame: view.frame.size,
			safeAreaInsets: view.safeAreaInsets)
		refresh_contentInset(size_frame: view.frame.size)
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		// The `size` parameter will later become `view.frame.size`, not `view.bounds.size`.
		exhibit.length_artwork = Self.length_square_fitting(
			size_frame: size,
			safeAreaInsets: view.safeAreaInsets)
		refresh_contentInset(size_frame: size)
	}
	
	private static func length_square_fitting(
		size_frame: CGSize,
		safeAreaInsets: UIEdgeInsets
	) -> CGFloat {
		return min(
			size_frame.width,
			size_frame.height - safeAreaInsets.bottom)
	}
	
	private func refresh_contentInset(size_frame: CGSize) {
		tableView.contentInset = {
			let gutter: CGFloat
			= size_frame.height / 2
			- exhibit.length_artwork / 2
			
			// `adjustedContentInset` is what matters because it determines the scrolling limits, but we can’t set it directly. We can set `contentInset`, but UIKit adds safe area insets to that.
			// As of iOS 18.3 RC, don’t use `contentInsetAdjustmentBehavior = .never`, because it breaks row sizing.
			
			var top: CGFloat = .zero
			top -= view.safeAreaInsets.top // Offsets how `UIScrollView` interprets `contentInset`. Applying it now should make it effectively zero.
			top += gutter
			top = top.rounded(.down) // As of iOS 18.3 developer beta 3, a non-integer value prevents you from rapidly expanding and collapsing albums.
			
			var bottom: CGFloat = .zero
			bottom -= view.safeAreaInsets.bottom
			bottom += gutter
			bottom = bottom.rounded(.up)
			
			return UIEdgeInsets(top: top, left: .zero, bottom: bottom, right: .zero)
		}()
	}
	
	// MARK: Table view
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		refresh_placeholder()
		return 1
	}
	private func refresh_placeholder() {
		contentUnavailableConfiguration = {
			guard MusicAuthorization.currentStatus == .authorized else {
				return UIHostingConfiguration {
					ContentUnavailableView {
						Text(InterfaceText._welcome_title).bold() // As of iOS 18.2 developer beta 4, the Settings app uses this for “No Fonts Installed”.
					} description: {
						Text(InterfaceText._welcome_subtitle)
					} actions: {
						Button(InterfaceText.Start) {
							switch MusicAuthorization.currentStatus {
								case .authorized: return
								case .denied, .restricted: Task {
									guard
										let url_settings = URL(string: UIApplication.openSettingsURLString)
									else { return }
									let _ = await UIApplication.shared.open(url_settings)
								}
								case .notDetermined: Task {
									switch await MusicAuthorization.request() {
										case .denied, .restricted, .notDetermined: return
										case .authorized: LavaRock.integrate_Apple_Music()
										@unknown default: return
									}
								}
								@unknown default: return
							}
						}
					}
				}.margins(.all, .zero) // As of iOS 17.5 developer beta 1, this prevents the content from sometimes jumping vertically.
			}
			if exhibit.artifacts.isEmpty {
				return UIHostingConfiguration {
					Placeholder()
						.accessibilityLabel(InterfaceText.No_music)
						.accessibilityRemoveTraits(.isImage)
				}.margins(.all, .zero)
			}
			return nil
		}()
	}
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if !initialized_rowIDs_current {
			initialized_rowIDs_current = true
			rowIDs_current = exhibit.rowIDs
		}
		return exhibit.artifacts.count
	}
	private var initialized_rowIDs_current = false
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch exhibit.artifacts[indexPath.row] {
			case .row_album(let uAlbum):
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Album Card", for: indexPath)
				cell.backgroundColor = .clear
				cell.selectionStyle = .none // Prevents highlighting.
				cell.contentConfiguration = UIHostingConfiguration {
					AlbumRow(uAlbum: uAlbum, exhibit: exhibit)
				}.margins(.all, .zero)
				return cell
			case .row_song(let uSong):
				switch exhibit.focus {
					case .covers, .spotlight: return UITableViewCell() // Should never run
					case .expanded(let uAlbum):
						// The cell in the storyboard is completely default except for the reuse identifier.
						let cell = tableView.dequeueReusableCell(withIdentifier: "Inline Song", for: indexPath)
						cell.backgroundColor = .clear
						cell.selectionStyle = .none
						cell.contentConfiguration = UIHostingConfiguration {
							SongRow(
								uSong: uSong,
								uAlbum: uAlbum,
								exhibit: exhibit)
						}.margins(.all, .zero)
						return cell
				}
		}
	}
	
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? { return nil }
	
	// MARK: Events
	
	func spotlight_current() {
		guard
			let uSong = LCD.shared.uSong_current,
			let album = Librarian.album_containing_uSong[uSong]?.referencee
		else { return }
		exhibit.focus = .spotlight(album.uAlbum)
	}
	
	@objc private func reflect_artifacts() {
		Task {
			await apply_rowIDs(exhibit.rowIDs)
		}
	}
	
	@objc private func reflect_focus() {
		let artifact_target: Exhibit.Artifact? = {
			switch exhibit.focus {
				case .covers: return nil
				case .expanded(let uA_expanded): return .row_album(uA_expanded)
				case .spotlight(let uA_spotlighted): return .row_album(uA_spotlighted)
			}
		}()
		guard
			let artifact_target,
			let i_artifact = self.exhibit.artifacts.firstIndex(of: artifact_target)
		else { return }
		Task { // Prevents jank in case we called `apply_rowIDs` just earlier.
			tableView.scrollToRow(
				at: IndexPath(row: i_artifact, section: 0),
				at: .top,
				animated: true)
		}
	}
	
	@objc private func reflect_activation() {
		guard let activated = exhibit.activated else {
			dismiss(animated: true) // Should be the “Start Playing” action sheet.
			return
		}
		
		guard let view_anchor: UIView = { () -> UITableViewCell? in
			guard let row_activating = exhibit.artifacts.firstIndex(where: { switch $0 {
				case .row_album: return false
				case .row_song(let uSong): return uSong == activated
			}}) else { return nil }
			return tableView.cellForRow(at: IndexPath(row: row_activating, section: 0))
		}() else { return }
		
		let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		sheet.popoverPresentationController?.sourceView = view_anchor
		sheet.addAction(
			UIAlertAction(title: InterfaceText.Start_Playing, style: .default) { _ in
				self.exhibit.activated = nil
				Task {
					guard let album = Librarian.album_containing_uSong[activated]?.referencee else { return }
					await Tape.play_now(album.uSongs, starting_at: activated)
				}
			}
			// 2do: Silence VoiceOver after starting audio. `UIAlertAction.accessibilityTraits = .startsMediaSession` doesn’t do it.)
		)
		sheet.addAction(
			UIAlertAction(title: InterfaceText.Cancel, style: .cancel) { _ in
				self.exhibit.activated = nil
			}
		)
		present(sheet, animated: true)
	}
}
