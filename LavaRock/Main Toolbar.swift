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
			ToolbarItem(placement: .bottomBar) { overflowMenu }
			ToolbarItem(placement: .bottomBar) { Spacer() }
			ToolbarItem(placement: .bottomBar) { jumpBackButton }
			ToolbarItem(placement: .bottomBar) { Spacer() }
			ToolbarItem(placement: .bottomBar) { playPauseButton }
			ToolbarItem(placement: .bottomBar) { Spacer() }
			ToolbarItem(placement: .bottomBar) { jumpForwardButton }
			ToolbarItem(placement: .bottomBar) { Spacer() }
			ToolbarItem(placement: .bottomBar) { nextButton }
		}
	}
	
	private var overflowMenu: some View {
		Menu {
		} label: {
			Image(systemName: "ellipsis.circle")
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
	
	private var nextButton: some View {
		Button {
		} label: {
			Image(systemName: "forward.end.circle")
		}
	}
}

struct MainToolbar_Previews: PreviewProvider {
    static var previews: some View {
		Color.clear.mainToolbar()
    }
}
