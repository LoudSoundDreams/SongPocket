// 2020-04-28

import UIKit
import SwiftUI
import MusicKit
import MediaPlayer

@MainActor @Observable final class AlbumListState {
	@ObservationIgnored fileprivate var list_items: [AlbumListItem] = AlbumListState.album_mpids_fresh().map { .album_mpid($0) }
	var expansion: Expansion = .collapsed { didSet {
		NotificationCenter.default.post(name: Self.expansion_changed, object: self)
	}}
	var select_mode: SelectMode = .view(nil) { didSet {
		NotificationCenter.default.post(name: Self.selection_changed, object: self)
	}}
	var signal_albums_reordered = false
	var signal_songs_reordered = false
	var size_viewport: (width: CGFloat, height: CGFloat) = (.zero, .zero)
}
extension AlbumListState {
	fileprivate enum AlbumListItem {
		case album_mpid(MPIDAlbum)
		case song_mpid(MPIDSong)
	}
	fileprivate func refresh_items() {
		list_items = {
			let album_mpids = Self.album_mpids_fresh()
			switch expansion {
				case .collapsed: return album_mpids.map { .album_mpid($0) }
				case .expanded(let id_expanded):
					// If we removed the expanded album, go to collapsed mode.
					guard
						let i_expanded = album_mpids.firstIndex(where: { $0 == id_expanded }),
						let lrAlbum = Librarian.lrAlbum_with(mpid: id_expanded)
					else {
						expansion = .collapsed
						return album_mpids.map { .album_mpid($0) }
					}
					
					let song_mpids_inline: [AlbumListItem] = lrAlbum.lrSongs.map {
						.song_mpid($0.mpid)
					}
					var result: [AlbumListItem] = album_mpids.map { .album_mpid($0) }
					result.insert(contentsOf: song_mpids_inline, at: i_expanded + 1)
					return result
			}
		}()
		
		// In case we removed items the user was doing something with.
		switch select_mode {
			case .view(let id_activated):
				if let id_activated, song_mpids(with: [id_activated]).isEmpty {
					select_mode = .view(nil)
				}
			case .select_albums(let ids_selected):
				let selectable: Set<MPIDAlbum> = Set(
					album_mpids(with: ids_selected)
				)
				if ids_selected != selectable {
					select_mode = .select_albums(selectable)
				}
			case .select_songs(let ids_selected):
				guard !song_mpids().isEmpty else {
					select_mode = .view(nil)
					break
				}
				let selectable: Set<MPIDSong> = Set(
					song_mpids(with: ids_selected)
				)
				if ids_selected != selectable{
					select_mode = .select_songs(selectable)
				}
		}
	}
	private static func album_mpids_fresh() -> [MPIDAlbum] {
		guard let the_crate = Librarian.the_lrCrate else { return [] }
		return the_crate.lrAlbums.map { $0.mpid }
	}
	fileprivate func row_identifiers() -> [AnyHashable] {
		return list_items.map { switch $0 {
			case .album_mpid(let mpidAlbum): return mpidAlbum
			case .song_mpid(let mpidSong): return mpidSong
		}}
	}
	fileprivate func album_mpids(with ids_chosen: Set<MPIDAlbum>? = nil) -> [MPIDAlbum] {
		return list_items.compactMap { switch $0 { // `compactMap` rather than `filter` because we’re returning a different type.
			case .song_mpid: return nil
			case .album_mpid(let mpidAlbum):
				guard let ids_chosen else { return mpidAlbum }
				guard ids_chosen.contains(mpidAlbum) else { return nil }
				return mpidAlbum
		}}
	}
	fileprivate func song_mpids(with ids_chosen: Set<MPIDSong>? = nil) -> [MPIDSong] {
		return list_items.compactMap { switch $0 {
			case .album_mpid: return nil
			case .song_mpid(let mpidSong):
				guard let ids_chosen else { return mpidSong }
				guard ids_chosen.contains(mpidSong) else { return nil }
				return mpidSong
		}}
	}
	
	func has_album_range(from id_anchor: MPIDAlbum, forward: Bool) -> Bool {
		guard let i_anchor = album_mpids().firstIndex(where: { $0 == id_anchor }) else { return false }
		let i_neighbor: Int = forward ? (i_anchor+1) : (i_anchor-1)
		guard album_mpids().indices.contains(i_neighbor) else { return false }
		switch select_mode {
			case .select_songs, .view: return true
			case .select_albums(let ids_selected):
				let anchor_is_selected = ids_selected.contains(id_anchor)
				let neighbor_is_selected = ids_selected.contains(album_mpids()[i_neighbor])
				return anchor_is_selected == neighbor_is_selected
		}
	}
	func has_song_range(from id_anchor: MPIDSong, forward: Bool) -> Bool {
		guard let i_anchor = song_mpids().firstIndex(where: { $0 == id_anchor }) else { return false }
		let i_neighbor: Int = forward ? (i_anchor+1) : (i_anchor-1)
		guard song_mpids().indices.contains(i_neighbor) else { return false }
		switch select_mode {
			case .select_albums: return false
			case .view: return true
			case .select_songs(let ids_selected):
				let anchor_is_selected = ids_selected.contains(id_anchor)
				let neighbor_is_selected = ids_selected.contains(song_mpids()[i_neighbor])
				return anchor_is_selected == neighbor_is_selected
		}
	}
	
	func change_album_range(from id_anchor: MPIDAlbum, forward: Bool) {
		guard let i_anchor = album_mpids().firstIndex(where: { $0 == id_anchor }) else { return }
		let old_selected: Set<MPIDAlbum> = {
			switch select_mode {
				case .select_songs, .view: return []
				case .select_albums(let ids_selected): return ids_selected
			}
		}()
		let inserting: Bool = !old_selected.contains(id_anchor)
		let new_selected: Set<MPIDAlbum> = {
			var result = old_selected
			var i_in_range = i_anchor
			while true {
				guard album_mpids().indices.contains(i_in_range) else { break }
				let id_in_range = album_mpids()[i_in_range]
				
				if inserting {
					guard !result.contains(id_in_range) else { break }
					result.insert(id_in_range)
				} else {
					guard result.contains(id_in_range) else { break }
					result.remove(id_in_range)
				}
				if forward { i_in_range += 1 } else { i_in_range -= 1 }
			}
			return result
		}()
		switch select_mode {
			case .select_songs: break
			case .view:
				withAnimation {
					select_mode = .select_albums(new_selected)
				}
			case .select_albums:
				select_mode = .select_albums(new_selected)
		}
	}
	func change_song_range(from id_anchor: MPIDSong, forward: Bool) {
		guard let i_anchor = song_mpids().firstIndex(where: { $0 == id_anchor }) else { return }
		let old_selected: Set<MPIDSong> = {
			switch select_mode {
				case .select_albums, .view: return []
				case .select_songs(let ids_selected): return ids_selected
			}
		}()
		let inserting: Bool = !old_selected.contains(id_anchor)
		let new_selected: Set<MPIDSong> = {
			var result = old_selected
			var i_in_range = i_anchor
			while true {
				guard song_mpids().indices.contains(i_in_range) else { break }
				let id_in_range = song_mpids()[i_in_range]
				
				if inserting {
					guard !result.contains(id_in_range) else { break }
					result.insert(id_in_range)
				} else {
					guard result.contains(id_in_range) else { break }
					result.remove(id_in_range)
				}
				if forward { i_in_range += 1 } else { i_in_range -= 1 }
			}
			return result
		}()
		switch select_mode {
			case .select_albums: break
			case .view:
				withAnimation {
					select_mode = .select_songs(new_selected)
				}
			case .select_songs:
				select_mode = .select_songs(new_selected)
		}
	}
	
	enum Expansion: Equatable {
		case collapsed
		case expanded(MPIDAlbum)
	}
	static let expansion_changed = Notification.Name("LRAlbumExpandingOrCollapsing")
	
	enum SelectMode: Equatable {
		case view(MPIDSong?)
		case select_albums(Set<MPIDAlbum>)
		case select_songs(Set<MPIDSong>) // Should always be within the same album.
	}
	static let selection_changed = Notification.Name("LRSelectModeOrSelectionChanged")
}

// MARK: - View controller

final class AlbumsTVC: LibraryTVC {
	private let list_state = AlbumListState()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		view.backgroundColor = UIColor(Color.white_one_eighth)
		tableView.separatorStyle = .none
		reflect_selection()
		b_sort.preferredMenuElementOrder = .fixed
		b_sort.menu = menu_sort()
		b_focused.preferredMenuElementOrder = .fixed
		b_focused.menu = menu_focused()
		
		NotificationCenter.default.addObserver(self, selector: #selector(refresh_list_items), name: AppleLibrary.did_merge, object: nil)
		Remote.shared.weak_tvc_albums = self
		NotificationCenter.default.addObserver(self, selector: #selector(reflect_expansion), name: AlbumListState.expansion_changed, object: list_state)
		NotificationCenter.default.addObserver(self, selector: #selector(confirm_play), name: SongRow.confirm_play_id_song, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(reflect_selection), name: AlbumListState.selection_changed, object: list_state)
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
							Task {
								switch MusicAuthorization.currentStatus {
									case .authorized: break // Should never run
									case .notDetermined:
										switch await MusicAuthorization.request() {
											case .denied, .restricted, .notDetermined: break
											case .authorized: LavaRock.integrate_Apple_Music()
											@unknown default: break
										}
									case .denied, .restricted:
										guard let url_settings = URL(string: UIApplication.openSettingsURLString) else { return }
										let _ = await UIApplication.shared.open(url_settings)
									@unknown default: break
								}
							}
						}
					}
				}.margins(.all, .zero) // As of iOS 17.5 developer beta 1, this prevents the content from sometimes jumping vertically.
			}
			if list_state.list_items.isEmpty {
				return UIHostingConfiguration {
					Image(systemName: "music.note")
						.foregroundStyle(Color.white_one_half)
						.font(.title)
						.accessibilityLabel(InterfaceText.No_music)
						.accessibilityRemoveTraits(.isImage)
				}.margins(.all, .zero)
			}
			return nil
		}()
	}
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if !has_set_ids_rows_onscreen {
			has_set_ids_rows_onscreen = true
			ids_rows_onscreen = list_state.row_identifiers()
		}
		return list_state.list_items.count
	}
	private var has_set_ids_rows_onscreen = false
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch list_state.list_items[indexPath.row] {
			case .album_mpid(let mpidAlbum):
				// The cell in the storyboard is completely default except for the reuse identifier.
				let cell = tableView.dequeueReusableCell(withIdentifier: "Album Card", for: indexPath)
				cell.backgroundColor = .clear
				cell.selectedBackgroundView = {
					let result = UIView()
					result.backgroundColor = .tintColor.withAlphaComponent(.one_half)
					return result
				}()
				list_state.size_viewport = (
					width: view.frame.width,
					height: view.frame.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom)
				cell.contentConfiguration = UIHostingConfiguration {
					AlbumRow(
						id_album: mpidAlbum,
						list_state: list_state)
				}.margins(.all, .zero)
				return cell
			case .song_mpid(let mpidSong):
				switch list_state.expansion {
					case .collapsed: return UITableViewCell() // Should never run
					case .expanded(let id_expanded):
						// The cell in the storyboard is completely default except for the reuse identifier.
						let cell = tableView.dequeueReusableCell(withIdentifier: "Inline Song", for: indexPath)
						cell.backgroundColor = .clear
						cell.selectedBackgroundView = {
							let result = UIView()
							result.backgroundColor = .tintColor.withAlphaComponent(.one_half)
							return result
						}()
						cell.contentConfiguration = UIHostingConfiguration {
							SongRow(
								id_song: mpidSong,
								id_album: id_expanded,
								list_state: list_state)
						}.margins(.all, .zero)
						return cell
				}
		}
	}
	
	override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? { return nil }
	
	// MARK: Events
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		list_state.size_viewport = (width: size.width, height: size.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom)
	}
	
	@objc private func refresh_list_items() {
		Task {
			list_state.refresh_items()
			b_sort.menu = menu_sort()
			b_focused.menu = menu_focused()
			guard await apply_ids_rows(list_state.row_identifiers()) else { return }
		}
	}
	
	func show_current() {
		guard
			let id_current = MPMusicPlayerController.mpidSong_current,
			let lrSong = Librarian.lrSong_with(mpid: id_current)
		else { return }
		let mpidAlbum_target = lrSong.lrAlbum.mpid
		guard let row_target = list_state.list_items.firstIndex(where: { switch $0 {
			case .song_mpid: return false
			case .album_mpid(let mpidAlbum): return mpidAlbum == mpidAlbum_target
		}}) else { return }
		tableView.performBatchUpdates {
			tableView.scrollToRow(at: IndexPath(row: row_target, section: 0), at: .top, animated: true)
		} completion: { _ in
			self.list_state.expansion = .expanded(mpidAlbum_target)
		}
	}
	
	@objc private func reflect_expansion() {
		switch list_state.expansion {
			case .collapsed:
				Task {
					list_state.refresh_items() // Immediately proceed to update the table view; don’t wait until a separate `Task`. As of iOS 17.6 developer beta 2, `UITableView` has a bug where it might call `cellForRowAt` with invalidly large `IndexPath`s: it’s trying to draw subsequent rows after we change a cell’s height in a `UIHostingConfiguration`, but forgetting to call `numberOfRowsInSection` first.
					b_sort.menu = menu_sort()
					b_focused.menu = menu_focused()
					let _ = await apply_ids_rows(list_state.row_identifiers())
				}
			case .expanded(let id_to_expand):
				Task {
					guard list_state.album_mpids().contains(where: { $0 == id_to_expand }) else { return }
					list_state.refresh_items()
					b_sort.menu = menu_sort()
					b_focused.menu = menu_focused()
					let _ = await apply_ids_rows(list_state.row_identifiers(), running_before_continuation: {
						let row_target: Int = self.list_state.list_items.firstIndex(where: { switch $0 {
							case .song_mpid: return false
							case .album_mpid(let mpidAlbum): return mpidAlbum == id_to_expand
						}})!
						self.tableView.scrollToRow(at: IndexPath(row: row_target, section: 0), at: .top, animated: true)
					})
				}
		}
	}
	
	@objc private func reflect_selection() {
		switch list_state.select_mode {
			case .view(let id_activated):
				navigationItem.setRightBarButtonItems([], animated: true)
				setToolbarItems([b_sort, .flexibleSpace(), Remote.shared.b_remote, .flexibleSpace(), b_focused], animated: true)
				b_sort.menu = menu_sort()
				b_focused.menu = menu_focused()
				if id_activated == nil {
					dismiss(animated: true) // In case “confirm play” action sheet is presented.
				}
			case .select_albums(let ids_selected):
				navigationItem.setRightBarButtonItems([b_done], animated: true)
				setToolbarItems([b_sort, .flexibleSpace(), b_album_promote, .flexibleSpace(), b_album_demote, .flexibleSpace(), b_focused], animated: true)
				b_album_promote.isEnabled = !ids_selected.isEmpty
				b_album_demote.isEnabled = b_album_promote.isEnabled
				b_sort.menu = menu_sort() // In case it’s open.
				b_focused.menu = menu_focused()
			case .select_songs(let ids_selected):
				navigationItem.setRightBarButtonItems([b_done], animated: true)
				setToolbarItems([b_sort, .flexibleSpace(), b_song_promote, .flexibleSpace(), b_song_demote, .flexibleSpace(), b_focused], animated: true)
				b_song_promote.isEnabled = !ids_selected.isEmpty
				b_song_demote.isEnabled = b_song_promote.isEnabled
				b_sort.menu = menu_sort()
				b_focused.menu = menu_focused()
		}
	}
	
	@objc private func confirm_play(notification: Notification) {
		guard
			let id_activated = notification.object as? MPIDSong,
			let view_popover_anchor: UIView = { () -> UITableViewCell? in
				guard let row_activated = list_state.list_items.firstIndex(where: { switch $0 {
					case .album_mpid: return false
					case .song_mpid(let mpidSong): return mpidSong == id_activated
				}}) else { return nil }
				return tableView.cellForRow(at: IndexPath(row: row_activated, section: 0))
			}()
		else { return }
		
		list_state.select_mode = .view(id_activated) // The UI is clearer if we leave the row selected while the action sheet is onscreen. You must eventually deselect the row in every possible scenario after this moment.
		
		let action_sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		action_sheet.popoverPresentationController?.sourceView = view_popover_anchor
		action_sheet.addAction(
			UIAlertAction(title: InterfaceText.Start_Playing, style: .default) { _ in
				self.list_state.select_mode = .view(nil)
				Task {
					guard let lrSong = Librarian.lrSong_with(mpid: id_activated) else { return }
					
					await ApplicationMusicPlayer._shared?.play_now(
						lrSong.lrAlbum.lrSongs.map { $0.mpid },
						starting_at: id_activated)
				}
			}
			// I want to silence VoiceOver after you choose actions that start playback, but `UIAlertAction.accessibilityTraits = .startsMediaSession` doesn’t do it.)
		)
		action_sheet.addAction(
			UIAlertAction(title: InterfaceText.Cancel, style: .cancel) { _ in
				self.list_state.select_mode = .view(nil)
			}
		)
		present(action_sheet, animated: true)
	}
	
	// MARK: Editing
	
	private lazy var b_done = UIBarButtonItem(primaryAction: UIAction(title: InterfaceText.Done, image: UIImage(systemName: "checkmark.circle.fill")) { [weak self] _ in self?.end_selecting_animated() })
	private func end_selecting_animated() {
		withAnimation {
			self.list_state.select_mode = .view(nil)
		}
	}
	
	private let b_sort = UIBarButtonItem(title: InterfaceText.Sort, image: UIImage(systemName: "arrow.up.arrow.down.circle.fill")?.applying_hierarchical_tint())
	private let b_focused = UIBarButtonItem(title: InterfaceText.More, image: UIImage(systemName: "ellipsis.circle.fill")?.applying_hierarchical_tint())
	
	private lazy var b_album_promote = UIBarButtonItem(primaryAction: a_album_promote, menu: UIMenu(children: [a_album_float]))
	private lazy var b_album_demote = UIBarButtonItem(primaryAction: a_album_demote, menu: UIMenu(children: [a_album_sink]))
	
	private lazy var a_album_promote = UIAction(title: InterfaceText.Move_Up, image: UIImage.move_up.applying_hierarchical_tint()) { [weak self] _ in self?.promote_albums() }
	private lazy var a_album_demote = UIAction(title: InterfaceText.Move_Down, image: UIImage.move_down.applying_hierarchical_tint()) { [weak self] _ in self?.demote_albums() }
	private lazy var a_album_float = UIAction(title: InterfaceText.To_Top, image: UIImage.to_top) { [weak self] _ in self?.float_albums() }
	private lazy var a_album_sink = UIAction(title: InterfaceText.To_Bottom, image: UIImage.to_bottom) { [weak self] _ in self?.sink_albums() }
	
	private lazy var b_song_promote = UIBarButtonItem(primaryAction: a_song_promote, menu: UIMenu(children: [a_song_float]))
	private lazy var b_song_demote = UIBarButtonItem(primaryAction: a_song_demote, menu: UIMenu(children: [a_song_sink]))
	
	private lazy var a_song_promote = UIAction(title: InterfaceText.Move_Up, image: UIImage.move_up.applying_hierarchical_tint()) { [weak self] _ in self?.promote_songs() }
	private lazy var a_song_demote = UIAction(title: InterfaceText.Move_Down, image: UIImage.move_down.applying_hierarchical_tint()) { [weak self] _ in self?.demote_songs() }
	private lazy var a_song_float = UIAction(title: InterfaceText.To_Top, image: UIImage.to_top) { [weak self] _ in self?.float_songs() }
	private lazy var a_song_sink = UIAction(title: InterfaceText.To_Bottom, image: UIImage.to_bottom) { [weak self] _ in self?.sink_songs() }
	
	// MARK: Focused
	
	private func title_focused(always_songs: Bool) -> String {
		switch list_state.select_mode {
			case .select_albums(let ids_selected):
				if always_songs {
					let num_songs_selected: Int = list_state.album_mpids(with: ids_selected).reduce(into: 0) { songs_so_far, mpidAlbum_selected in
						guard let lrAlbum_selected = Librarian.lrAlbum_with(mpid: mpidAlbum_selected) else { return }
						songs_so_far += lrAlbum_selected.lrSongs.count
					}
					return InterfaceText.NUMBER_songs_selected(num_songs_selected)
				} else {
					return InterfaceText.NUMBER_albums_selected(list_state.album_mpids(with: ids_selected).count)
				}
			case .select_songs(let ids_selected):
				return InterfaceText.NUMBER_songs_selected(list_state.song_mpids(with: ids_selected).count)
			case .view:
				switch list_state.expansion {
					case .collapsed:
						if always_songs {
							let num_all_songs: Int = list_state.album_mpids().reduce(into: 0) { songs_so_far, mpidAlbum in
								guard let lrAlbum = Librarian.lrAlbum_with(mpid: mpidAlbum) else { return }
								songs_so_far += lrAlbum.lrSongs.count
							}
							return InterfaceText.NUMBER_songs(num_all_songs)
						} else {
							return InterfaceText.NUMBER_albums(list_state.album_mpids().count)
						}
					case .expanded:
						return InterfaceText.NUMBER_songs(list_state.song_mpids().count)
				}
		}
	}
	
	private func menu_sort() -> UIMenu? {
		return UIMenu(title: title_focused(always_songs: false), children: {
			switch list_state.expansion {
				case .collapsed: return menu_sections_album_sort
				case .expanded: return menu_sections_song_sort
			}
		}())
	}
	private func menu_focused() -> UIMenu {
		let menu_sections: [UIMenu] = [
			UIMenu(options: .displayInline, children: [
				UIDeferredMenuElement.uncached { [weak self] use in
					guard let self else { return }
					let ids_songs = ids_songs_focused()
					let action = UIAction(title: InterfaceText.Play, image: UIImage(systemName: "play")) { [weak self] _ in
						guard let self else { return }
						end_selecting_animated()
						Task {
							await ApplicationMusicPlayer._shared?.play_now(ids_songs)
						}
					}
					if ids_songs.isEmpty { action.attributes.formUnion(.disabled) }
					use([action])
				},
				UIDeferredMenuElement.uncached { [weak self] use in
					guard let self else { return }
					let ids_songs = ids_songs_focused()
					let action = UIAction(title: InterfaceText.Play_Later, image: UIImage(systemName: "text.line.last.and.arrowtriangle.forward")) { [weak self] _ in
						guard let self else { return }
						end_selecting_animated()
						Task {
							await ApplicationMusicPlayer._shared?.play_later(ids_songs)
						}
					}
					if ids_songs.isEmpty { action.attributes.formUnion(.disabled) }
					use([action])
				},
				UIDeferredMenuElement.uncached { [weak self] use in
					guard let self else { return }
					let ids_songs = ids_songs_focused()
					let action = UIAction(title: InterfaceText.Randomize(for: Locale.preferredLanguages), image: UIImage.random_die()) { [weak self] _ in
						guard let self else { return }
						end_selecting_animated()
						Task {
							await ApplicationMusicPlayer._shared?.play_now(ids_songs.in_any_other_order()) // Don’t trust `MusicPlayer.shuffleMode`. As of iOS 17.6 developer beta 3, if you happen to set the queue with the same contents, and set `shuffleMode = .songs` after calling `play`, not before, then the same song always plays the first time. Instead of continuing to test and comment about this ridiculous API, I’d rather shuffle the songs myself and turn off Apple Music’s shuffle mode.
						}
					}
					if ids_songs.count <= 1 { action.attributes.formUnion(.disabled) }
					use([action])
				},
			]),
		]
		return UIMenu(title: title_focused(always_songs: true), children: menu_sections)
	}
	
	private func ids_songs_focused() -> [MPIDSong] { // In display order.
		switch list_state.select_mode {
			case .select_albums(let ids_selected):
				var result: [MPIDSong] = []
				ids_selected.forEach {
					guard let lrAlbum_selected = Librarian.lrAlbum_with(mpid: $0) else { return }
					result.append(contentsOf: lrAlbum_selected.lrSongs.map { $0.mpid })
				}
				return result
			case .select_songs(let ids_selected):
				return list_state.song_mpids(with: ids_selected)
			case .view:
				switch list_state.expansion {
					case .collapsed:
						var result: [MPIDSong] = []
						list_state.album_mpids().forEach {
							guard let lrAlbum = Librarian.lrAlbum_with(mpid: $0) else { return }
							result.append(contentsOf: lrAlbum.lrSongs.map { $0.mpid })
						}
						return result
					case .expanded:
						return list_state.song_mpids()
				}
		}
	}
	
	// MARK: Sorting
	
	private lazy var menu_sections_album_sort: [UIMenu] = {
		let groups: [[AlbumOrder]] = [[.recently_added, .recently_released], [.reverse, .random]]
		return groups.map { album_orders in
			UIMenu(options: .displayInline, children: album_orders.map { order in
				UIDeferredMenuElement.uncached { [weak self] use in
					// Runs each time the button presents the menu
					guard let self else { return }
					let action = order.action { [weak self] in self?.sort_albums(by: order) }
					if !can_sort_albums(by: order) { action.attributes.formUnion(.disabled) } // You must do this inside `UIDeferredMenuElement.uncached`.
					use([action])
				}
			})
		}
	}()
	private func can_sort_albums(by album_order: AlbumOrder) -> Bool {
		guard ids_albums_to_sort().count >= 2 else { return false }
		switch list_state.select_mode {
			case .select_songs, .view: break
			case .select_albums(let ids_selected):
				let rs_selected = list_state.album_mpids().indices(where: {
					ids_selected.contains($0)
				})
				guard rs_selected.ranges.count <= 1 else { return false }
		}
		switch album_order {
			case .random, .reverse, .recently_added: return true
			case .recently_released: return ids_albums_to_sort().contains {
				nil != AppleLibrary.shared.albumInfo(mpid: $0)?._date_released
			}
		}
	}
	private lazy var menu_sections_song_sort: [UIMenu] = {
		let groups: [[SongOrder]] = [[.track], [.reverse, .random]]
		return groups.map { song_orders in
			UIMenu(options: .displayInline, children: song_orders.map { order in
				UIDeferredMenuElement.uncached { [weak self] use in
					guard let self else { return }
					let action = order.action { [weak self] in self?.sort_songs(by: order) }
					var enabling = true
					if ids_songs_to_sort().count <= 1 { enabling = false }
					switch list_state.select_mode {
						case .select_albums, .view: break
						case .select_songs(let ids_selected):
							let rs_selected = list_state.song_mpids().indices(where: {
								ids_selected.contains($0)
							})
							if rs_selected.ranges.count >= 2 { enabling = false }
					}
					if !enabling { action.attributes.formUnion(.disabled) }
					use([action])
				}
			})
		}
	}()
	
	private func sort_albums(by album_order: AlbumOrder) {
		Task {
			// TO DO: Tell `Librarian` to sort the albums, and save the changes.
//			album_order.reindex(albums_to_sort())
			
			list_state.refresh_items()
			list_state.signal_albums_reordered.toggle()
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
	private func sort_songs(by song_order: SongOrder) {
		Task {
			// TO DO: Tell `Librarian` to sort the songs, and save the changes.
			
			list_state.refresh_items()
			list_state.signal_songs_reordered.toggle()
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
	
	private func ids_albums_to_sort() -> [MPIDAlbum] {
		switch list_state.select_mode {
			case .select_songs: return []
			case .view: return list_state.album_mpids()
			case .select_albums(let ids_selected): return list_state.album_mpids(with: ids_selected)
		}
	}
	private func ids_songs_to_sort() -> [MPIDSong] {
		switch list_state.select_mode {
			case .select_albums: return []
			case .view: return list_state.song_mpids()
			case .select_songs(let ids_selected): return list_state.song_mpids(with: ids_selected)
		}
	}
	
	// MARK: Moving up and down
	
	private func promote_albums() {
		Task {
			guard case let .select_albums(ids_selected) = list_state.select_mode else { return }
			// TO DO: Tell `Librarian` to promote the selected albums, and save the changes.
			let _ = ids_selected
			
			list_state.refresh_items()
			list_state.signal_albums_reordered.toggle() // Refresh “select range” commands.
			NotificationCenter.default.post(name: AlbumListState.selection_changed, object: list_state) // We didn’t change which albums were selected, but we made them contiguous, which should enable sorting.
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
	private func promote_songs() {
		Task {
			guard case let .select_songs(ids_selected) = list_state.select_mode else { return }
			// TO DO: Tell `Librarian` to promote the selected songs within their album, and save the changes.
			let _ = ids_selected
			
			list_state.refresh_items()
			list_state.signal_songs_reordered.toggle()
			NotificationCenter.default.post(name: AlbumListState.selection_changed, object: list_state)
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
	
	private func demote_albums() {
		Task {
			// TO DO
			
			list_state.refresh_items()
			list_state.signal_albums_reordered.toggle()
			NotificationCenter.default.post(name: AlbumListState.selection_changed, object: list_state)
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
	private func demote_songs() {
		Task {
			// TO DO
			
			list_state.refresh_items()
			list_state.signal_songs_reordered.toggle()
			NotificationCenter.default.post(name: AlbumListState.selection_changed, object: list_state)
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
	
	// MARK: To top and bottom
	
	private func float_albums() {
		Task {
			// TO DO
			
			list_state.refresh_items()
			list_state.signal_albums_reordered.toggle()
			list_state.select_mode = .select_albums([])
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
	private func float_songs() {
		Task {
			// TO DO
			
			list_state.refresh_items()
			list_state.signal_songs_reordered.toggle()
			list_state.select_mode = .select_songs([])
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
	
	private func sink_albums() {
		Task {
			// TO DO
			
			list_state.refresh_items()
			list_state.signal_albums_reordered.toggle()
			list_state.select_mode = .select_albums([])
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
	private func sink_songs() {
		Task {
			// TO DO
			
			list_state.refresh_items()
			list_state.signal_songs_reordered.toggle()
			list_state.select_mode = .select_songs([])
			let _ = await apply_ids_rows(list_state.row_identifiers())
		}
	}
}
