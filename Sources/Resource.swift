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

public struct None: Encodable {}

public struct Resource<O: Encodable, I: Decodable> {
  
  public enum Sendable {
    case object(JSONDictionary)
    case collection(JSONArray)
  }
  
  public typealias Outgoing = (() -> Sendable)
  public typealias Incoming = (() -> JSONDecoder)
  
  public let method: Method
  public let path: String
  public let package: () -> Result<Data?, WebServiceError>
  public let parse: (Data) -> Result<I, WebServiceError>
  
  public var httpMethod: String? { return method.httpMethod }
}

public extension Resource {
  public init(method: Method = .get, path: String, send package: O? = nil, encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder()) {
    self.method = method
    self.path = path
    
    self.package = {
      guard let package = package else { return .success(nil) }
      
      do {
        let encoded = try encoder.encode(package)
        return .success(encoded)
      } catch {
        return .failure(WebServiceError.serializationError(error))
      }
    }
    
    self.parse = { data in
      do {
        let decoded = try decoder.decode(I.self, from: data)
        return .success(decoded)
      } catch {
        return .failure(WebServiceError.deserializationError(error))
      }
    }
  }
}
