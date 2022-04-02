//
//  TransportBar.swift
//  LavaRock
//
//  Created by h on 2022-04-02.
//

import SwiftUI

struct TransportBar: View {
    var body: some View {
		HStack {
			Button {
				
			} label: {
				Image(systemName: "backward.end")
					.font(.system(size: 30))
			}
			.padding()
			
			Spacer()
			
			Button {
				
			} label: {
				Image(systemName: "gobackward.10")
					.font(.system(size: 30))
			}
			.padding()
			
			Spacer()
			
			Button {
				
			} label: {
				Image(systemName: "play.circle")
					.font(.system(size: 48))
			}
			.padding()
			
			Spacer()
			
			Button {
				
			} label: {
				Image(systemName: "goforward.10")
					.font(.system(size: 30))
			}
			.padding()
			
			Spacer()
			
			Button {
				
			} label: {
				Image(systemName: "forward.end")
					.font(.system(size: 30))
			}
			.padding()
		}
    }
}

struct TransportBar_Previews: PreviewProvider {
    static var previews: some View {
        TransportBar()
    }
}
