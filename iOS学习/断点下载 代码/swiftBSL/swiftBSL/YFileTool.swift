//
//  YFileTool.swift
//  swiftBSL
//
//  Created by iiik- on 2021/6/12.
//

import UIKit

class YFileTool: NSObject {
    //判断文件是否存在
    class func fileExist(fileNmae: String) -> Bool {
        guard fileNmae.count != 0 else {
            return false
        }
        return FileManager.default.fileExists(atPath: fileNmae)
    }
    
    //判断tmp临时文件中是否有下载继续
     class func fileSize(filePath:String) -> CLongLong {
        guard self.fileExist(fileNmae: filePath) else {
            return 0
        }
        do {
            let dict =  try  FileManager.default.attributesOfItem(atPath: filePath)
            return dict[FileAttributeKey.size] as! CLongLong
        } catch  {
            print(error)
        }
        return 0
    }
    
    //move文件：改变文件路径，将下载好的tmp文件转移到cache目录下
    class func moveFile(curPath: String, toPath: String) {
        guard YFileTool.fileSize(filePath: curPath) != 0 else {
            return
        }
        do {
            try FileManager.default.moveItem(atPath: curPath, toPath: toPath)
        } catch  {
            print(error)
        }
    }
    
    //移除文件
    class func deleteFile(path: String) {
        do {
            try FileManager.default.removeItem(atPath: path)
        } catch  {
            print(error)
        }
    }
}
