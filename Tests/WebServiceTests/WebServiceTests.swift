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

struct Example {
  let id: String
  let title: String
}

extension Example {
  init?(dictionary: JSONDictionary) {
    guard
      let id = dictionary["id"] as? String,
      let title = dictionary["title"] as? String
      else { return nil }
    
    self.id = id
    self.title = title
  }
  
  var toDictionary: JSONDictionary {
    return [
      "id": id,
      "title": title
    ]
  }
}

extension Example {
  static var all: ResourceCollection<Example> {
    return ResourceCollection(path: "examples") { $0.resourceMap(Example.init) }
  }
  
  static func specific(with id: String) -> Resource<Example> {
    return Resource(path: "examples/\(id)") { $0.resourceMap(Example.init) }
  }
  
  func create() -> Resource<Example> {
    return Resource(path: "examples", send: { .object(self.toDictionary) }) { (dict: JSONDictionary) -> Result<Example, WebServiceError> in
      return dict.resourceMap(Example.init)
    }
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
    
    let expectation = self.expectation(description: "completed")
    
    let resource = Example.specific(with: id)
    
    let expectedURL = URL(string: resource.path,
                          relativeTo: URL(string: self.baseURLString))
    let key = expectedURL!.absoluteString
    
    fakeSession.responses[key] = ["id": id, "title": title]
    
    webservice.load(resource) { result in
      switch result {
      case .success(let example):
        XCTAssertEqual(id, example.id)
        XCTAssertEqual(title, example.title)
        XCTAssertTrue(self.fakeSession.lastRequestHeaders == nil || self.fakeSession.lastRequestHeaders!.isEmpty)
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
    
    let expectation = self.expectation(description: "completed")
    
    let example = Example(id: id, title: title)
    let resource = example.create()
    
    let expectedURL = URL(string: resource.path,
                          relativeTo: URL(string: self.baseURLString))
    let key = expectedURL!.absoluteString
    
    fakeSession.responses[key] = ["id": id, "title": title]
    
    webservice.load(resource) { result in
      switch result {
      case .success(let createdExample):
        XCTAssertEqual(id, createdExample.id)
        XCTAssertEqual(title, createdExample.title)
        
        guard
          let actual = self.fakeSession.lastRequestJSONObject as? JSONDictionary
          else {
            XCTFail("expected data in session missing");
            return
          }
        
        let expected = example.toDictionary
        
        XCTAssertEqual(actual["id"] as! String, expected["id"] as! String)
        XCTAssertEqual(actual["title"] as! String, expected["title"] as! String)
        XCTAssertEqual(actual.count, expected.count)
        
        XCTAssertTrue(self.fakeSession.lastRequestHeaders == nil || self.fakeSession.lastRequestHeaders!.isEmpty)
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
  
}
