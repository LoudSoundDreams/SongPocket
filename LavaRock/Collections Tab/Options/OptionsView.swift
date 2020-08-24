//
//  OptionsView.swift
//  LavaRock
//
//  Created by h on 2020-07-28.
//
/*
import SwiftUI
import UIKit

struct OptionsView: View {
//	@AppStorage("accentColorName") private var selectedColorName = "Blue" // @AppStorage isn't the right solution, because we don't want to create a default value here.
//	@State private var selectedColorName = UserDefaults.standard.value(forKey: "accentColorName") as? String // Doesn't automatically get invalidated when we change UserDefaults; we need to update selectedColorName manually.
	let window: UIWindow
	let dismissModalHostingControllerHostingThisSwiftUIView: (() -> ())
	
	var body: some View {
		NavigationView {
			if #available(iOS 14.0, *) {
				Form {
					Section(header: Text("Accent Color")) {
						ForEach(AccentColorManager.accentColorTuples, id: \.0) { (rowColorName, rowUIColor) in
							HStack {
								Text(rowColorName)
									.foregroundColor(Color(rowUIColor))
								Spacer()
								if rowUIColor == window.tintColor {
									Image(systemName: "checkmark") // Should be bold
										.foregroundColor(Color(rowUIColor))
								}
							}
							.onTapGesture { // Only works if you tap on the text
								DispatchQueue.global().async {
									UserDefaults.standard.set(rowColorName, forKey: "accentColorName")
								}
//								selectedColorName = rowColorName // You shouldn't have to do this manually
								window.tintColor = rowUIColor
								dismissModalHostingControllerHostingThisSwiftUIView()
							}
						}
					}
				}
				.navigationTitle("Options")
				.navigationBarTitleDisplayMode(.inline)
				.toolbar(items: {
					ToolbarItem(placement: .navigationBarTrailing) {
						Button("Done", action: { // Should be bold
							dismissModalHostingControllerHostingThisSwiftUIView()
						})
					}
				} )
			} else { // iOS 13 and earlier
				Form {
					Section(header: Text("Accent Color")) {
						ForEach(AccentColorManager.accentColorTuples, id: \.0) { (rowColorName, rowUIColor) in
							HStack {
								Text(rowColorName)
									.foregroundColor(Color(rowUIColor))
								Spacer()
								if rowUIColor == window.tintColor {
									Image(systemName: "checkmark") // Should be bold
										.foregroundColor(Color(rowUIColor))
								}
							}
							.onTapGesture { // Only works if you tap on the text
								DispatchQueue.global().async {
									UserDefaults.standard.set(rowColorName, forKey: "accentColorName")
								}
//								selectedColorName = rowColorName // You shouldn't do this manually
								window.tintColor = rowUIColor
								dismissModalHostingControllerHostingThisSwiftUIView()
							}
						}
					}
				}
				.navigationBarTitle("Options", displayMode: .inline)
				.navigationBarItems(
					trailing: Button("Done", action: { // Should be bold
						dismissModalHostingControllerHostingThisSwiftUIView()
					} )
				)
			}
		}
    }
}

//struct OptionsView_Previews: PreviewProvider {
//    static var previews: some View {
//		OptionsView()
//    }
//}
*/
