# WebService

This micro-framework is inspired by the approach to do networking in Swift as shown in [Swift Talk](https://talk.objc.io/)’s [Episode #1](https://talk.objc.io/episodes/S01E01-networking). It's way more opinionated though.

## How to use

1. Create a WebService instance

   ```swift
   let baseURL = URL(string: "https://api.example.org")!
   let service = WebService(baseURL: baseURL)
   ```

2. Extend your model with an initializer that takes a `JSONDictionary`

   ```swift
   extension Example {
     init?(dictionary: JSONDictionary) {
     	guard 
     		let id = dictionary["id"] as? String 
     		else { return nil }
       self.id = id
     }
   }
   ```

3. Extend your model with a `Resource` and/or `ResourceCollection` method as necessary.

   ```swift
   extension Example {

     // fetches a list of `Example` entities from
     // "<baseurl>/examples"
     static var add: ResourceCollection<Example> {
       return ResourceCollection(path: "examples") { 
         (dict: JSONDictionary) -> Result<Example> in 
         return dict.resourceMap(Example.init)
       }
     }
     
     // fetches a specific `Example` entity from 
     // "<baseurl>/examples/<id>"
     static func specific(with id: String) -> Resource<Example> {
       return Resource(path: "examples/\(id)") { 
         (dict: JSONDictionary) -> Result<Example> in 
         return dict.resourceMap(Example.init)
       }
     }
     
   }
   ```

4. Enjoy a nice call-side experience.

   ```swift
   // load all `Example` entities
   let resourceCollection = Example.all
   service.load(resourceCollection) { result in
     switch result {
       case .success(let examples): /* do something */
       case .error(let error): 	 /* do something */
     }
   }
   ```

   ```swift
   // load the `Example` with id 9
   let resource = Example.specific(with: 9)
   service.load(resource) { result in
     switch result {
       case .success(let example): /* do something */
       case .error(let error): 	/* do something */
     }
   }
   ```

