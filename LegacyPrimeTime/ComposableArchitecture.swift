import Combine
import Prelude

public struct Effect<Output>: Publisher {
    public typealias Failure = Never

    let publisher: AnyPublisher<Output, Failure>

    public func receive<S>(
        subscriber: S
    ) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        self.publisher.receive(subscriber: subscriber)
    }
}

extension Effect {
    public static func fireAndForget(work: @escaping () -> Void) -> Effect {
        return Deferred { () -> Empty<Output, Never> in
            work()
            return Empty(completeImmediately: true)
        }.eraseToEffect()
    }

    public static func sync(work: @escaping () -> Output) -> Effect {
        return Deferred {
            Just(work())
        }.eraseToEffect()
    }
}

extension Publisher where Failure == Never {
    public func eraseToEffect() -> Effect<Output> {
        return Effect(publisher: self.eraseToAnyPublisher())
    }
}

public struct Reducer<Value, Action> {
  public let reduce: (inout Value, Action) -> [Effect<Action>]

  public func pullback<GlobalValue, GlobalAction>(
    value: Lens<GlobalValue, Value>,
    action: WritableKeyPath<GlobalAction, Action?>
  ) -> Reducer<GlobalValue, GlobalAction> {

    return Reducer<GlobalValue, GlobalAction> { globalValue, globalAction in
      guard let localAction = globalAction[keyPath: action] else { return [] }

      var state = value.view(globalValue)
      let localEffects = self.reduce(&state, localAction)
      value.mutatingSet(&globalValue, state)

      return localEffects.map { localEffect in
        localEffect.map { localAction -> GlobalAction in
          var globalAction = globalAction
          globalAction[keyPath: action] = localAction
          return globalAction
        }
        .eraseToEffect()
      }
    }
  }

  public func pullback<GlobalValue, GlobalAction>(
    value: WritableKeyPath<GlobalValue, Value>,
    action: WritableKeyPath<GlobalAction, Action?>
  ) -> Reducer<GlobalValue, GlobalAction> {

    return pullback(value: lens(value), action: action)
  }
}

public final class Store<Value, Action>: ObservableObject {
  @Published public private(set) var value: Value
  private let reducer: Reducer<Value, Action>
  private var viewCancellable: Cancellable?
  private var effectCancellables: Set<AnyCancellable> = []

  public init(initialValue: Value, reducer: Reducer<Value, Action>) {
    self.reducer = reducer
    self.value = initialValue
  }

  public func send(_ action: Action) {
    let effects = self.reducer.reduce(&self.value, action)
    effects.forEach { effect in
      var effectCancellable: AnyCancellable?
      var didComplete = false
      effectCancellable = effect.sink(
        receiveCompletion: { [weak self] _ in
          didComplete = true
          guard let effectCancellable = effectCancellable else { return }
          self?.effectCancellables.remove(effectCancellable)
        },
        receiveValue: self.send
      )
      if !didComplete, let effectCancellable = effectCancellable {
        self.effectCancellables.insert(effectCancellable)
      }
    }
  }

  public func view<LocalValue, LocalAction>(
    value toLocalValue: @escaping (Value) -> LocalValue,
    action toGlobalAction: @escaping (LocalAction) -> Action
  ) -> Store<LocalValue, LocalAction> {
    let localStore = Store<LocalValue, LocalAction>(
      initialValue: toLocalValue(self.value),
      reducer: Reducer { localValue, localAction in
        self.send(toGlobalAction(localAction))
        localValue = toLocalValue(self.value)
        return []
    })
    localStore.viewCancellable = self.$value.sink { [weak localStore] newValue in
      localStore?.value = toLocalValue(newValue)
    }
    return localStore
  }
}

extension Store {
  func subscribe<T>(
    state keyPath: KeyPath<Value, T>,
    removeDuplicates: @escaping (T, T) -> Bool = { _,_  in false }
  ) -> AnyPublisher<T, Never> {

    return self.$value
      .map(keyPath)
      .removeDuplicates(by: removeDuplicates)
      .eraseToAnyPublisher()
  }

  func subscribe<T>(state keyPath: KeyPath<Value, T>) -> AnyPublisher<T, Never> where T: Equatable {
    return subscribe(state: keyPath, removeDuplicates: ==)
  }
}

public func combine<Value, Action>(
  _ reducers: Reducer<Value, Action>...
) -> Reducer<Value, Action> {
  return Reducer { value, action in
    reducers.flatMap { $0.reduce(&value, action) }
  }
}

public func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction>(
  _ reducer: Reducer<LocalValue, LocalAction>,
  value: Lens<GlobalValue, LocalValue>,
  action: WritableKeyPath<GlobalAction, LocalAction?>
) -> Reducer<GlobalValue, GlobalAction> {
  return reducer.pullback(value: value, action: action)
}

public func pullback<LocalValue, GlobalValue, LocalAction, GlobalAction>(
  _ reducer: Reducer<LocalValue, LocalAction>,
  value: WritableKeyPath<GlobalValue, LocalValue>,
  action: WritableKeyPath<GlobalAction, LocalAction?>
) -> Reducer<GlobalValue, GlobalAction> {

  return reducer.pullback(value: value, action: action)
}
