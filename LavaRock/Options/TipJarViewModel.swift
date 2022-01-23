//
//  TipJarViewModel.swift
//  LavaRock
//
//  Created by h on 2022-01-22.
//

import StoreKit
import Combine

protocol TipJarDelegate: AnyObject {
	func statusBecameLoading()
	func statusBecameReload()
	func statusBecameReady()
	func statusBecameConfirming()
	func tipTransactionUpdated(_ transaction: SKPaymentTransaction)
}

final class TipJarViewModel: ObservableObject {
	private init() {}
	static let shared = TipJarViewModel()
	
	enum Status: Equatable {
		case notYetFirstLoaded
		case loading
		case reload
		case ready(SKPaymentTransaction?)
		case confirming
	}
	
	weak var delegate: TipJarDelegate? = nil
	
	@Published var status: Status = .notYetFirstLoaded {
		didSet {
			DispatchQueue.main.async {
				switch self.status {
				case .notYetFirstLoaded:
					// Should never run
					break
				case .loading:
					self.delegate?.statusBecameLoading()
				case .reload:
					self.delegate?.statusBecameReload()
				case .ready(let transaction):
					if let transaction = transaction {
						self.delegate?.tipTransactionUpdated(transaction)
					} else {
						self.delegate?.statusBecameReady()
					}
				case .confirming:
					self.delegate?.statusBecameConfirming()
				}
			}
		}
	}
}
