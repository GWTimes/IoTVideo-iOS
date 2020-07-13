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
//    private var host = "http://cvm.tencentcloudapi.com"
//    private var host = "http://14.22.4.147:80/"
    private var host = "https://iotvideo.tencentcloudapi.com/"
    var secretId  = ""
    var secretKey = ""
    var token = ""
    
    public static let shared: IVTencentNetwork = {
        let instance = IVTencentNetwork()
        instance.responseSerializer.acceptableContentTypes = NSSet(objects: "application/json", "text/html", "text/json", "text/javascript", "text/plain","application/octet-stream") as? Set
        instance.requestSerializer = AFJSONRequestSerializer()
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
            if json == nil {
                response?(nil, NSError(domain: "", code: 997, userInfo: nil))
                return
            }
            if let json = json, let jsonObj = json as? [String: Any], let code:Int = jsonObj["code"] as? Int, code != 0 { //code 不等于0时，返回错误信息
                response?(nil, NSError(domain: "", code: 998, userInfo: nil))
                return
            }
            if let jsonData = try? JSONSerialization.data(withJSONObject: json!, options: []) {
                let str = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue)
                logInfo(action + ": \n" + String(str ?? "http call back empty"))
                response?(str! as String, nil)
            } else {
                response?(nil, NSError(domain: "", code: 999, userInfo: nil))
            }
        }
        let failure = {(task: URLSessionTask?, error: Error) -> () in
            response?(nil, error as NSError)
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
        
//temp
//        let action = "DescribeInstances"
//        secretId  = "AKIDz8krbsJ5yKBZQpn74WFkmLPx3EXAMPLE"
//        secretKey = "Gu5t9xGARNpq86cd98joQYCN3EXAMPLE"
        
        if self.secretId.isEmpty || self.secretKey.isEmpty {
            secretId  = UserDefaults.standard.string(forKey: demo_secretId) ?? ""
            secretKey = UserDefaults.standard.string(forKey: demo_secretKey) ?? ""
        }
        
        if self.token.isEmpty {
            let loginToken = UserDefaults.standard.string(forKey: demo_loginToken)
            if let loginToken = loginToken, !loginToken.isEmpty, loginToken.count > 1 {
                token = loginToken
            }
        }
        
        var headerParams = [String: String]()
       
        
        let region = "ap-guangzhou"
        let service = "iotvideo"
        let version = "2019-11-26"
        let algorithm = "TC3-HMAC-SHA256"
        
        do {
            // ************* 步骤 1：拼接规范请求串 *************
            // POST:示例
            
            let httpRequestMethod = methodType.rawValue
            let canonicalUri = "/"
            let canonicalQueryString = ""
            let contentType = "application/json; charset=utf-8"
            let hostStr = URL(string: host)?.host ?? ""
            let canonicalHeaders = "content-type:" + contentType + "\n" + "host:" + hostStr + "\n"
            let signedHeaders = "content-type;host"
            
            let jsonPayloadData = try JSONSerialization.data(withJSONObject: params ?? [], options: [])
            let jsonPayload = NSString(data: jsonPayloadData, encoding: String.Encoding.utf8.rawValue)
            let hashedRequestPayload = (jsonPayload! as String).hashHex(by: .SHA256)
            let canonicalRequest = httpRequestMethod + "\n" + canonicalUri + "\n" + canonicalQueryString + "\n"
                       + canonicalHeaders + "\n" + signedHeaders + "\n" + hashedRequestPayload;
//            logDebug("第一步：", canonicalRequest)
            
            // ************* 步骤 2：拼接待签名字符串 *************
                        
            let timestamp = Date().timeIntervalSince1970
            let timestampStr = "\(Int(timestamp))"
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            let date = dateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(timestamp)))
            
            let credentialScope = date + "/" + service + "/" + "tc3_request"
            let hashedCanonicalRequest = canonicalRequest.hashHex(by: .SHA256)
            let stringToSign = algorithm + "\n" + timestampStr + "\n" + credentialScope + "\n" + hashedCanonicalRequest
            
//            logDebug("第二步：", stringToSign)
            
            // ************* 步骤 3：计算签名 *************
            let secretDate = date.hmac(by: .SHA256, key: ("TC3" + secretKey).bytes)
            let secretService = service.hmac(by: .SHA256, key: secretDate)
            let secretSigning = "tc3_request".hmac(by: .SHA256, key: secretService)
            let signature = stringToSign.hmac(by: .SHA256, key: secretSigning).hexString.lowercased()
            
//            logDebug("第三步：\n", signature)
            
            let authorization = "TC3-HMAC-SHA256 " + "Credential=" + secretId + "/" + credentialScope + ", "
            + "SignedHeaders=" + signedHeaders + ", " + "Signature=" + signature
            
//            logDebug("第四步：\n", authorization)

            headerParams["Host"]           = hostStr
            headerParams["Authorization"]  = authorization
            headerParams["Content-Type"]   = contentType
            headerParams["X-TC-Action"]    = action
            headerParams["X-TC-Timestamp"] = timestampStr
            headerParams["X-TC-Version"]   = version
            headerParams["X-TC-Region"]    = region
            
            if !self.token.isEmpty {
                headerParams["X-TC-Token"] = token
            }
            
            for headerParam in headerParams {
                requestSerializer.setValue(headerParam.value, forHTTPHeaderField: headerParam.key)
                
                logDebug(headerParam.key, "=" , headerParam.value)
            }
            logDebug("body = ",jsonPayload!)
            //print(requestSerializer.httpRequestHeaders, params)
        } catch  {
            logError(error)
            showError(error)
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
