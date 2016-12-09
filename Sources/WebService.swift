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
  
  public func load<A>(_ resource: Resource<A>, completion: @escaping (Result<A>) -> Void) {
    let url = URL(string: resource.path, relativeTo: baseURL)!
    var request = URLRequest(url: url)
    request.httpMethod = resource.httpMethod
    session.dataTask(with: request) { data, _, error in
      guard let data = data else {
        if let error = error {
          completion(.error(error))
        } else {
          completion(.error(WebServiceError.emptyResult))
        }
        return
      }
      completion(resource.parse(data))
      }.resume()
  }
  
  public func load<A>(_ resource: ResourceCollection<A>, completion: @escaping (Result<[A]>) -> Void) {
    let url = URL(string: resource.path, relativeTo: baseURL)!
    var request = URLRequest(url: url)
    request.httpMethod = resource.httpMethod
    session.dataTask(with: request) { data, _, error in
      guard let data = data else {
        if let error = error {
          completion(.error(error))
        } else {
          completion(.error(WebServiceError.emptyResult))
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
