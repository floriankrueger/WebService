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

public struct Resource<A> {
  
  public enum Sendable {
    case object(JSONDictionary)
    case collection(JSONArray)
  }
  
  public typealias Outgoing = (() -> Sendable)
  public typealias Incoming = ((JSONDictionary) -> Result<A, WebServiceError>)
  
  public let method: Method
  public let path: String
  public let package: () -> Result<Data?, WebServiceError>
  public let parse: (Data) -> Result<A, WebServiceError>
  
  public var httpMethod: String? { return method.httpMethod }
}

public extension Resource {
  init(method: Method = .get, path: String, send package: Outgoing? = nil, receive parse: @escaping Incoming) {
    self.method = method
    self.path = path
    
    self.package = {
      switch package?() {
      case .some(.object(let dictionary)):
        do {
          let data = try JSONSerialization.data(withJSONObject: dictionary, options: [])
          return .success(data)
        } catch {
          return .failure(.serializationError(error))
        }
      case .some(.collection(let array)):
        do {
          let data = try JSONSerialization.data(withJSONObject: array, options: [])
          return .success(data)
        } catch {
          return .failure(.serializationError(error))
        }
      default:
        return .success(nil)
      }
    }
    
    self.parse = { data in
      let json: JSONDictionary?
      do {
        json = try JSONSerialization.jsonObject(with: data, options: []) as? JSONDictionary
      } catch {
        return .failure(.deserializationError(error))
      }
      if let json = json {
        return parse(json)
      } else {
        return .failure(.notADictionary)
      }
    }
  }
}

public extension Dictionary where Key: Hashable, Value: Any {
  func resourceMap<A>(_ transform: ([AnyHashable: Any]) -> A?) -> Result<A, WebServiceError> {
    if let model = transform(self) {
      return .success(model)
    } else {
      return .failure(.invalidModel)
    }
  }
  
}
