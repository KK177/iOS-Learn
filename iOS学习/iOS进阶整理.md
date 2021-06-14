[TOC]
# iOS技术栈
## 内存
### 内存泄漏
常见的内存泄漏情况：
1.对象之间的循环引用问题
2.block的循环引用，`block`在copy时都会自动对对象进行强引用，因此有必要对对象进行weak操作
3.delegate的循环引用，一般将delegate属性声明为weak
4.NSTimer会对target有强引用
5.通知的使用
> 在iOS9之后，一般我们是不用去移除通知的观察者，但是如果使用的监听通知的方式为`addObserverForName:(nullable NSNotificationName)name object:(nullable id)obj queue:(nullable NSOperationQueue *)queue usingBlock`,这种监听通知的方式，通知中心会自动对target进行retain，那么ViewController执行dealloc方法时就需要移除观察者.

6.内存泄漏的查询方法
- Analyze静态分析（command + shift + b）
- Leak动态分析（product - profile - Leak）
- 借用第三方库或者插件来进行内存泄漏分析

### 缓存管理
为了让用户在使用App时的体验更好，开发者一般都是要做好缓存工作的，缓存包括内存缓存和磁盘缓存。内存缓存一般采用NSCache，而磁盘缓存就是将数据写进应用的沙盒里面，默认情况，每个沙盒含有3个文件夹：Documents，Library和tmp。
> Documents：苹果建议将程序中建立的活在程序中浏览到的文件数据保存在该目录下。iTunes备份和恢复的时候会包括此目录
> Library：存储程序的默认设置和其他状态信息
> Library/Caches：存放缓存文件，iTunes备份和恢复时不会包括此目录，应用程序结束后也不会删除此目录下的文件
> Library/preferenes：程序的偏好设置文件
> tmp：存放临时数据文件，应用程序杀死之后会自动删除，iTunes不会备份此目录的文件

磁盘缓存中获取文件路径的方法
```Objective-c
获取Caches目录路径的方法：
//NSCachesDirectory获取到了Cache目录
//NSUserDomainMask表示主目录
//YES表示展开目录
NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
NSString *cachesDir = [paths objectAtIndex:0];
```

### 引用计数/垃圾回收
现在被广泛采用的内存管理机制主要有GC和RC两种。
- GC（Garbage Collection）垃圾回收机制，定期查找不再需要的对象，然后进行回收，释放对象占用的内存。
- RC（Reference Counting）引用计数机制。采用引用计数来管理对象的内存。当持有对象时，引用计数➕1，当不需要持有对象时，引用计数➖1，当引用计数为0⃣️时，该对象就会被系统回收，释放内存。
- 而在iOS上采用的内存管理机制是RC模式


#### 引用计数下的MRC
MRC模式下，开发者需要**手动**控制对象的引用计数来实现内存管理
主要的内存管理语句有`retain`,`release`,`autorelease`
`retain`是持有对象，使该对象的引用计数➕1
`release`是释放对该对象的引用，使该对象的引用计数➖1
`autorelease`也是释放对该对象的引用，但是引用计数➖1的时机是不确定的，在Runloop事件循环到了之后就会对对象进行释放。
在MRC模式下，alloc/new/copy/mutableCopy方法创建对象并持有对象，其他方法创建的对象会被自动注册到autoreleasepool，在一定时机之后就会被释放掉
四种规则
- 创建并持有对象
在alloc方法下会自动持有该对象

```objective-c
    id obj = [NSObject alloc] init]; // 创建并持有对象，RC = 1
    /*
     * 使用该对象，RC = 1
     */
    [obj release]; // 在不需要使用的时候调用 release，RC = 0，对象被销毁
```
- 可以使用retain持有对象

```Objective-c
    /* 正确的用法 */

    id obj = [NSMutableArray array]; // 创建对象但并不持有，对象加入自动释放池，RC = 1

    [obj retain]; // 使用之前进行 retain，对对象进行持有，RC = 2
    /*
     * 使用该对象，RC = 2
     */
    [obj release]; // 在不需要使用的时候调用 release，RC = 1
    /*
     * RunLoop 可能在某一时刻迭代结束，给自动释放池中的对象调用 release，RC = 0，对象被销毁
     * 如果这时候 RunLoop 还未迭代结束，该对象还可以被访问，不过这是非常危险的，容易导致 Crash
     */
```
 - 调用release，对象的RC会➖1
 - 调用autorelease，对象的RC不会立即➖1，而是将对象添加进自动释放池，它会在一个恰当的时机自动给对象调用release，所以autorelease相当于延迟了对象的释放

#### 引用计数下的ARC
 ARC是一种编译器功能，它通过LLVM编译器和Runtime协作来进行自动管理内存。LLVM编译器会在编译时在合适的地方为OC对象插入retain，release，autorelease代码来自动管理对象的内存，省去了在MRC手动引用计数下手动插入这些代码的工作，减轻了开发者的工作量，让开发者可以专注于应用程序的代码、对象图以及对象间的关系上。
 [文章入口🔗](https://cloud.tencent.com/developer/article/1620348)
 
### 网络
#### http/https/dns
- https是会对url进行加密处理
- dns是域名解析系统，会对域名进行解析成IP地址，比如百度的域名www.baidu.com，dns就会将这个域名解析成百度的IP地址

#### 断点下载

##### 使用原生的类NSURLSession实现断点下载
大概的流程
```swift
//1.先看内存缓存里是否有下载好的数据，有的话结束下载，直接拿
//2.内存没缓存到，那么就根据url的后缀去拼接文件路径，去Cache目录下看是否存在下载好的记录，有就直接提取
//3.Cache目录下没记录，那么就去查找tmp目录下是否有临时文件，有的话：就在临时文件已下载好的bytes开始下载，将已经下载的bytes封装到urlRequest的请求头上，实现断点下载
//4.tmp目录下也没有记录，那就从0⃣️开始下载

//下载流程
//1.下载的时候利用OutPutStream将数据一段一段地写进tmp目录下的文件
//2.下载好之后，将tmp目录下的文件移到cache文件下，并根据实际情况看是否做内存缓存
```
具体代码
[代码](/Users/macbookpro/iOS-Learn/iOS学习/断点下载\ 代码 )