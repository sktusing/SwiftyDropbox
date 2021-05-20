import XCTest
@testable import SwiftyDropbox

enum TestAuthTokenGenerator {
    static func authToken(with refreshToken: String, apiKey: String, scopes: [String]) -> String? {
        let manager = SwiftyDropbox.DropboxOAuthManager(appKey: apiKey)

        let defaultToken = DropboxAccessToken(
            accessToken: "",
            uid: "",
            refreshToken: refreshToken,
            tokenExpirationTimestamp: 0
        )


        let flag = XCTestExpectation()

        var returnAccessToken: String?

        manager.refreshAccessToken(
            defaultToken,
            scopes: scopes,
            queue: DispatchQueue.global(qos: .userInitiated)) { result in

            switch result {
            case .success(let authToken)?:
                returnAccessToken = authToken.accessToken
            case .error(_, let description)?:
                XCTFail("Error: failed to refresh access token (\(description ?? "no description")")
            case .cancel?:
                XCTFail("Error: failed to refresh access token (cancelled)")
            case .none:
                XCTFail("Error: failed to refresh access token (no result)")
            }

            flag.fulfill()
        }

        let result = XCTWaiter.wait(for: [flag], timeout: 10)
        XCTAssertEqual(result, .completed, "Error: timeout refreshing access token")
        return returnAccessToken
    }
}
