import Overture
//import Optics

struct User {
  var id: Int
  var name: String
}

struct Episode {
  var id: Int
  var title: String
  var videoUrl: String
}

struct Settings {
  var notificationsOn: Bool = false
}

struct EpisodesState {
  var episodes: [Episode] = []
}

struct AccountState {
  var loggedInUser: User? = nil
  var settings: Settings = .init()
}

struct AppState {
  var episodesState = EpisodesState()
  var accountState = AccountState()
}

struct AccountViewState {
  var episodes: [Episode]
  var notificationsOn: Bool
}

let episode = Episode(
  id: 1,
  title: "title",
  videoUrl: "videoUrl"
)

var appState = AppState()
//let someLens = both(lens(\AppState.episodesState.episodes), lens(\AppState.accountState.settings.notificationsOn))
//let raw = someLens.view(appState)
//
//let accountViewLens = zip(with: AccountViewState.init, review: { state in (state.episodes, state.notificationsOn) })(
//  lens(\AppState.episodesState.episodes),
//  lens(\AppState.accountState.settings.notificationsOn)
//)
//someLens.mutatingSet(&appState, ([episode], true))
//dump(appState)

