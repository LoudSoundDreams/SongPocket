// 2020-04-28

import UIKit
import SwiftUI
import MusicKit

@MainActor @Observable final class Exhibit {
	@ObservationIgnored fileprivate private(set) var artifacts: [Artifact]
	= Exhibit.uAlbums_fresh().map { .row_album($0) } { didSet {
		signal_artifacts.toggle()
	}}
	private(set) var signal_artifacts = false // Value is meaningless; we’re toggling this to tell SwiftUI to redraw views. (As of iOS 18.3 beta 1, setting the property to the same value again doesn’t trigger observers.)
	
	var focus: Focus = .covers { didSet {
		switch focus {
			case .spotlight:
				Global.shared.focus_is_spotlight = true
			case .covers, .expanded:
				Global.shared.focus_is_spotlight = false
		}
		NotificationCenter.default.post(name: Self.changed_focus, object: self)
	}}
	
	var selection: Selection = .view(nil) { didSet {
		NotificationCenter.default.post(name: Self.changed_selection, object: nil)
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
	@ObservationIgnored fileprivate static let changed_focus = Notification.Name("LR_Focus")
	
	enum Selection {
		case view(USong?)
		case mode_albums(Set<UAlbum>)
		case mode_songs(Set<USong>)
	}
	@ObservationIgnored fileprivate static let changed_selection = Notification.Name("LR_Selection")
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
	
	@ObservationIgnored fileprivate var rowIDs: [AnyHashable] { artifacts }
	fileprivate func refresh_artifacts() {
		artifacts = {
			let uAlbums = Self.uAlbums_fresh()
			switch focus {
				case .covers:
					return uAlbums.map { .row_album($0) }
					
				case .spotlight(let uA_spotlighted):
					// If we removed the spotlighted album, change focus to covers.
					if nil == uAlbums.firstIndex(where: { $0 == uA_spotlighted }) {
						focus = .covers
					}
					return uAlbums.map { .row_album($0) }
					
				case .expanded(let uA_expanded):
					// If we removed the expanded album, change focus to covers.
					guard
						let i_expanded = uAlbums.firstIndex(where: { $0 == uA_expanded }),
						let album_expanded = Librarian.album_with_uAlbum[uA_expanded]?.referencee
					else {
						focus = .covers
						return uAlbums.map { .row_album($0) }
					}
					
					let uSongs_inline: [Artifact] = album_expanded.uSongs.map { .row_song($0) }
					var result: [Artifact] = uAlbums.map { .row_album($0) }
					result.insert(contentsOf: uSongs_inline, at: i_expanded + 1)
					return result
			}
		}()
		
		// In case we removed items the user was doing something with.
		switch selection {
			case .view(let uS_activated):
				if let uS_activated, uSongs(with: [uS_activated]).isEmpty {
					selection = .view(nil)
				}
			case .mode_albums(let old_selected):
				let selectable = Set(uAlbums(with: old_selected))
				if old_selected != selectable {
					selection = .mode_albums(selectable)
				}
			case .mode_songs(let old_selected):
				guard !uSongs().isEmpty else {
					selection = .view(nil)
					break
				}
				let selectable = Set(uSongs(with: old_selected))
				if old_selected != selectable{
					selection = .mode_songs(selectable)
				}
		}
	}
	private static func uAlbums_fresh() -> [UAlbum] {
		guard MusicAuthorization.currentStatus == .authorized
		else { return [] } // Don’t show any albums; show a placeholder.
		return Librarian.the_albums.map { $0.uAlbum }
	}
	
	fileprivate func uAlbums(with chosen: Set<UAlbum>? = nil) -> [UAlbum] {
		return artifacts.compactMap { switch $0 { // `compactMap` rather than `filter` because we’re returning a different type.
			case .row_song: return nil
			case .row_album(let uAlbum):
				guard let chosen else { return uAlbum }
				guard chosen.contains(uAlbum) else { return nil }
				return uAlbum
		}}
	}
	fileprivate func uSongs(with chosen: Set<USong>? = nil) -> [USong] {
		return artifacts.compactMap { switch $0 {
			case .row_album: return nil
			case .row_song(let uSong):
				guard let chosen else { return uSong }
				guard chosen.contains(uSong) else { return nil }
				return uSong
		}}
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
		let old_selected: Set<UAlbum> = {
			switch selection {
				case .mode_songs, .view: return []
				case .mode_albums(let uAs_selected): return uAs_selected
			}
		}()
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
			case .mode_songs: break
			case .view:
				withAnimation {
					selection = .mode_albums(new_selected)
				}
			case .mode_albums:
				selection = .mode_albums(new_selected)
		}
	}
	func change_song_range(from uS_anchor: USong, forward: Bool) {
		guard let i_anchor = uSongs().firstIndex(where: { $0 == uS_anchor })
		else { return }
		let old_selected: Set<USong> = {
			switch selection {
				case .mode_albums, .view: return []
				case .mode_songs(let uAs_selected): return uAs_selected
			}
		}()
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
			case .mode_albums: break
			case .view:
				withAnimation {
					selection = .mode_songs(new_selected)
				}
			case .mode_songs:
				selection = .mode_songs(new_selected)
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
		
		view.backgroundColor = .clear
		tableView.separatorStyle = .none
		b_sort.preferredMenuElementOrder = .fixed
		b_scope.preferredMenuElementOrder = .fixed
		reflect_selection()
		
		NotificationCenter.default.addObserver(self, selector: #selector(refresh_rows), name: AppleLibrary.merged, object: nil)
		Remote.shared.weak_exhibitTVC = self
		NotificationCenter.default.addObserver(self, selector: #selector(reflect_focus), name: Exhibit.changed_focus, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(confirm_play), name: SongRow.confirm_play_uSong, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(reflect_selection), name: Exhibit.changed_selection, object: nil)
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
			// `adjustedContentInset` is what matters because it determines the scrolling limits, but we can’t set it directly. We can set `contentInset`, but UIKit adds safe area insets to that.
			// As of iOS 18.3 RC, don’t use `contentInsetAdjustmentBehavior = .never`, because it breaks row sizing.
			var gutter: CGFloat = .zero
			gutter -= view.safeAreaInsets.top // Offsets how `UIScrollView` interprets `contentInset`. Applying it now should make it effectively zero.
			gutter += (size_frame.height / 2)
			gutter -= (exhibit.length_artwork / 2)
			
			let top = gutter.rounded(.down) // As of iOS 18.3 developer beta 3, a non-integer value prevents you from rapidly expanding and collapsing albums.
			let bottom = {
				if WorkingOn.toolbar {
					return gutter.rounded(.up)
				} else { return .zero }
			}()
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
			if exhibit.artifacts.isEmpty {
				return UIHostingConfiguration {
					PlaceholderMusicNote()
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
	
	@objc private func refresh_rows() {
		Task {
			exhibit.refresh_artifacts()
			b_sort.menu = menu_sort()
			b_scope.menu = menu_scope()
			let _ = await apply_rowIDs(exhibit.rowIDs)
		}
	}
	
	func go_to_album() {
		guard
			let uSong_current = ApplicationMusicPlayer.uSong_current,
			let album_target = Librarian.album_containing_uSong[uSong_current]?.referencee
		else { return }
		exhibit.focus = .spotlight(album_target.uAlbum)
	}
	
	@objc private func reflect_focus() {
		switch exhibit.focus {
			case .covers:
				Task {
					if !WorkingOn.toolbar {
						navigationController?.setToolbarHidden(false, animated: true)
					}
					exhibit.refresh_artifacts() // Immediately proceed to update the table view; don’t wait until a separate `Task`. As of iOS 17.6 developer beta 2, `UITableView` has a bug where it might call `cellForRowAt` with invalidly large `IndexPath`s: it’s trying to draw subsequent rows after we change a cell’s height in a `UIHostingConfiguration`, but forgetting to call `numberOfRowsInSection` first.
					b_sort.menu = menu_sort()
					b_scope.menu = menu_scope()
					let _ = await apply_rowIDs(exhibit.rowIDs)
				}
			case .expanded(let uA_to_expand):
				Task {
					if !WorkingOn.toolbar {
						navigationController?.setToolbarHidden(false, animated: true)
					}
					exhibit.refresh_artifacts()
					b_sort.menu = menu_sort()
					b_scope.menu = menu_scope()
					let _ = await apply_rowIDs(exhibit.rowIDs, running_before_continuation: {
						if
							let row_target: Int = self.exhibit.artifacts.firstIndex(where: { switch $0 {
								case .row_song: return false
								case .row_album(let uAlbum): return uAlbum == uA_to_expand
							}})
						{
							self.tableView.scrollToRow(at: IndexPath(row: row_target, section: 0), at: .top, animated: true)
						}
					})
				}
			case .spotlight(let uA_to_spotlight):
				Task {
					if !WorkingOn.toolbar {
						navigationController?.setToolbarHidden(true, animated: true)
					}
					exhibit.refresh_artifacts()
					b_sort.menu = menu_sort()
					b_scope.menu = menu_scope()
					let _ = await apply_rowIDs(exhibit.rowIDs, running_before_continuation: {
						if
							let row_target: Int = self.exhibit.artifacts.firstIndex(where: { switch $0 {
								case .row_song: return false
								case .row_album(let uAlbum): return uAlbum == uA_to_spotlight
							}})
						{
							self.tableView.scrollToRow(at: IndexPath(row: row_target, section: 0), at: .top, animated: true)
						}
					})
				}
		}
	}
	
	@objc private func reflect_selection() {
		switch exhibit.selection {
			case .view(let uS_activated):
				setToolbarItems([b_sort, .flexibleSpace(), Remote.shared.b_remote, .flexibleSpace(), b_scope], animated: true)
				b_sort.menu = menu_sort()
				b_scope.menu = menu_scope()
				b_scope.image = image_scope
				if uS_activated == nil {
					dismiss(animated: true) // In case “confirm play” action sheet is presented. 2do: Replace with SwiftUI.
				}
			case .mode_albums(let uAs_selected):
				setToolbarItems([b_sort, .flexibleSpace(), b_album_promote, .flexibleSpace(), b_album_demote, .flexibleSpace(), b_scope], animated: true)
				b_album_promote.isEnabled = !uAs_selected.isEmpty
				b_album_demote.isEnabled = b_album_promote.isEnabled
				b_sort.menu = menu_sort() // In case it’s open.
				b_scope.menu = menu_scope()
				b_scope.image = image_scope_highlighted
			case .mode_songs(let uSs_selected):
				setToolbarItems([b_sort, .flexibleSpace(), b_song_promote, .flexibleSpace(), b_song_demote, .flexibleSpace(), b_scope], animated: true)
				b_song_promote.isEnabled = !uSs_selected.isEmpty
				b_song_demote.isEnabled = b_song_promote.isEnabled
				b_sort.menu = menu_sort()
				b_scope.menu = menu_scope()
				b_scope.image = image_scope_highlighted
		}
	}
	
	@objc private func confirm_play(notification: Notification) {
		guard
			let uSong_activated = notification.object as? USong,
			let view_popover_anchor: UIView = { () -> UITableViewCell? in
				guard let row_activated = exhibit.artifacts.firstIndex(where: { switch $0 {
					case .row_album: return false
					case .row_song(let uSong): return uSong == uSong_activated
				}}) else { return nil }
				return tableView.cellForRow(at: IndexPath(row: row_activated, section: 0))
			}()
		else { return }
		
		exhibit.selection = .view(uSong_activated) // The UI is clearer if we leave the row selected while the action sheet is onscreen. You must eventually deselect the row in every possible scenario after this moment.
		
		let action_sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		action_sheet.popoverPresentationController?.sourceView = view_popover_anchor
		action_sheet.addAction(
			UIAlertAction(title: InterfaceText.Start_Playing, style: .default) { _ in
				self.exhibit.selection = .view(nil)
				Task {
					guard let album_chosen = Librarian.album_containing_uSong[uSong_activated]?.referencee else { return }
					await ApplicationMusicPlayer._shared?.play_now(
						album_chosen.uSongs,
						starting_at: uSong_activated)
				}
			}
			// I want to silence VoiceOver after you choose actions that start playback, but `UIAlertAction.accessibilityTraits = .startsMediaSession` doesn’t do it.)
		)
		action_sheet.addAction(
			UIAlertAction(title: InterfaceText.Cancel, style: .cancel) { _ in
				self.exhibit.selection = .view(nil)
			}
		)
		present(action_sheet, animated: true)
	}
	
	// MARK: Editing
	
	private lazy var a_done = UIAction(title: InterfaceText.Done, image: UIImage(systemName: "checkmark.circle.fill")) { [weak self] _ in self?.end_selecting_animated() }
	private func end_selecting_animated() {
		withAnimation {
			self.exhibit.selection = .view(nil)
		}
	}
	
	private let b_sort = UIBarButtonItem(title: InterfaceText.Sort, image: UIImage(systemName: "arrow.up.arrow.down.circle.fill")?.applying_hierarchical_tint())
	private lazy var b_scope = UIBarButtonItem(title: InterfaceText.More)
	private lazy var image_scope = image_scope_highlighted?.applying_hierarchical_tint()
	private let image_scope_highlighted = UIImage(systemName: "ellipsis.circle.fill")
	
	private lazy var b_album_promote = UIBarButtonItem(primaryAction: a_album_promote, menu: UIMenu(children: [a_album_float]))
	private lazy var b_album_demote = UIBarButtonItem(primaryAction: a_album_demote, menu: UIMenu(children: [a_album_sink]))
	
	private lazy var b_song_promote = UIBarButtonItem(primaryAction: a_song_promote, menu: UIMenu(children: [a_song_float]))
	private lazy var b_song_demote = UIBarButtonItem(primaryAction: a_song_demote, menu: UIMenu(children: [a_song_sink]))
	
	private lazy var a_album_promote = UIAction(title: InterfaceText.Move_Up, image: UIImage.move_up.applying_hierarchical_tint()) { [weak self] _ in self?.promote_albums() }
	private lazy var a_album_demote = UIAction(title: InterfaceText.Move_Down, image: UIImage.move_down.applying_hierarchical_tint()) { [weak self] _ in self?.demote_albums() }
	private lazy var a_album_float = UIAction(title: InterfaceText.To_Top, image: UIImage.to_top) { [weak self] _ in self?.float_albums() }
	private lazy var a_album_sink = UIAction(title: InterfaceText.To_Bottom, image: UIImage.to_bottom) { [weak self] _ in self?.sink_albums() }
	
	private lazy var a_song_promote = UIAction(title: InterfaceText.Move_Up, image: UIImage.move_up.applying_hierarchical_tint()) { [weak self] _ in self?.promote_songs() }
	private lazy var a_song_demote = UIAction(title: InterfaceText.Move_Down, image: UIImage.move_down.applying_hierarchical_tint()) { [weak self] _ in self?.demote_songs() }
	private lazy var a_song_float = UIAction(title: InterfaceText.To_Top, image: UIImage.to_top) { [weak self] _ in self?.float_songs() }
	private lazy var a_song_sink = UIAction(title: InterfaceText.To_Bottom, image: UIImage.to_bottom) { [weak self] _ in self?.sink_songs() }
	
	// MARK: Scope
	
	private func menu_scope() -> UIMenu {
		var menu_children: [UIMenu] = []
		switch exhibit.selection {
			case .view: break
			case .mode_albums, .mode_songs:
				menu_children.append(UIMenu(
					options: .displayInline,
					children: [
						a_done,
					]
				))
		}
		menu_children.append(UIMenu(
			options: .displayInline,
			children: [
				UIDeferredMenuElement.uncached { [weak self] use in
					guard let self else { return }
					let uSongs = uSongs_scope()
					let action = UIAction(title: InterfaceText.Play, image: UIImage(systemName: "play")) { [weak self] _ in
						guard let self else { return }
						end_selecting_animated()
						Task {
							await ApplicationMusicPlayer._shared?.play_now(uSongs)
						}
					}
					if uSongs.isEmpty { action.attributes.formUnion(.disabled) }
					use([action])
				},
				UIDeferredMenuElement.uncached { [weak self] use in
					guard let self else { return }
					let uSongs = uSongs_scope()
					let action = UIAction(title: InterfaceText.Randomize(for_localeLanguageIdentifiers: Locale.preferredLanguages), image: UIImage.random_die()) { [weak self] _ in
						guard let self else { return }
						end_selecting_animated()
						Task {
							// Don’t trust `MusicPlayer.shuffleMode`. As of iOS 17.6 developer beta 3, if you happen to set the queue with the same contents, and set `shuffleMode = .songs` after calling `play`, not before, then the same song always plays the first time. Instead of continuing to test and comment about this ridiculous API, I’d rather shuffle the songs myself and turn off Apple Music’s shuffle mode.
							let uSongs_reordered = uSongs.in_any_other_order { $0 == $1 }
							await ApplicationMusicPlayer._shared?.play_now(uSongs_reordered)
						}
					}
					if uSongs.count <= 1 { action.attributes.formUnion(.disabled) }
					use([action])
				},
				UIDeferredMenuElement.uncached { [weak self] use in
					guard let self else { return }
					let uSongs = uSongs_scope()
					let action = UIAction(title: InterfaceText.Add_to_Queue, image: UIImage(systemName: "text.line.last.and.arrowtriangle.forward")) { [weak self] _ in
						guard let self else { return }
						end_selecting_animated()
						Task {
							await ApplicationMusicPlayer._shared?.play_later(uSongs)
						}
					}
					if uSongs.isEmpty { action.attributes.formUnion(.disabled) }
					use([action])
				},
			]
		))
		return UIMenu(children: menu_children)
	}
	private func uSongs_scope() -> [USong] { // In display order.
		switch exhibit.selection {
			case .mode_albums(let uAs_selected):
				var result: [USong] = []
				exhibit.uAlbums(with: uAs_selected).forEach { uAlbum in // Order matters.
					guard let lrAlbum = Librarian.album_with_uAlbum[uAlbum]?.referencee else { return }
					result.append(contentsOf: lrAlbum.uSongs)
				}
				return result
			case .mode_songs(let uSs_selected):
				return exhibit.uSongs(with: uSs_selected)
			case .view:
				switch exhibit.focus {
					case .spotlight: return []
					case .covers:
						var result: [USong] = []
						exhibit.uAlbums().forEach { uAlbum in
							guard let lrAlbum = Librarian.album_with_uAlbum[uAlbum]?.referencee else { return }
							result.append(contentsOf: lrAlbum.uSongs)
						}
						return result
					case .expanded:
						return exhibit.uSongs()
				}
		}
	}
	
	// MARK: Sorting
	
	// Including sort commands depends on the type to sort: albums or songs.
	// Enabling sort commands depends on the items to sort:
	// • 2 or more
	// • Contiguous
	// • With useful data
	private func menu_sort() -> UIMenu? {
		return UIMenu(
			children: {
				switch exhibit.focus {
					case .spotlight: return []
					case .covers: return menu_sections_album_sort
					case .expanded: return menu_sections_song_sort
				}
			}()
		)
	}
	
	private lazy var menu_sections_album_sort: [UIMenu] = {
		let groups: [[AlbumOrder]] = [[.recently_added, .recently_released], [.reverse, .random]]
		return groups.map { albumOrders in
			UIMenu(options: .displayInline, children: albumOrders.map { order in
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
		let uAlbums = uAlbums_to_sort()
		guard uAlbums.count >= 2 else { return false }
		
		switch exhibit.selection {
			case .mode_songs, .view: break
			case .mode_albums(let uAs_selected):
				let rs_selected = exhibit.uAlbums().indices(where: { uAlbum in
					uAs_selected.contains(uAlbum)
				})
				guard rs_selected.ranges.count <= 1 else { return false }
		}
		
		switch album_order {
			case .random, .reverse, .recently_added: return true
			case .recently_released: return uAlbums.contains {
				nil != AppleLibrary.shared.albumInfo(uAlbum: $0)?._date_released
			}
		}
	}
	
	private lazy var menu_sections_song_sort: [UIMenu] = {
		let groups: [[SongOrder]] = [[.track], [.reverse, .random]]
		return groups.map { songOrders in
			UIMenu(options: .displayInline, children: songOrders.map { order in
				UIDeferredMenuElement.uncached { [weak self] use in
					guard let self else { return }
					let action = order.action { [weak self] in self?.sort_songs(by: order) }
					var enabling = true
					
					if uSongs_to_sort().count <= 1 { enabling = false }
					
					switch exhibit.selection {
						case .mode_albums, .view: break
						case .mode_songs(let uSs_selected):
							let rs_selected = exhibit.uSongs().indices(where: { uSong in
								uSs_selected.contains(uSong)
							})
							if rs_selected.ranges.count >= 2 { enabling = false }
					}
					
					if !enabling { action.attributes.formUnion(.disabled) }
					use([action])
				}
			})
		}
	}()
	
	private func sort_albums(by albumOrder: AlbumOrder) {
		Task {
			Librarian.sort_albums(uAlbums_to_sort(), by: albumOrder)
			Librarian.save()
			
			exhibit.refresh_artifacts()
			let _ = await apply_rowIDs(exhibit.rowIDs)
		}
	}
	private func sort_songs(by songOrder: SongOrder) {
		Task {
			Librarian.sort_songs(uSongs_to_sort(), by: songOrder)
			Librarian.save()
			
			exhibit.refresh_artifacts()
			let _ = await apply_rowIDs(exhibit.rowIDs)
		}
	}
	
	private func uAlbums_to_sort() -> Set<UAlbum> {
		switch exhibit.selection {
			case .mode_songs: return []
			case .view: return Set(exhibit.uAlbums())
			case .mode_albums(let uAs_selected): return uAs_selected
		}
	}
	private func uSongs_to_sort() -> Set<USong> {
		switch exhibit.selection {
			case .mode_albums: return []
			case .view: return Set(exhibit.uSongs())
			case .mode_songs(let uSs_selected): return uSs_selected
		}
	}
	
	// MARK: Moving up and down
	
	private func promote_albums() {
		Task {
			guard case let .mode_albums(uAs_selected) = exhibit.selection else { return }
			Librarian.promote_albums(uAs_selected, to_limit: false)
			Librarian.save()
			
			exhibit.refresh_artifacts()
			NotificationCenter.default.post(name: Exhibit.changed_selection, object: nil) // We didn’t change which albums were selected, but we made them contiguous, which should enable sorting.
			let _ = await apply_rowIDs(exhibit.rowIDs)
		}
	}
	private func promote_songs() {
		Task {
			guard case let .mode_songs(uSs_selected) = exhibit.selection else { return }
			Librarian.promote_songs(uSs_selected, to_limit: false)
			Librarian.save()
			
			exhibit.refresh_artifacts()
			NotificationCenter.default.post(name: Exhibit.changed_selection, object: nil)
			let _ = await apply_rowIDs(exhibit.rowIDs)
		}
	}
	
	private func demote_albums() {
		Task {
			guard case let .mode_albums(uAs_selected) = exhibit.selection else { return }
			Librarian.demote_albums(uAs_selected, to_limit: false)
			Librarian.save()
			
			exhibit.refresh_artifacts()
			NotificationCenter.default.post(name: Exhibit.changed_selection, object: nil)
			let _ = await apply_rowIDs(exhibit.rowIDs)
		}
	}
	private func demote_songs() {
		Task {
			guard case let .mode_songs(uSs_selected) = exhibit.selection else { return }
			Librarian.demote_songs(uSs_selected, to_limit: false)
			Librarian.save()
			
			exhibit.refresh_artifacts()
			NotificationCenter.default.post(name: Exhibit.changed_selection, object: nil)
			let _ = await apply_rowIDs(exhibit.rowIDs)
		}
	}
	
	// MARK: To top and bottom
	
	private func float_albums() {
		Task {
			guard case let .mode_albums(uAs_selected) = exhibit.selection else { return }
			Librarian.promote_albums(uAs_selected, to_limit: true)
			Librarian.save()
			
			exhibit.refresh_artifacts()
			exhibit.selection = .mode_albums([])
			let _ = await apply_rowIDs(exhibit.rowIDs)
		}
	}
	private func float_songs() {
		Task {
			guard case let .mode_songs(uSs_selected) = exhibit.selection else { return }
			Librarian.promote_songs(uSs_selected, to_limit: true)
			Librarian.save()
			
			exhibit.refresh_artifacts()
			exhibit.selection = .mode_songs([])
			let _ = await apply_rowIDs(exhibit.rowIDs)
		}
	}
	
	private func sink_albums() {
		Task {
			guard case let .mode_albums(uAs_selected) = exhibit.selection else { return }
			Librarian.demote_albums(uAs_selected, to_limit: true)
			Librarian.save()
			
			exhibit.refresh_artifacts()
			exhibit.selection = .mode_albums([])
			let _ = await apply_rowIDs(exhibit.rowIDs)
		}
	}
	private func sink_songs() {
		Task {
			guard case let .mode_songs(uSs_selected) = exhibit.selection else { return }
			Librarian.demote_songs(uSs_selected, to_limit: true)
			Librarian.save()
			
			exhibit.refresh_artifacts()
			exhibit.selection = .mode_songs([])
			let _ = await apply_rowIDs(exhibit.rowIDs)
		}
	}
}
