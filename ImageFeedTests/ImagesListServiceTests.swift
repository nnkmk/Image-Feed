@testable import ImageFeed
import XCTest


final class ImageFeedTests: XCTestCase {


    func testExample() {
        func testFetchPhotos() {
                let service = ImagesListService()
                
                let expectation = self.expectation(description: "Wait for Notification")
                NotificationCenter.default.addObserver(
                    forName: ImagesListService.didChangeNotification,
                    object: nil,
                    queue: .main) { _ in
                        expectation.fulfill()
                    }
                
            service.fetchPhotosNextPage(completion: { _ in })
                wait(for: [expectation], timeout: 10)
                
                XCTAssertEqual(service.photos.count, 10)
            }
    }


}
