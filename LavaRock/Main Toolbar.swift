//
//  Main Toolbar.swift
//  LavaRock
//
//  Created by h on 2023-05-14.
//

import SwiftUI

extension View {
	func mainToolbar() -> some View {
		toolbar {
			ToolbarItem(placement: .bottomBar) { selectButton }
			ToolbarItem(placement: .bottomBar) { Spacer() }
			ToolbarItem(placement: .bottomBar) { jumpBackButton }
			ToolbarItem(placement: .bottomBar) { Spacer() }
			ToolbarItem(placement: .bottomBar) { playPauseButton }
			ToolbarItem(placement: .bottomBar) { Spacer() }
			ToolbarItem(placement: .bottomBar) { jumpForwardButton }
			ToolbarItem(placement: .bottomBar) { Spacer() }
			ToolbarItem(placement: .bottomBar) { overflowButton }
		}
	}
	
	private var selectButton: some View {
		Button {
			print("user tapped Select")
		} label: {
			Image(systemName: "checkmark.circle")
		}
	}
	
	private var jumpBackButton: some View {
		Button {
		} label: {
			Image(systemName: "gobackward.15")
		}
	}
	
	private var playPauseButton: some View {
		Button {
		} label: {
			Image(systemName: "play.circle")
		}
	}
	
	private var jumpForwardButton: some View {
		Button {
		} label: {
			Image(systemName: "goforward.15")
		}
	}
	
	private var overflowButton: some View {
		Menu {
		} label: {
			Image(systemName: "ellipsis.circle")
		}
	}
}

struct MainToolbar_Previews: PreviewProvider {
    static var previews: some View {
		Color.clear.mainToolbar()
    }
}
