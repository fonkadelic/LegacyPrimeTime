import Overture

public struct Lens<Whole, Part> {
  public let view: (Whole) -> Part
  public let mutatingSet: (inout Whole, Part) -> Void

  public func set(_ whole: Whole, _ part: Part) -> Whole {
    var result = whole
    self.mutatingSet(&result, part)
    return result
  }

  public func compose<Subpart>(_ other: Lens<Part, Subpart>) -> Lens<Whole, Subpart> {
    return Lens<Whole, Subpart>(
      view: Overture.compose(other.view, self.view),
      mutatingSet: { whole, subpart in
        var part = self.view(whole)
        other.mutatingSet(&part, subpart)
        self.mutatingSet(&whole, part)
    })
  }
}

public func lens<Whole, Part>(
  get: @escaping (Whole) -> Part,
  inverseGet: @escaping (Part) -> Whole
) -> Lens<Whole, Part> {

  return Lens(
    view: get,
    mutatingSet: { (whole, part) in
      whole = inverseGet(part)
  })
}

public func lens<Whole, Part>(_ keyPath: WritableKeyPath<Whole, Part>) -> Lens<Whole, Part> {
  return Lens(
    view: { $0[keyPath: keyPath] },
    mutatingSet: { whole, part in
      whole[keyPath: keyPath] = part
  })
}

public func zip<Whole, A, B>(
  _ a: Lens<Whole, A>,
  _ b: Lens<Whole, B>
) -> Lens<Whole, (A, B)> {

  return Lens(
    view: { (a.view($0), b.view($0)) },
    mutatingSet: { whole, parts in
      a.mutatingSet(&whole, parts.0)
      b.mutatingSet(&whole, parts.1)
  })
}
