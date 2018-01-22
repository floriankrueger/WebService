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
import Result

public protocol Session {
  func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> SessionDataTask
}

public protocol SessionDataTask {
  func resume()
  func cancel()
}

public final class WebService {
  
  public let baseURL: URL
  public let session: Session
  public var defaultHeaders: [String: String]? = nil
  
  public func load<O, I>(_ resource: Resource<O, I>, headers: [String: String]? = nil, completion: @escaping (Result<I, WebServiceError>) -> Void) {
    let url = URL(string: resource.path, relativeTo: baseURL)!
    var request = URLRequest(url: url)
    request.httpMethod = resource.httpMethod
    
    switch resource.package() {
    case .success(let data): request.httpBody = data
    case .failure(let error): completion(.failure(error)); return
    }
    
    request.allHTTPHeaderFields = requestHeaders(with: headers, hasJSONData: (request.httpBody != nil))
    
    session.dataTask(with: request) { data, _, error in
      guard let data = data else {
        if let error = error {
          completion(.failure(.networkError(error)))
        } else {
          completion(.failure(.emptyResult))
        }
        return
      }
      completion(resource.parse(data))
      }.resume()
  }
  
  public init(baseURL: URL, session: Session = URLSession.shared) {
    self.baseURL = baseURL
    self.session = session
  }
  
}

// MARK: - Helpers

extension WebService {
  
  fileprivate func requestHeaders(with headers: [String: String]?, hasJSONData: Bool) -> [String: String]? {
    guard let headers = headers else { return defaultHeaders }
    var requestHeaders = self.defaultHeaders ?? [:]
    headers.forEach { (k, v) in requestHeaders[k] = v }
    
    if hasJSONData {
      requestHeaders["Content-Type"] = "application/json"
    }
    
    return requestHeaders
  }
  
}
