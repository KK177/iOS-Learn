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
 
## 网络
### http/https/dns
- https是会对url进行加密处理
- dns是域名解析系统，会对域名进行解析成IP地址，比如百度的域名www.baidu.com，dns就会将这个域名解析成百度的IP地址

### 断点下载

#### 使用原生的类NSURLSession实现断点下载
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

### 使用AFN实现断点下载，快捷方便

### 弱网优化
1.界面呈现优化
- 无网络提示
利用AFN的相关API时刻监测用户的网络状态，断网或者网络情况极差时及时告知用户当前的网络状况
- 加载前添加“正在加载的动画" 或者 先布局固定的UI图
- 善用状态切换的通知，为2G、3G、4G、5G或wifi下的不同网络状态展示不同的界面

2.网络请求优化
- 制定合理的超时时间，加快对超时的判断，减少等待时间，尽早重试
- 多子模块请求的“延迟性”
比如一个界面同时要展示不同的子模块，那么可以先去请求数据量小的，业务上要优先展示的模块
- 利用好缓存机制以及选择性更新机制
选择性更新机制：刷新请求数据时只截取未请求过的数据、页面的cell数据变动是更改对应的cell
- 预加载
比如tableView滑到相对位置就会去加载新的数据，但是这样会有另外一个问题：当前页面还没看完而且也没意愿去看更后的内容，但是应用已经发出请求去更新数据，导致发出了一个无谓的请求
- 从请求下手
做好下载/上传数据的缓存处理，比如下载数据先看缓存里是否已经有下载过的数据记录，然后请求还未下载到的数据

3.用户体验优化
- 固定的UI显示布局，加载时可预加载虚拟布局视图
- 弱网加载失败/空数据，可添加“重新加载”的按钮，或可增加下拉刷新操作


4.图片加载优化
- 使用更快的图片格式
 WebP格式：谷歌开发的一种旨在加快图片加载速度的图片格式，压缩图片后的体积只有JPEG的2/3，这能节省大量的服务器带宽资源和数据空间，但这是有损压缩。
- 根据网络状态呈现不同精度的图
 比如在2/3G使用低清晰度图片
- 也可以弱网情况下直接不加载图片，只显示文字

## 存储
### 文件系统与沙盒机制
iOS中每个应用都各自对应着一个沙盒，App之间是不可以相互访问沙盒。
沙盒里面有三个目录：
Document 存放应用运行时生成的并且需要保存的数据。注:iTunes或iCloud同步设备时会备份该目录
Library/Caches 存放应用运行时生成的并且需要保存的数据。注:iTunes或iCloud不同步
Library/Preferences 存放偏好设置。存放应用的设置信息。NSUserDefaults保存在该目录下。注:iTunes或iCloud同步设备时会备份该目录
tmp：存放应用运行时所需的临时数据。当应用没运行时，系统可能会自动清除该目录下的文件。在不需要这些文件时，应用要负责删除tmp中的文件，以免占用文件系统的空间。
[沙盒路径学习](https://www.jianshu.com/p/d0376fb9ec71)

### NSUserDefaults存储
NSUserDefaults用来存储用户设置、系统配置等一些轻量级数据，数据是明文存储在plist文件中的，因此是不安全，即时只是修改一对键值也要重新加载整个文件，因此不适合存储大量数据。它是单例的，也是线程安全的，是以key-value的形式存储在沙盒中，存储路径为Library/Perferences文件夹中。

支持的数据类型有NSString、NSNumber、NSDate、NSArray、NSDictionary、BOOL、NSInteger等系统定义的数据类型，如果要存放其他数据类型或自定义的对象，则必须将其转换NSData存储（这一过程其实其实叫做归档）。即时对象是NSArray或NSDictionary，他们存储的类型也应该是以上范围包括的。NSUserDefaults返回的对象是不可变的值，

NSUserDefaults数据库中其实是由多个层级的域组成的。当要读取一个键值的数据时，NSUserDefaults从上到下透过域的层级寻找正确的值，不同的域有不同的功能。默认是包含五个Domain（域），如下：
1.参数域：有最高优先权
2.应用域：是最重要的域，存储着App通过NSUserDefaults set。。。forKey添加的设置
3.全局域：存储着系统的设置
4.语言域：包括地区、日期等
5.注册域：较低的优先权，只有在应用域没有找到值时才从注册域去寻找。

当NSUserDefaults寻找某一个键值对时：先去应用域看是否能找到数据，如果在应用域找不到数据，那么就会从上到下逐层查询是否有对应数据。查询顺序为：参数域 -> 应用域 -> 全局域 -> 语言域 -> 注册域

### 文件读写
文件管理器（NSFileManager）：此类主要是对文件进行的操作（创建/删除/改名等）以及文件信息的获取
文件连接器（NSFileHandle）:此类主要是对文件内容进行读取和写入操作
NSFileManager 主要是对文件进行管理，而 NSFileHandle 是对文件内容进行管理
[NSFileManager学习](https://www.cnblogs.com/xs514521/p/6293078.html)
[NSFileHandle学习](https://www.jianshu.com/p/8249e3abcd4a)

### 数据流读写
大文件上传或者下载，如果一次性加载数据到内存中，会导致内存暴涨，所以需要使用输入输出流，建立起文件和内存中的管道，通过管道输入和输出数据。

在使用输入流：NSInputStream
输入流的代理是可以监听当前文件读取状态的：1.刚打开文件 2.正在读取文件 3.读取文件结束
```Objectivew-C
// 将输入流注册在当前的事件循环中 - 这样的好处是：每一次事件循环，代理就会去查询当前文件读取状态
// 如果不注册到当前的事件循环中，那么在没有数据读出时，代理也一直在阻塞等待数据的读出。
[inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
```
[Stream学习](https://www.jianshu.com/p/4e7575e977fb)

### 数据库
#### plist
1.基础数据类型 或者 Foundation框架内的对象大多数都能直接用plist进行存储 
#### 归档和解档
1.而对于自定义的对象，是不可以直接存储到plist文件中的。一般能直接存储到plist文件的对象都是可序列化对象（系统会自动将此对象转换成二进制数据），而要将自定义的对象转换成可序列化对象，那么就要对它进行归档和解档。
2.适合小量数据的存储，因为每一个归档和解档都是对全部数据进行重新的加载。
> 归档是将自定义对象转换成可序列化对象，解档是将二进制数据转为一开始自定义的对象。
> 归档和解档实现的前提是：该自定义对象遵循NSCoding协议
> 归档和解档最终也是可以将对象存储到沙盒里的
[归解档学习](https://www.jianshu.com/p/24856243d36a)

#### SQLite3 Core Data 和 Realm
[SQLite3学习](https://www.jianshu.com/p/b70e127497dc)
SQLite是在世界上使用的最多的数据库引擎，并且还是开源的。
Core Data是App开发者可以使用的第二大主要的iOS存储技术，相对于SQLite来说，Core Data省去了写SQL语句的麻烦。
Realm是比较新的产品。Realm的处理速度上和Core Data，SQLite的速度并不差，但是它的复杂度相对Core Data，SQLite来说是更加简单，但是Realm会加大App的体积，官方文档上说的Realm库文件大概是1M的体积。
[realm学习1](https://www.jianshu.com/p/6704afc62d6c)
[realm学习2](https://www.jianshu.com/p/ec2bc15b7c92)

## 线程
### NSTHread、GCD、NSOperation
### 线程之间的通信
线程间通信：在一个进程中，线程往往不是独立存在的，多个线程之间需要经常进行通信。
线程间通信的体现：
    1.1个线程传递数据给另1个线程
    2.在1个线程中执行完特定任务后，转到另1线程继续执行任务
    
线程间通信的常用方法
```swift
- (void)performSelectorOnMainThread:(SEL)aSelector withObject:(id)arg waitUntilDone:(BOOL)wait;

- (void)performSelector:(SEL)aSelector onThread:(NSThread *)thr withObject:(id)arg waitUntilDone:(BOOL)wait;
```

线程间通信示例


