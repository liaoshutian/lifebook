import XCTest
@testable import LifeBook

final class KeychainStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        KeychainStore.deleteAPIKey()
    }

    override func tearDown() {
        KeychainStore.deleteAPIKey()
        super.tearDown()
    }

    func testSaveReadAndDeleteAPIKey() throws {
        try KeychainStore.saveAPIKey("sk-test-value")
        XCTAssertEqual(KeychainStore.readAPIKey(), "sk-test-value")

        KeychainStore.deleteAPIKey()
        XCTAssertNil(KeychainStore.readAPIKey())
    }
}
