//
//  IVTencentNetwork.swift
//  IotVideoDemo
//
//  Created by ZhaoYong on 2020/3/10.
//  Copyright © 2020 Tencentcs. All rights reserved.
//

import Foundation
import AFNetworking
import SwiftyJSON

public enum IVTencentNetworkRequestType: String {
    case GET  = "GET"
    case POST = "POST"
}

public typealias IVTencentNetworkResponseHandler = ((_ json: String?, _ error: NSError?) -> Void)?


// yunApi 网络请求类
public class IVTencentNetwork: AFHTTPSessionManager {
    private var host = "http://14.22.4.147:80/"
    var secretId = ""
    var secretKey = ""
    var token = ""
    public static let shared: IVTencentNetwork = {
        let instance = IVTencentNetwork()
        instance.responseSerializer.acceptableContentTypes = NSSet(objects: "application/json", "text/html", "text/json", "text/javascript", "text/plain","application/octet-stream") as? Set
        return instance
    }()
    
    public override func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        //不校验证书 - 信任所有证书
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}

extension IVTencentNetwork {
    public func request(methodType: IVTencentNetworkRequestType,
                        action: String,
                        params: [String: Any]?,
                        response:IVTencentNetworkResponseHandler
    ) {
        let urlPath = self.host
        
        self.setupHeader(methodType: methodType, params: params, action: action)
        
        let success = {(task: URLSessionTask, json: Any?) -> () in
            if let res = response {
                if json == nil {
                    res(nil, NSError(domain: "", code: 997, userInfo: nil))
                    return
                }
                if let json = json, let jsonObj = json as? [String: Any], let code:Int = jsonObj["code"] as? Int, code != 0 { //code 不等于0时，返回错误信息
                    res(nil, NSError(domain: "", code: 998, userInfo: nil))
                    return
                }
                if let jsonData = try? JSONSerialization.data(withJSONObject: json!, options: []) {
                    let str = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)
                    print(str ?? "http call back empty")
                    res(str! as String, nil)
                } else {
                    res(nil, NSError(domain: "", code: 999, userInfo: nil))
                }
            }
        }
        let failure = {(task: URLSessionTask?, error: Error) -> () in
            if let res = response {
                res(nil, error as NSError)
            }
        }
        switch methodType {
        case .GET:
            get(urlPath, parameters: params, progress: nil, success: success, failure: failure)
        case .POST:
            post(urlPath, parameters: params, progress: nil, success: success, failure: failure)
        }
    }
}
extension IVTencentNetwork {
    func setupHeader(methodType: IVTencentNetworkRequestType, params: [String: Any]?, action: String!) {
        
        requestSerializer = AFJSONRequestSerializer()
        
        var headerParams = [String: String]()
        
        let region = "ap-guangzhou"
        let version = "2019-11-26"
        let endpoint = "iotvideo.tencentcloudapi.com"
        let contentType = "application/json; charset=utf-8"
        let canonicalUri = "/"
        let canonicalQueryString = ""
        let canonicalHeaders = "content-type:" + contentType + "\nhost:" + endpoint + "\n"
        let signedHeaders = "content-type;host"
        
        do {
            let jsonPayloadData = try JSONSerialization.data(withJSONObject: params ?? [], options: [])
            let jsonPayload = NSString(data: jsonPayloadData, encoding: String.Encoding.utf8.rawValue)
            let hashedRequestPayload = (jsonPayload! as String).sha256()
            let canonicalRequest = methodType.rawValue + "\n" + canonicalUri + "\n" + canonicalQueryString + "\n"
            + canonicalHeaders + "\n" + signedHeaders + "\n" + hashedRequestPayload;
            
            let timestamp = Date().timeIntervalSince1970
            let timestampStr = "\(Int(timestamp))"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            let date = dateFormatter.string(from: Date(timeIntervalSince1970: timestamp))
            let service = endpoint
            let credentialScope = date + "/" + service + "/" + "tc3_request"
            let hashedCanonicalRequest = canonicalRequest.sha256()
            let stringToSign = "TC3-HMAC-SHA256\n" + timestampStr + "\n" + credentialScope + "\n" + hashedCanonicalRequest
            let secretDate = date.hmac(algorithm: .SHA256, key: "TC3" + secretKey)
            let secretService = service.hmac(algorithm: .SHA256, key: secretDate)
            let secretSigning = "tc3_request".hmac(algorithm: .SHA256, key: secretService)
            let signature = stringToSign.hmac(algorithm: .SHA256, key: secretSigning).lowercased()
            let authorization = "TC3-HMAC-SHA256 " + "Credential=" + secretId + "/" + credentialScope + ", "
            + "SignedHeaders=" + signedHeaders + ", " + "Signature=" + signature
         

            headerParams["Host"]           = endpoint
            headerParams["Content-Type"]   = contentType
            headerParams["Authorization"]  = authorization
            headerParams["X-TC-Action"]    = action
            headerParams["X-TC-Timestamp"] = timestampStr
            headerParams["X-TC-Version"]   = version
            headerParams["X-TC-Region"]    = region
            headerParams["X-TC-RequestClient"] = version
            headerParams["X-TC-Token"]     = token
            for headerParam in headerParams {
                requestSerializer.setValue(headerParam.value, forHTTPHeaderField: headerParam.key)
            }
            //print(requestSerializer.httpRequestHeaders, params)
        } catch  {
            print(error)
        }
    }
    
    
    
    /// 获取唯一识别码，APP卸载后重置
    func getUniqueId() -> String {
        let userDefault = UserDefaults.standard
        var uuid = userDefault.string(forKey: "IOTVIDEO_UUID")
        if let uuid = uuid {
            return uuid
        }
        uuid = NSUUID().uuidString
        userDefault.set(uuid!, forKey:"IOTVIDEO_UUID")
        return uuid!
    }
    
}

func parseJson(_ json: String?) -> JSON? {
    let json = JSON(parseJSON: json!)
    if let errorCode = json["Response"]["Error"]["Code"].string {
        ivHud("\(errorCode) : \(json["Response"]["Error"]["Message"].stringValue)")
        return nil
    }
    return json
}

