//
//  RestAPIController.swift
//
//  Created by apple on 07/02/19.
//  Copyright © 2019 Aditya. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

internal var CurrentBaseUrl: URL = RestAPIController.BaseAPIUrl


class RestAPIController {
    public static let sharedInstance = RestAPIController()
    
    let decoder = JSONDecoder()

    public static let BaseAPIUrl     = URL(string: "http://")!
    public static let imageBaseUrl  = URL(string: "http://")!

    //Private properties
    fileprivate var af: Alamofire.SessionManager
    fileprivate var opQueue: OperationQueue
    fileprivate var bgOpQueue: OperationQueue
    
    public var baseUrl: URL {
        get {
            return CurrentBaseUrl
        }
    }
    
    public init() {
        let config = URLSessionConfiguration.default
        self.af = Alamofire.SessionManager(configuration: config)
        self.opQueue = OperationQueue()
        self.opQueue.name = "RCKService OpQ"
        
        
        //Add any default background operations
        self.bgOpQueue = OperationQueue()
        self.bgOpQueue.name = "RCKService BgOpQ"
        
    }
    
    /// Execute a network request with thes erver
    ///
    /// - Parameter request; URLRequset to make
    /// - Parameter completion: a completion block containing the rseponse data, JSON data (on success) and any error codes.  This completion block wil run on runQueue, the same DispatchQueue that the state machine execute son.
    
    class func startRequest(request:RestAPIRouter, completion: @escaping (_ response: ServerResponse)->Void = { _ in }) {
        
        let af = RestAPIController.sharedInstance.af
        
        af.request(request)
            .validate(statusCode: 200..<600)
            .validate(contentType: ["application/json; charset=utf-8","text/plain"])
            .responseJSON { response in
                let serverResponse: ServerResponse
                
                switch response.result
                {
                case .success(let value ):
                    serverResponse = ServerResponse(json: JSON(value),
                                                    error: nil,
                                                    reachiblity: true,
                                                    response: response)
                case .failure(let error):
                    serverResponse = ServerResponse(json: nil,
                                                    error: error,
                                                    reachiblity: true,
                                                    response: response)
                    
                    let body: String
                    if let data = response.data {
                        body = String(data: data, encoding: .utf8)!
                    }else {
                        body = "(no body)"
                    }
                    print("Server ERROR: \(error.localizedDescription)\n\(body)\n")
                    ActivityIndicatorS.shared.stopProgressHUD()
                }
                
                completion(serverResponse)
        }
    }
    
    
    class func requestForUploadProfileWith(requestUrl: RestAPIRouter, parameters: [String: Any], indicator: ActivityIndicatorS?, completion: @escaping (_ success: Bool, _ serverResponseData: JSON?, _ response: DataResponse<Any>?) -> Void ) {
        
        let requestURL = requestUrl.urlRequest?.url
        
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            
            for (key, value) in parameters {
                if key == "action" { continue }
                if key == "file" {
                    if let data = parameters["file"] as? Data {
                        multipartFormData.append(data, withName: key, fileName: "\(Date().timeIntervalSince1970).jpeg", mimeType: "image/jpeg")
                    }
                    continue
                }
                multipartFormData.append((value as! String).data(using: String.Encoding.utf8)!, withName: key)
            }
        }, usingThreshold: UInt64.init(), to: requestURL!, method: .post)
        { (result) in
            
            switch result {
            case .failure(let error):
                print("UploadImageController.requestWith.Alamofire.usingThreshold:", error)
                completion(false, nil, nil)
                
            case .success(request: let upload, _, _):
                if let indicatorS = indicator {
                    upload.uploadProgress(closure: { (progress) in
                        let percent = Int((progress.fractionCompleted)*100)
                        indicatorS.hud.textLabel.text = "\(percent)% \nUploading"
                        print("Upload Progress: \(progress.fractionCompleted)")
                    })
                }
                
                upload.responseJSON(completionHandler: { (response) in
                    switch response.result {
                    case .failure(_):
                        completion(false, JSON(response), response)
                        
                    case .success(_):
                        guard let data = response.data else { return }
                        do {
                            completion(true, JSON(data), nil)
                        }
                    }
                })
            }
            
        }
    }
    
}


public struct ServerResponse {
    let json: JSON?
    let error: Error?
    let reachiblity: Bool?
    let response: DataResponse<Any>?
}
public enum ServerError: Error {
    case generalError(String)
}

class Connectivity {
    class var isConnectedToInternet:Bool {
        return NetworkReachabilityManager()?.isReachable ?? false
    }
}
