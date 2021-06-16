//
//  YDownLoadTool.swift
//  swiftBSL
//
//  Created by iiik- on 2021/6/12.
//

import UIKit

//缓存文件路径
public let YCachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
//临时文件路径
public let YTmpPath = NSTemporaryDirectory();

class YDownLoadTool: NSObject, URLSessionDelegate,URLSessionTaskDelegate,URLSessionDataDelegate {
    
    lazy var session:URLSession = {
        let sessionConfiguration = URLSessionConfiguration.default
        let session:URLSession = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: .main)
        return session
    }()
    
    var dataTask:URLSessionDataTask? = nil
    
    var downLoadPath:String = ""
    var tempLoadPath:String = ""
    
    var tempSize:CLongLong = 0
    var totalSize:CLongLong = 0
    
    var outputStream:OutputStream? = nil
    
    func downLoader(url: URL) {
        guard url.absoluteString != nil else {
            return
        }
        let fileName:String = url.lastPathComponent
        //下载完成的路径
        let downLoadPath = String(format: "%@&@", YCachePath,fileName)
        //下载文件的临时路径
        let tempLoadPath = String(format: "%@%@", YTmpPath,fileName)
        
        //先判断之前是否已经下载过
        if YFileTool.fileExist(fileNmae: downLoadPath) {
            return
        }
        //判断临时文件是否存在
        if !YFileTool.fileExist(fileNmae: tempLoadPath) {
            //从0字节开始请求资源
            downLoadFromUrl(url: url, offset: 0)
            return
        }
        //如果临时文件存在——说明之前下载中断过，现在重新下载
        //获取已下载文件大小，重新下载
        self.tempSize = YFileTool.fileSize(filePath: tempLoadPath)
        downLoadFromUrl(url: url, offset: self.tempSize)
    }
    
    //0字节开始从url下载资源
    func downLoadFromUrl(url: URL, offset:CLongLong) {
        let request = NSMutableURLRequest(url: url as URL, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 0)
        request.setValue(String(format: "bytes=%lld", offset), forHTTPHeaderField: "Range")
        self.dataTask = self.session.dataTask(with: request as URLRequest)
        self.dataTask?.resume()
    }
    
    //请求数据完成后调用该方法
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if error == nil {
            YFileTool.moveFile(curPath: self.tempLoadPath, toPath: self.downLoadPath)
            YFileTool.deleteFile(path: self.tempLoadPath)
            self.outputStream?.close()
            print("下载完成")
        }else {
            print("下载失败")
        }
    }
    
    //持续接受数据时调用的方法
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let uintData = [UInt8](data)
        self.outputStream?.write(UnsafePointer<UInt8>(uintData), maxLength: uintData.count)
    }
    
    //收到服务器响应——准备开始下载时调用
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        //将本地缓存大小与文件总大小进行比对
        //如果本地缓存大小 > 文件总大小，那么就要重新下载文件
        //如果本地缓存大小 = 文件总大小，表示已经下载好了，取消本次下载
        //如果本地缓存大小 < 文件总大小，就开始断点下载
        let httpResponse:HTTPURLResponse = response as! HTTPURLResponse
        //请求中的Content-Length指的是请求总大小，不是要下载资源的大小
        //content-range是要下载的资源的大小
        self.totalSize = httpResponse.allHeaderFields["Content-Length"] as! CLongLong
        let range:String = httpResponse.allHeaderFields["content-range"] as! String
        if range.count != 0 {
            self.totalSize = range.components(separatedBy: "/").last as! CLongLong
        }
        //本地文件大小 = 文件总大小
        if self.tempSize == self.totalSize {
            //将临时文件移到缓存文件
            YFileTool.moveFile(curPath: tempLoadPath, toPath: downLoadPath)
            completionHandler(.cancel)
            return
        }
        //本地文件大小 > 文件总大小
        if self.tempSize > self.totalSize {
            YFileTool.deleteFile(path: self.tempLoadPath)
            completionHandler(.cancel)
            downLoader(url: (response.url)! as URL)
            return
        }
        //本地文件大小 < 文件总大小，从本地大小开始下载
        //使用输出流一段一段地下载数据，有利于降低内存峰值
        self.outputStream = OutputStream.init(toFileAtPath: self.tempLoadPath, append: true);
        self.outputStream?.open()
        completionHandler(.allow)
    }

}
