import Foundation

public enum SignInProgress: Sendable, Equatable {
    case starting
    case waitingForBrowser(URL?)
    case connecting
}
