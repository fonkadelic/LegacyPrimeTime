import UIKit
import Prelude

func isPrime(_ p: Int) -> Bool {
  if p <= 1 { return false }
  if p <= 3 { return true }
  for i in 2...Int(sqrtf(Float(p))) {
    if p % i == 0 { return false }
  }
  return true
}

public struct PrimeModalState {
  public var count: Int
  var title = "Hello"
}

extension PrimeModalState {
  var isButtonHidden: Bool { !isPrime(count) }
  var labelText: String { isPrime(count)
    ? "\(count) is prime 🎉"
    : "\(count) is not prime 😞"
  }
}

public extension PrimeModalState {
  init(count: Int) {
    self.count = count
  }

  static let lens = Prelude.lens(get: Self.init, inverseGet: { $0.count })
}

public enum PrimeModalAction: Equatable {
  case saveFavoritePrimeTapped
  case removeFavoritePrimeTapped
}

public let primeModalReducer = Reducer<PrimeModalState, PrimeModalAction> { state, action in
  switch action {
  case .removeFavoritePrimeTapped:
//    state.favoritePrimes.removeAll(where: { $0 == state.count })
    return []

  case .saveFavoritePrimeTapped:
//    state.favoritePrimes.append(state.count)
    return []
  }
}

import Combine

final class PrimeModalViewController: UIViewController {

  private var store: Store<PrimeModalState, PrimeModalAction>
  private var subscriptions = Set<AnyCancellable>()

  @IBOutlet private var label: UILabel!
  @IBOutlet private var button: UIButton!

  init?(coder: NSCoder, store: Store<PrimeModalState, PrimeModalAction>) {
    self.store = store
    super.init(coder: coder)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    store.subscribe(state: \.labelText)
      .assign(to: \.text!, on: label)
      .store(in: &subscriptions)
    store.subscribe(state: \.isButtonHidden)
      .assign(to: \.isHidden, on: button)
      .store(in: &subscriptions)
  }
}
