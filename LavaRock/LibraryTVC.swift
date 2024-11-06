// 2020-04-15

import UIKit

class LibraryTVC: UITableViewController {
	final var ids_rows_onscreen: [AnyHashable] = []
	// Returns a boolean indicating whether it’s safe for the caller to continue running code. If it’s `false`, table view animations are already in progress from an earlier call of this method, and callers could disrupt those animations by running further code.
	// Returns after completing the animations for moving rows, and also deselects all rows and refreshes editing buttons.
	final func apply_ids_rows(
		_ idsNew: [AnyHashable],
		running_before_continuation: (() -> Void)? = nil
	) async -> Bool {
		await withCheckedContinuation { continuation in
			_apply_ids_rows(idsNew) { should_continue in
				continuation.resume(returning: should_continue)
			}
			running_before_continuation?()
		}
	}
	private func _apply_ids_rows(
		_ new_ids: [AnyHashable],
		completion_if_should_run: @escaping (Bool) -> Void // We used to sometimes not run this completion handler, but if you wrapped this method in `withCheckedContinuation` and resumed the continuation during that handler, that leaked `CheckedContinuation`. Hence, this method always runs the completion handler, and callers should pass a completion handler that returns immediately if the parameter is `false`.
	) {
		animations_in_progress += 1
		let old_ids = ids_rows_onscreen
		ids_rows_onscreen = new_ids
		tableView.perform_batch_updates_from_ids(old: old_ids, new: new_ids) {
			// Completion handler
			self.animations_in_progress -= 1
			if self.animations_in_progress == 0 { // If we call `performBatchUpdates` multiple times quickly, executions after the first one can beat the first one to the completion closure, because they don’t have to animate any rows. Here, we wait for the animations to finish before we run the completion closure (once).
				completion_if_should_run(true)
			} else {
				completion_if_should_run(false)
			}
		}
	}
	private var animations_in_progress = 0
}
