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

public struct ResourceCollection<A> {
  public let method: Method
  public let path: String
  public let parse: (Data) -> Result<[A]>
  
  public var httpMethod: String? { return method.httpMethod }
}

public extension ResourceCollection {
  public init(method: Method = .get, path: String, parseJSONDictionary: @escaping (JSONDictionary) -> Result<A>) {
    self.method = method
    self.path = path
    self.parse = { data in
      let jsonObject: Any
      do {
        jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
      } catch {
        return .error(error)
      }
      if let json = jsonObject as? JSONArray {
        return ResourceCollection.flatMap(json, parseJSONDictionary)
      } else {
        return .error(WebServiceError.notAnArray(jsonObject))
      }
    }
  }
  
  private static func flatMap(_ array: JSONArray, _ parseJSONDictionary: @escaping (JSONDictionary) -> Result<A>) -> Result<[A]> {
    var models: [A] = []
    
    for dictionary in array {
      switch parseJSONDictionary(dictionary) {
      case .success(let model):
        models.append(model)
      case .error(let error):
        return .error(error)
      }
    }
    
    return .success(models)
  }
}