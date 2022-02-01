//
//  PlayerView.swift
//  LavaRock
//
//  Created by h on 2022-01-31.
//

import SwiftUI

final class PlayerHostingController: UIHostingController<PlayerView> {
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder, rootView: PlayerView())
	}
}

struct PlayerView: View {
    var body: some View {
		NavigationView {
			Text("Controls")
			
			.navigationTitle("Player")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					Button("Shuffle") {}
				}
				ToolbarItem(placement: .navigationBarTrailing) {
					Button("Apply") {}
					.disabled(true)
				}
			}
			.toolbar {
				ToolbarItemGroup(placement: .bottomBar) {
					Button {
						
					} label: {
						Image(systemName: .SFPreviousTrack)
					}
					Spacer()
					Button {
						
					} label: {
						Image(systemName: .SFRewind)
					}
					Spacer()
					Button {
						
					} label: {
						Image(systemName: .SFPlay)
					}
					Spacer()
					Button {
						
					} label: {
						Image(systemName: .SFNextTrack)
					}
				}
			}
		}
    }
}

struct PlayerView_Previews: PreviewProvider {
    static var previews: some View {
        PlayerView()
    }
}
