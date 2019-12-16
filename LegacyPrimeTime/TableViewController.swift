import UIKit

final class TableViewController: UITableViewController {

  @IBSegueAction
  private func initializeCounter(coder: NSCoder) -> UIViewController? {
    let store = Store(initialValue: CounterState(), reducer: counterViewReducer)
    return CounterViewController(coder: coder, store: store)
  }

  @IBSegueAction
  private func initializeFavoritePrimes(coder: NSCoder) -> UIViewController {
    fatalError()
  }
}
