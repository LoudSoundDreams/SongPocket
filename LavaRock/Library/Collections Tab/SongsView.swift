//
//  SongsView.swift
//  LavaRock
//
//  Created by h on 2020-06-26.
//  Copyright © 2020 h. All rights reserved.
//

// A SwiftUI replacement for SongsTVC.

import SwiftUI

struct SongsView: View {
	
//	let albumTitle: String
	
	init() {
		// Removes the blank cells below the List.
		UITableView.appearance().tableFooterView = UIView()
	}
	
	var body: some View {
		VStack {
			Image(systemName: "music.note")
				.resizable()
				.padding(.all, 0)
				.scaledToFit()
			List(/*@START_MENU_TOKEN@*/0 ..< 5/*@END_MENU_TOKEN@*/) { item in
				Text("Song")
			}
			.padding(.all, 0)
//			.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
		}
	}
}

struct SongsView_Previews: PreviewProvider {
    static var previews: some View {
		SongsView()
    }
}
