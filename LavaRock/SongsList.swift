//
//  SongsList.swift
//  LavaRock
//
//  Created by h on 2020-06-26.
//  Copyright © 2020 h. All rights reserved.
//

import SwiftUI

struct SongsList: View {
//	let albumTitle: String
	
	// Removes the blank cells below the List.
	init() {
		UITableView.appearance().tableFooterView = UIView()
	}
	
	var body: some View {
		List(/*@START_MENU_TOKEN@*/0 ..< 5/*@END_MENU_TOKEN@*/) { item in
			Text("Song")
		}
//	.navigationBarItems(trailing: EditButton()) // As of iOS 13.5.1, doesn't appear until the show segue animation finishes, and removes the title in the navigation bar.
	}
}

struct SongsView_Previews: PreviewProvider {
    static var previews: some View {
		SongsList()
    }
}
