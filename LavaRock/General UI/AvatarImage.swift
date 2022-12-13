//
//  AvatarImage.swift
//  LavaRock
//
//  Created by h on 2022-12-12.
//

import SwiftUI

struct AvatarImage: View {
	var body: some View {
		Image(systemName: "tortoise")
			.font(.body)
			.dynamicTypeSize(...DynamicTypeSize.xxxLarge)
			.foregroundColor(.accentColor)
	}
}
