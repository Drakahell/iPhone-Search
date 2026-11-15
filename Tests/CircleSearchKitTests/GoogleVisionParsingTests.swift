@testable import CircleSearchKit
import XCTest

final class GoogleVisionParsingTests: XCTestCase {
    func testParsesWebDetection() throws {
        let json = """
        {"responses":[{"webDetection":{
          "webEntities":[{"description":"Eiffel Tower","score":0.92},{"description":"eiffel tower","score":0.8},{"description":"Noise","score":0.1}],
          "pagesWithMatchingImages":[{"url":"https://example.com/paris","pageTitle":"<b>Eiffel</b> Tower &amp; Paris",
            "fullMatchingImages":[{"url":"https://example.com/img.jpg"}]}],
          "visuallySimilarImages":[{"url":"https://example.com/sim.jpg"}],
          "bestGuessLabels":[{"label":"eiffel tower","languageCode":"en"}]
        }}]}
        """
        let results = try GoogleVisionClient.parse(Data(json.utf8), statusCode: 200)

        XCTAssertEqual(results.bestGuess, "eiffel tower")
        XCTAssertEqual(results.entities, ["Eiffel Tower"])            // дубль и низкий score отброшены
        XCTAssertEqual(results.pages.first?.title, "Eiffel Tower & Paris") // HTML вычищен
        XCTAssertEqual(results.pages.first?.imageURL?.absoluteString, "https://example.com/img.jpg")
        XCTAssertEqual(results.similarImages.count, 1)
    }

    func testServerErrorIsThrown() {
        let json = #"{"error":{"code":403,"message":"API key not valid"}}"#
        XCTAssertThrowsError(try GoogleVisionClient.parse(Data(json.utf8), statusCode: 403))
    }

    func testEmptyResponseIsEmpty() throws {
        let results = try GoogleVisionClient.parse(Data(#"{"responses":[{}]}"#.utf8), statusCode: 200)
        XCTAssertTrue(results.isEmpty)
    }

    func testGoogleTextSearchURL() {
        let url = GoogleWebSearch.url(for: "  кот  ", languageCode: "ru")
        XCTAssertEqual(url?.host(), "www.google.com")
        XCTAssertTrue(url?.absoluteString.contains("hl=ru") == true)
        XCTAssertNil(GoogleWebSearch.url(for: "   "))
    }
}
