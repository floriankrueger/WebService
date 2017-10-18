//
//  WebServiceError.swift
//  WebService
//
//  Created by Florian Krüger on 26/02/2017.
//  Copyright © 2017 projectserver.org. All rights reserved.
//

import Foundation

public enum WebServiceError: Error {
  case emptyResult
  case notADictionary
  case notAnArray(Any)
  case invalidModel
  case serializationError(Error)
  case deserializationError(Error)
  case networkError(Error)
}
