// 2020-04-15

import UIKit

class LibraryTVC: UITableViewController {
	final var idsRowsOnscreen: [AnyHashable] = []
	// Returns a boolean indicating whether it’s safe for the caller to continue running code. If it’s `false`, table view animations are already in progress from an earlier call of this method, and callers could disrupt those animations by running further code.
	// Returns after completing the animations for moving rows, and also deselects all rows and refreshes editing buttons.
	final func applyIDsRows(
		_ idsNew: [AnyHashable],
		runningBeforeContinuation: (() -> Void)? = nil
	) async -> Bool {
		await withCheckedContinuation { continuation in
			_applyIDsRows(idsNew) { shouldContinue in
				continuation.resume(returning: shouldContinue)
			}
			runningBeforeContinuation?()
		}
	}
	private func _applyIDsRows(
		_ idsNew: [AnyHashable],
		completionIfShouldRun: @escaping (Bool) -> Void // We used to sometimes not run this completion handler, but if you wrapped this method in `withCheckedContinuation` and resumed the continuation during that handler, that leaked `CheckedContinuation`. Hence, this method always runs the completion handler, and callers should pass a completion handler that returns immediately if the parameter is `false`.
	) {
		animationsInProgress += 1
		let idsOld = idsRowsOnscreen
		idsRowsOnscreen = idsNew
		tableView.performUpdatesFromRowIdentifiers(old: idsOld, new: idsNew) {
			// Completion handler
			self.animationsInProgress -= 1
			if self.animationsInProgress == 0 { // If we call `performBatchUpdates` multiple times quickly, executions after the first one can beat the first one to the completion closure, because they don’t have to animate any rows. Here, we wait for the animations to finish before we run the completion closure (once).
				completionIfShouldRun(true)
			} else {
				completionIfShouldRun(false)
			}
		}
	}
	private var animationsInProgress = 0
}
