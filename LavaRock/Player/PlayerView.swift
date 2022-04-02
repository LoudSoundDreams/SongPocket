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
			VStack {
				
				Spacer()
				Text("queue")
				Spacer()
				
				TransportBar()
				
				Spacer()
			}
			.navigationTitle("Queue")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .navigationBarLeading) {
					Button("Shuffle") {}
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
