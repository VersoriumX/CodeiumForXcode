import ComposableArchitecture
import Foundation

struct APIKeyManagement: ReducerProtocol {
    struct State: Equatable {
        var availableAPIKeyNames: [String] = []
        @PresentationState var apiKeySubmission: APIKeySubmission.State?
    }

    enum Action: Equatable {
        case appear
        case closeButtonClicked
        case addButtonClicked
        case deleteButtonClicked(name: String)
        case refreshAvailableAPIKeyNames

        case apiKeySubmission(PresentationAction<APIKeySubmission.Action>)
    }

    @Dependency(\.toast) var toast
    @Dependency(\.apiKeyKeychain) var keychain

    var body: some ReducerProtocol<State, Action> {
        Reduce { state, action in
            switch action {
            case .appear:
                if isPreview { return .none }
                
                return .run { send in
                    await send(.refreshAvailableAPIKeyNames)
                }
            case .closeButtonClicked:
                return .none
                
            case .addButtonClicked:
                state.apiKeySubmission = .init()
                
                return .none

            case let .deleteButtonClicked(name):
                do {
                    try keychain.remove(name)
                    return .run { send in
                        await send(.refreshAvailableAPIKeyNames)
                    }
                } catch {
                    toast(error.localizedDescription, .error)
                    return .none
                }

            case .refreshAvailableAPIKeyNames:
                do {
                    let pairs = try keychain.getAll()
                    state.availableAPIKeyNames = Array(pairs.keys)
                } catch {
                    toast(error.localizedDescription, .error)
                }

                return .none

            case .apiKeySubmission(.presented(.saveFinished)):
                state.apiKeySubmission = nil
                return .run { send in
                    await send(.refreshAvailableAPIKeyNames)
                }

            case .apiKeySubmission(.presented(.cancelButtonClicked)):
                state.apiKeySubmission = nil
                return .none

            case .apiKeySubmission:
                return .none
            }
        }
        .ifLet(\.$apiKeySubmission, action: /Action.apiKeySubmission) {
            APIKeySubmission()
        }
    }
}

