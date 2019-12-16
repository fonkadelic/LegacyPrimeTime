import XCTest
@testable import Prelude

struct User {
  var id: Int
  var name: String

  public init(id: Int, name: String) {
    self.id = id
    self.name = name
  }
}

struct Episode {
  var id: Int
  var host: User
  var cohost: User?
  var guests: [User]
  var isSubscriberOnly: Bool
}

let user = User(id: 1, name: "Blob")

let episode = Episode(
  id: 5,
  host: user,
  cohost: nil,
  guests: [User(id: 2, name: "Glob"), User(id: 3, name: "Prob")],
  isSubscriberOnly: false
)

class PreludeTests: XCTestCase {

    func testLens() {
      struct UserEpisodeState: Equatable {
        var userId: Int
        var isSubscriberOnly: Bool
      }

      struct AppState {
        var user: User
        var episode: Episode
      }

      let userLens = lens(\AppState.user.id)
      let episodeLens = lens(\AppState.episode.isSubscriberOnly)
      let userEpisodeLens = lens(
        get: UserEpisodeState.init,
        inverseGet: { ($0.userId, $0.isSubscriberOnly) }
      )

      let theLens = zip(userLens, episodeLens).compose(userEpisodeLens)

      var appState = AppState(user: user, episode: episode)

      XCTAssertEqual(UserEpisodeState(userId: 1, isSubscriberOnly: false), theLens.view(appState))

      theLens.mutatingSet(&appState, UserEpisodeState(userId: 4, isSubscriberOnly: true))

      XCTAssertEqual(appState.user.id, 4)
      XCTAssertEqual(appState.episode.isSubscriberOnly, true)
    }
}
