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
}

extension Example {
  static var all: ResourceCollection<Example> {
    return ResourceCollection(path: "examples") { (dict: JSONDictionary) -> Result<Example> in
      return dict.resourceMap(Example.init)
    }
  }
  
  static func specific(with id: String) -> Resource<Example> {
    return Resource(path: "examples/\(id)") { (dict: JSONDictionary) -> Result<Example> in
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
  
  func testAll() {
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
      case .error(let error):
        XCTFail(error.localizedDescription)
      }
      
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
  }
  
  func testSpecific() {
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
      case .error(let error):
        XCTFail(error.localizedDescription)
      }
      
      expectation.fulfill()
    }
    
    waitForExpectations(timeout: 0.5) { XCTAssertNil($0) }
  }
  
}
