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
import WebService

enum FakeSessionError: Error {
  case unexpected
  case cancelled
}

class FakeSession: Session, FakeSessionDataTaskDelegate {
  
  var responses = [String: Any]()
  var lastRequestHeaders: [String: String]? = nil
  var lastRequestData: Data? = nil
  var lastRequestJSONObject: Any? {
    guard let data = lastRequestData else { return nil }
    return try? JSONSerialization.jsonObject(with: data, options: [])
  }
  
  func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> SessionDataTask {
    let task = FakeSessionDataTask(request: request, completionHandler: completionHandler)
    task.delegate = self
    return task
  }
  
  // MARK: Actions
  
  func reset() {
    responses = [:]
    lastRequestHeaders = nil
    lastRequestData = nil
  }

  // MARK: FakeSessionDataTaskDelegate
  
  func fakeSessionDataTaskDidResume(_ sender: FakeSessionDataTask) {
    let key = sender.request.url!.absoluteString
    if let response = responses[sender.request.url!.absoluteString] {
      responses[key] = nil
      lastRequestHeaders = sender.request.allHTTPHeaderFields
      lastRequestData = sender.request.httpBody
      sender.completionHandler(try! JSONSerialization.data(withJSONObject: response, options: []), nil, nil)
    } else {
      sender.completionHandler(nil, nil, FakeSessionError.unexpected)
    }
  }
  
  func fakeSessionDataTaskDidCancel(_ sender: FakeSessionDataTask) {
    sender.completionHandler(nil, nil, FakeSessionError.cancelled)
  }
  
}
