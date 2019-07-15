//
//  RestAPIRouter.swift
//
//  Created by apple on 07/02/19.
//  Copyright © 2019 Aditya. All rights reserved.
//

import Foundation
import Alamofire

public enum RestAPIRouter: URLRequestConvertible {
    case genericApi()
    case login([String: Any]) //Contains Parameters

    var method: HTTPMethod {
        switch self {
        case .genericApi:           return .get
        case .login:                return .post
        }
    }
    
    var path: String {
        switch self {
        case .genericApi:
            return "/generic/url"
        case .login:
            return "login"
        }
    }
    
    public func asURLRequest() throws -> URLRequest {
        let url = RestAPIController.BaseAPIUrl.appendingPathComponent(self.path)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = self.method.rawValue
        
        print("---------Request Details---------")
        
        switch self {
        case .genericApi():
            let url = RestAPIController.BaseAPIUrl.appendingPathComponent(self.path)
            let finalURL = url.append("action", value: "apiurl") // Query params is been appended

            urlRequest = URLRequest(url: finalURL)
            urlRequest.httpMethod = self.method.rawValue // GET Method is been set
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: nil)
            
            urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            print("urlRequest:\(urlRequest)")
            return urlRequest
        case .login(let params):
            print("---------Params------\n \(String(describing: params))")
            var url = RestAPIController.BaseAPIUrl.appendingPathComponent(self.path)
            for (key, value) in params {
                let finalUrl = url.append(key, value: value as? String)
                url = finalUrl
            } // All Parameters are been attached as Query Parameters
            
            urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = self.method.rawValue // POST Method
            urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            print("urlRequest:\(urlRequest)")
            return urlRequest
        
        }
    }
}

