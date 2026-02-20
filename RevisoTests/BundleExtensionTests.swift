import Testing
import Foundation
@testable import Reviso

struct BundleExtensionTests {

    @Test func appVersion_returnsString() {
        let version = Bundle.main.appVersion
        #expect(!version.isEmpty)
    }

    @Test func buildNumber_returnsString() {
        let build = Bundle.main.buildNumber
        #expect(!build.isEmpty)
    }

    @Test func versionDisplay_containsVersionAndBuild() {
        let display = Bundle.main.versionDisplay
        #expect(display.contains(Bundle.main.appVersion))
        #expect(display.contains(Bundle.main.buildNumber))
    }
}
