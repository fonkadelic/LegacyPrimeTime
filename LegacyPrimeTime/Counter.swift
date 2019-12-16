import UIKit
import Combine
import Prelude

public enum CounterAction: Equatable {
  case decrTapped
  case incrTapped
}

public struct CounterState {
  var count: Int = 0
  var title: String = "Blob"
}

extension CounterState {
  var displayCount: String { "\(count)" }
}

public enum CounterViewAction: Equatable {
  case counter(CounterAction)
  case primeModal(PrimeModalAction)

  var counter: CounterAction? {
    get {
      guard case let .counter(value) = self else { return nil }
      return value
    }
    set {
      guard case .counter = self, let newValue = newValue else { return }
      self = .counter(newValue)
    }
  }

  var primeModal: PrimeModalAction? {
    get {
      guard case let .primeModal(value) = self else { return nil }
      return value
    }
    set {
      guard case .primeModal = self, let newValue = newValue else { return }
      self = .primeModal(newValue)
    }
  }

}


let counterReducer = Reducer<CounterState, CounterAction> { state, action in
  switch action {
  case .decrTapped:
    state.count -= 1
    return []

  case .incrTapped:
    state.count += 1
    return []
  }
}

let primeModalLens = lens(\CounterState.count).compose(PrimeModalState.lens)

let counterViewReducer = combine(
  pullback(
    counterReducer,
    value: \.self,
    action: \CounterViewAction.counter
  ),
  pullback(
    primeModalReducer,
    value: primeModalLens,
    action: \.primeModal
  )
)

final class CounterViewController: UIViewController {

  let store: Store<CounterState, CounterViewAction>

  init?(coder: NSCoder, store: Store<CounterState, CounterViewAction>) {
    self.store = store
    super.init(coder: coder)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  @IBOutlet private var countLabel: UILabel!

  private var subscriptions = Set<AnyCancellable>()

  override func viewDidLoad() {
    super.viewDidLoad()

    store.subscribe(state: \.displayCount)
      .assign(to: \.text!, on: countLabel)
      .store(in: &subscriptions)
  }

  @IBAction func incrTapped(_ sender: Any) {
    store.send(.counter(.incrTapped))
  }

  @IBAction func decrTapped(_ sender: Any) {
    store.send(.counter(.decrTapped))
  }

  @IBAction func isPrimeTapped(_ sender: Any) {
    let store = self.store.view(value: primeModalLens.view, action: { .primeModal($0) })
    let primeModal = storyboard!.instantiateViewController(identifier: "PrimeModalViewController", creator: {
      PrimeModalViewController(coder: $0, store: store)
    })
    present(primeModal, animated: true, completion: nil)
  }
}

