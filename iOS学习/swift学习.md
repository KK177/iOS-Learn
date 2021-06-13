[TOC]
# swift学习
## as类型转换符
as类型转换符包括as，as？，as！
- as是向上转型

```swift
class Class {
    
}
class person:Class {
    
}
var test1:person = person()
let test2 = test1 as Class //将test1向上转换为Class类型然后赋值给了test2
```

- as？和 as！是向下类型转换：as？向下类型转换之后返回的是一个可选值，转型失败则会返回nil，而as！向下类型转换如果失败会直接crash

```swift
class Class {
    
}
class person:Class {
    
}
var test1:Class = person()
let test2 = test1 as? person
let test3 = test1 as! person
```

## ??符号
？？ 为swift的空合并运算符
a ?? b 
a要是可选项，b可以是可选项，也可以不是可选项
a 和 b 的存储类型要一样
当a为nil时，就会返回b
当a不为nil时，就会返回a
如果b不是可选项，返回a时会自动解包

## Foundation框架
swift新建的文件默认都导入了UIKit框架，而UIKit框架里导入了Foundation框架

## 关于import
在swift中是不需要import自己在工程中创建的文件的，相反如果import了自己创建的文件，就会提示报错。
而如果引入的是由cocoaPods导入的第三方库，那么就需要用到import，比如我导入了SDWebImage这个框架，那么如果在文件中用到，就要import SDWebImage。

## 实例方法和类方法
OC中有实例方法和类方法，swift中也有实例方法和类方法
OC中用+表示类方法，用-表示实例方法
swift中有class / static 来表示类方法
```swift
//用了class修饰fileExist标明fileExist是一个类方法
    class func fileExist(fileNmae: String) -> Bool {
        guard fileNmae.count != 0 else {
            return false
        }
        return FileManager.default.fileExists(atPath: fileNmae)
    }
```

## 懒加载
swift中的懒加载标志符为lazy，懒加载实际上执行的是一个闭包
swift中闭包的表达形式为
```swift
{ (parameters) -> return type in
    statements
}
```
懒加载🌰
```swift
//后面那部分其实相当是一个闭包
    lazy var session:URLSession = {
        let sessionConfiguration = URLSessionConfiguration.default
        let session:URLSession = URLSession(configuration: sessionConfiguration, delegate: self, delegateQueue: .main)
        return session
    }()
//将上述代码进行转换，可以明显看出其实懒加载执行的就是一个闭包
    let blk = { () -> URLSession in
        let sessionConfiguration = URLSessionConfiguration.default
        let session:URLSession = URLSession(configuration: sessionConfiguration, delegate:nil, delegateQueue: .main)
        return session
    }
    lazy var session = blk()
```

