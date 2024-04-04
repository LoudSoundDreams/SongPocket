// 2020-05-04

import UIKit
import SwiftUI

final class CollectionsTVC: LibraryTVC {
	// MARK: - Table view
	override func tableView(
		_ tableView: UITableView, numberOfRowsInSection section: Int
	)-> Int {
		return 1
	}
	
	override func tableView(
		_ tableView: UITableView, cellForRowAt indexPath: IndexPath
	) -> UITableViewCell {
		// The cell in the storyboard is completely default except for the reuse identifier.
		let cell = tableView.dequeueReusableCell(withIdentifier: "Folder", for: indexPath)
		cell.contentConfiguration = UIHostingConfiguration {
			Text("folder")
		}.margins(.all, .zero)
		return cell
	}
}
