/**
 *  WebService
 *
 *  Copyright (c) 2016 Florian Krüger. Licensed under the MIT license, as follows:
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
 */

import Foundation
import XCTest
import WebService
import Result

struct Example: Codable {
  let id: String
  let title: String
  let createdAt: Date?
}

extension DateFormatter {
  static let iso8601: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }()
}

extension Example {
  static let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601)
    return decoder
  }()
  
  static let encoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .formatted(DateFormatter.iso8601)
    return encoder
  }()
  
  static var all: Resource<None, [Example]> {
    return Resource(path: "examples", decoder: Example.decoder)
  }
  
  static func specific(with id: String) -> Resource<None, Example> {
    return Resource(path: "examples/\(id)", decoder: Example.decoder)
  }
  
  func create() -> Resource<Example, Example> {
    return Resource(path: "examples", send: self, encoder: Example.encoder, decoder: Example.decoder)
  }
}

class WebServiceTests: XCTestCase {
  
  let baseURLString = "http://example.org/api/v1/"
  
  private lazy var fakeSession: FakeSession = {
    return FakeSession()
  }()
  
  private lazy var webservice: WebService = {
    return WebService(baseURL: URL(string: self.baseURLString)!,
                      session: self.fakeSession)
  }()
  
  override func setUp() {
    super.setUp()
    webservice.defaultHeaders = nil
    fakeSession.reset()
  }
  
  func testAll() {
    webservice.defaultHeaders = nil
    
    let expected: [[String: Any]] = [
      ["id": "0", "title": "first example"],
      ["id": "1", "title": "second example"]
    ]
    
    let expectation = self.expectation(description: "completed")
    
    let resourceCollection = Example.all
    
    let expectedURL = URL(string: resourceCollection.path,
                          relativeTo: URL(string: self.baseURLString))
    let key = expectedURL!.absoluteString
    
    fakeSession.responses[key] = expected
    
    webservice.load(resourceCollection) { result in
      switch result {
      case .success(let actual):
        XCTAssertEqual(actual.count, expected.count)
        XCTAssertTrue(self.fakeSession.lastRequestHeaders == nil || self.fakeSession.lastRequestHeaders!.isEmpty)
      case .failure(let error):
        XCTFail(error.localizedDescription)
      }
      
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
  }
  
  func testSpecific() {
    webservice.defaultHeaders = nil
    
    let id = "0"
    let title = "first example"
    let createdAtString = "2014-10-23T23:10:00+01:00"
    
    let expectation = self.expectation(description: "completed")
    
    let resource = Example.specific(with: id)
    
    let expectedURL = URL(string: resource.path,
                          relativeTo: URL(string: self.baseURLString))
    let key = expectedURL!.absoluteString
    
    fakeSession.responses[key] = ["id": id, "title": title, "createdAt": createdAtString]
    
    webservice.load(resource) { result in
      switch result {
      case .success(let example):
        XCTAssertEqual(id, example.id)
        XCTAssertEqual(title, example.title)
        XCTAssertTrue(self.fakeSession.lastRequestHeaders == nil || self.fakeSession.lastRequestHeaders!.isEmpty)
        
        XCTAssertNotNil(example.createdAt)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: example.createdAt!)
        XCTAssertEqual(components.year, 2014)
        XCTAssertEqual(components.month, 10)
        XCTAssertEqual(components.day, 24)
        XCTAssertEqual(components.hour, 00)
        XCTAssertEqual(components.minute, 10)
      case .failure(let error):
        XCTFail(error.localizedDescription)
      }
      
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
  }
  
  func testCreate() {
    webservice.defaultHeaders = nil
    
    let id = "7"
    let title = "The 7th Example"
    let createdAtString = "2014-10-23T23:10:00+01:00"
    
    let expectation = self.expectation(description: "completed")
    
    let example = Example(id: id, title: title, createdAt: nil)
    let resource = example.create()
    
    let expectedURL = URL(string: resource.path,
                          relativeTo: URL(string: self.baseURLString))
    let key = expectedURL!.absoluteString
    
    fakeSession.responses[key] = ["id": id, "title": title, "createdAt": createdAtString]
    
    webservice.load(resource) { result in
      switch result {
      case .success(let createdExample):
        XCTAssertEqual(id, createdExample.id)
        XCTAssertEqual(title, createdExample.title)
        XCTAssertNotNil(createdExample.createdAt)
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: createdExample.createdAt!)
        XCTAssertEqual(components.year, 2014)
        XCTAssertEqual(components.month, 10)
        XCTAssertEqual(components.day, 24)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 10)
        
        guard
          let actual = self.fakeSession.lastRequestJSONObject as? JSONDictionary
          else {
            XCTFail("expected data in session missing");
            return
          }
        
        let expected: [AnyHashable: Any] = ["id": "7", "title": "The 7th Example"]
        
        XCTAssertEqual(actual["id"] as! String, expected["id"] as! String)
        XCTAssertEqual(actual["title"] as! String, expected["title"] as! String)
        XCTAssertEqual(actual.count, expected.count)
        
        XCTAssertNotNil(self.fakeSession.lastRequestHeaders)
        XCTAssertEqual(["Content-Type": "application/json"], self.fakeSession.lastRequestHeaders!)
      case .failure(let error):
        XCTFail(error.localizedDescription)
      }
      
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
  }
  
  func testDefaultHeadersResource() {
    let headers = ["testHeader": "testValue"]
    webservice.defaultHeaders = headers
    
    let expectation = self.expectation(description: "completed")
    
    let resource = Example.specific(with: "0")
    
    let expectedURL = URL(string: resource.path,
                          relativeTo: URL(string: self.baseURLString))
    let key = expectedURL!.absoluteString
    
    fakeSession.responses[key] = ["id": "0", "title": "something"]
    
    webservice.load(resource) { result in
      switch result {
      case .success(_):
        XCTAssertNotNil(self.fakeSession.lastRequestHeaders)
        XCTAssertEqual(headers, self.fakeSession.lastRequestHeaders!)
      case .failure(let error):
        XCTFail(error.localizedDescription)
      }
      
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
  }
  
  func testDefaultHeadersResourceCollection() {
    let headers = ["collectionTestHeader": "collectionTestValue"]
    webservice.defaultHeaders = headers
    
    let expectation = self.expectation(description: "completed")
    
    let resourceCollection = Example.all
    
    let expectedURL = URL(string: resourceCollection.path,
                          relativeTo: URL(string: self.baseURLString))
    let key = expectedURL!.absoluteString
    
    fakeSession.responses[key] = [
      ["id": "0", "title": "first example"],
      ["id": "1", "title": "second example"]
    ]
  
    webservice.load(resourceCollection) { result in
      switch result {
      case .success(_):
        XCTAssertNotNil(self.fakeSession.lastRequestHeaders)
        XCTAssertEqual(headers, self.fakeSession.lastRequestHeaders!)
      case .failure(let error):
        XCTFail(error.localizedDescription)
      }
      
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
  }
  
  func testRequestHeadersResource() {
    let headers = ["testHeader":        "testValue",
                   "testRequestHeader": "this should be overwritten"]
    webservice.defaultHeaders = headers
    
    let expectation = self.expectation(description: "completed")
    
    let resource = Example.specific(with: "0")
    
    let expectedURL = URL(string: resource.path,
                          relativeTo: URL(string: self.baseURLString))
    let key = expectedURL!.absoluteString
    
    fakeSession.responses[key] = ["id": "0", "title": "something"]
    
    let expected = ["testHeader":         "testValue",
                    "testRequestHeader":  "testRequestValue"]
    
    webservice.load(resource, headers: ["testRequestHeader": "testRequestValue"]) { result in
      switch result {
      case .success(_):
        XCTAssertNotNil(self.fakeSession.lastRequestHeaders)
        XCTAssertEqual(expected, self.fakeSession.lastRequestHeaders!)
      case .failure(let error):
        XCTFail(error.localizedDescription)
      }
      
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
  }
  
  func testRequestHeadersResourceCollection() {
    let headers = ["collectionTestHeader": "collectionTestValue",
                   "collectionRequestTestHeader": "this should be overwritten"]
    webservice.defaultHeaders = headers
    
    let expectation = self.expectation(description: "completed")
    
    let resourceCollection = Example.all
    
    let expectedURL = URL(string: resourceCollection.path,
                          relativeTo: URL(string: self.baseURLString))
    let key = expectedURL!.absoluteString
    
    fakeSession.responses[key] = [
      ["id": "0", "title": "first example"],
      ["id": "1", "title": "second example"]
    ]
    
    let expected = ["collectionTestHeader": "collectionTestValue",
                    "collectionRequestTestHeader": "collectionRequestTestValue"]
    
    webservice.load(resourceCollection, headers: ["collectionRequestTestHeader": "collectionRequestTestValue"]) { result in
      switch result {
      case .success(_):
        XCTAssertNotNil(self.fakeSession.lastRequestHeaders)
        XCTAssertEqual(expected, self.fakeSession.lastRequestHeaders!)
      case .failure(let error):
        XCTFail(error.localizedDescription)
      }
      
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
  }
  
  func testRequestHeadersCreate() {
    let example = Example(id: "id", title: "title", createdAt: nil)
    let expectation = self.expectation(description: "completed")
    
    let resource = example.create()
    
    let expectedURL = URL(string: resource.path,
                          relativeTo: URL(string: self.baseURLString))
    let key = expectedURL!.absoluteString
    
    fakeSession.responses[key] = ["id": "id", "title": "title"]
    
    let expected = ["Content-Type": "application/json"]
    
    webservice.load(resource) { result in
      switch result {
      case .success(_):
        XCTAssertNotNil(self.fakeSession.lastRequestHeaders)
        XCTAssertEqual(expected, self.fakeSession.lastRequestHeaders!)
      case .failure(let error):
        XCTFail(error.localizedDescription)
      }
      
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
  }
  
  func testRequestHeadersWithCustomHeadersCreate() {
    let headers = ["testHeader": "testValue"]
    
    let example = Example(id: "id", title: "title", createdAt: nil)
    let expectation = self.expectation(description: "completed")
    
    let resource = example.create()
    
    let expectedURL = URL(string: resource.path,
                          relativeTo: URL(string: self.baseURLString))
    let key = expectedURL!.absoluteString
    
    fakeSession.responses[key] = ["id": "id", "title": "title"]
    
    let expected = ["Content-Type": "application/json",
                    "testHeader": "testValue"]
    
    webservice.load(resource, headers: headers) { result in
      switch result {
      case .success(_):
        XCTAssertNotNil(self.fakeSession.lastRequestHeaders)
        XCTAssertEqual(expected, self.fakeSession.lastRequestHeaders!)
      case .failure(let error):
        XCTFail(error.localizedDescription)
      }
      
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
  }
  
}
