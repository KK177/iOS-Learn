[TOC]



### plist

不能直接将自定义模型存进plist里，要先将模型转字典才能存进去，要想直接存自定义模型可以试一下用归档和解档

### 属性

https://www.jianshu.com/p/2e3bd492ec1b

### new 和 alloc init 的区别

- new 和 alloc init 在功能上没有什么区别，都是分配内存完成初始化

- 差别在于

  >  1.采用new的方式只能采用默认的init完成初始化，而如果采用alloc init的方式可以用其他自定义的初始化方法
  >
  >  2.类调用alloc方法返回一个实例对象并分配好内存，再由实例对象区调用init方法完成初始化
  >
  >  3.alloc使用了Zone分配的内存会和相关联的对象在内存地址中相靠近，这样的好处是：调用时消耗更少的代价，提升了程序处理速度
  >
  >  > NSZone 是 用于维护一块用于对象内存分配及释放的内存池 的描述信息，进程默认的NSZone在启动时创建并将对象均分配在这里，但经过大量的内存分配和释放之后，可能会产生很多的内存碎片，在做新的内存分配的时候NSZone会试图去填补这些碎片，这个查找过程是需要时间开销的

### 数据类型 - NSObject

- 在OC中，我们使用的框架叫`Cocoa`，对应的iOS版本叫做`Cocoa Touch`，这两个框架内部代码部分是相同的，比如最基础也是最重要的`Foundation`框架

- `Foudation`框架中几乎所有对象都是以`NS`开头
- 在所有的NS对象中，最基础的类就是`NSObject`类，是所有`Cocoa`框架中所有对象的基类

### instancetype

- 返回类型为`instancetype`的函数 表示 返回值代表当前类的实例，比如在`NSObject`类中，`instacnetype`表示返`NSObject`的实例



### 野指针 空指针 僵尸对象

- 空指针是没有存储任何的内存地址
- 野指针指向一块内存地址，但这块内存地址不可用（野指针指向的对象已经被释放掉了），假如：指针A指向着对象B，B被释放之后，A仍然指向那块内存地址，但是指针A还是可以访问那块内存地址，但如果那块内存地址重新分配给了另一个指针，当指针A再次访问就是有`crash`
- 在OC中，如果对象被释放之后占用的内存没有被重写（重新分配给其他对象），那么该对象被称为僵尸对象



### nil Nil NULL NSNULL

- nil OC中对象的空指针
- Nil OC中类的空指针
- NULL C类型的空指针
- NSNULL 数值类的空对象



### Blocks

忘了重新看一下工作室多线程和内存管理的书

- Blocks是C语言的扩充功能，一句话来表示Blocks的扩充功能：带有自动变量（局部变量）的匿名函数
- 匿名函数就是不带名称的函数，C语言中是不允许这样的函数出现的
- Blocks的好处 不用另外去创建一个函数，简单明了，比如要给一个函数传递一个url，那么如果函数的最后一个参数是一个Blocks，我们就可以在Blocks里写明拿到url之后要去干嘛，这样就比较得直接。

#### Blocks语法

> Blocks的标记性符号：^插入记号

- ^`返回值类型` `参数列表` `表达式` 
- ^ `参数列表` `表达式` 
- ^ `表达式`

#### Blocks类型变量

```swift
   	//blocks是这个blocks块的变量名
		int (^blocks)(int) = ^(int count){
        return 1;
    };
```

#### 截取自动变量值

- blocks块里有变量num，那么Blocks就会保存该自动变量的瞬时值，当Blocks后面再去修改该自动变量的值是不会影响之前截取的值的

```swift
    int num = 10;
    void (^blocks)(void) = ^{
        NSLog(@"%d",num);
    };
    num = 20;
    blocks();
    //输出结果仍然为10
```

#### __block说明符

- 如果在Blocks里要修改自动变量的值，那么就需要借助__block，否则是会报错的

```swift
   __block int num = 10;
    void (^blocks)(void) = ^{
        num = 20;
        NSLog(@"%d",num);
    };
    blocks();
    //输出结果为20
```

#### 截获的自动变量

- 如果对Blocks截获的自动变量进行赋值就会产生编译错误（在没有使用__blocks修饰符的情况下）
- 但是如果截获的是OC对象，那么调用该对象的方法是不会报错的，赋值还是会报错

```swift
   	//array是一个NSMutableArray类的对象，而Blocks截获的变量值是一个NSMutableArray类的对象，那么用C语言描述，就是截获了NSMutableArray类对象的结构体实例指针，因此使用内部方法是不会产生编译错误的
		NSMutableArray *array = [[NSMutableArray alloc] init];
    void (^blocks)(void) = ^{
        [array addObject:@"s"];
    };
    blocks();
```

### Blocks的实现

- 将OC代码转换成C++之后（说是C++，其实也仅是使用了struct结构体，其本质是C语言源代码），发现Blocks在源代码里其实是一个结构体（OC对象本质是结构体，Blocks也是OC的对象）

> Blocks转换成C++之后，本质是一个impl_0结构体，内部包含了impl，desc_0结构体以及外部需要访问的变量
>
> 1.impl结构体存放的有
>
> ​	isa指针 isa保持该类的结构体实例指针（`对象`里的isa指针指向它的`类对象`，`类对象`里的isa指针指向它的`元类`，`元类`里保存的是怎么去创建一个`类对象`和`类方法`的信息，而`类对象`里的元数据保存的是如何去实例化一个`类的对象`）
>
> ​	Flags 标志
>
> ​	Reserved 今后版本升级所需的区域
>
> ​	FuncPtr Blocks块里执行代码的函数指针 —— 对应着func_0函数
>
> 2.desc_0结构体存放的有
>
> ​	reserved今后版本升级所需的区域
>
> ​	Block_size Block的大小
>
> 3.impl_0结构体存放的有
>
> ​	结构体impl的实例
>
> ​	结构体desc_0的实例
>
> ​    Impl_0的初始化方法 用于给impl，desc_0结构体的成员变量赋值
>
> 4.func_0函数存放的是
>
> ​	Blocks块里的执行代码块
>
> 实现
>
> ​	Blocks在初始化时，是调用impl_0函数的初始化，把函数指针func_0以及结构体实例指针desc_0_DATA作为函数的参数传进去（desc_0_DATA里存放的是impl_0结构体大小的数据）
>
> Blocks在调用时，实际上是使用函数指针调用函数（impl结构体里的FuncPtr）

#### 截获自动变量值

> - 初始化Blocks 就是对Blocks里的impl_0结构体进行初始化，而截获的自动变量会作为参数传进去 对 impl_0进行初始化
> - 而传进去的自动变量会作为impl_0结构体的成员变量，成员变量在赋值时只是把传进来的自动变量的值赋值过去——因为是无法在Block块修改值的
> - 自动变量在Blocks内外的数据类型都是一样的
> - 当在func_0函数中需要用到自动变量时 根据_cself->变量去获取成员变量 ——cself是C++的写法，可以理解为当前结构体实例



#### __block说明符

在Block里实现对自动变量重新赋值，有两种做法

做法1:

> 截获的自动变量是 全局变量 ，静态全局变量 或者 静态变量
>
> 如果截获的自动变量是 全局变量 或者 静态全局变量
>
> - 那么Blocks块里是可以直接访问自动变量的，没有做出任何的改变
>
> 如果截获的自动变量是静态变量
>
> - 在Blocks的结构体impl_0中会多出一个指向静态变量的指针，impl_0在初始化时会把静态变量的地址传进去，当需要对自动变量赋值时，是通过指针去访问静态变量的值，从而进行修改

做法2:

>利用__block修饰符修饰变量
>
>- Blocks里的impl_0结构体外会多出一个关于自动变量的结构体，该结构体里有一个isa指针，一个forwarding指针指向结构体自身，一个flags，一个size，还有一个值保存自动变量的值
>- 在Blocks初始化impl_0时会把自动变量的结构体指针以及指针的地址传进去
>- 当需要修改自动变量的值时，通过访问成员变量farwarding去访问结构体里的自动变量



#### Block存储域

- NSConcreteStackBlock -  Block对象存储在栈区

  - 没有直接指向Block的在栈区，比如下面的Block

  ```swift
   NSLog(@"%@",[ ^{NSLog(@"1");} class]);
  ```

  

- NSConcreteGlobalBlock- Block对象存储在程序的数据区域(.data区)

  > 1.在记述全局变量的地方有Block语法时
  >
  > 2.Block语法的表达式不使用应截获的自动变量

- NSConcreteMallocBlock- Block对象存储在堆区

  > 当变量作用域结束时，栈上的__block变量和Block也被废弃
  >
  > 而复制到堆上的__block变量和Block在变量作用域结束时不受影响

- 对Block调用copy方法

  > 1.栈上的Block会复制到堆上
  >
  > 2.堆上的Block复制，引用计数会增加
  >
  > 3.程序的数据区域上的Block复制后没有变化

- 在ARC模式下，大多数编译器会自动将Block从栈区拷贝到堆上

  - 但是如果向方法或者函数的参数里传递Block，编译器是不能进行
    - 向方法或者函数参数传里Block 有两个特例（Block已经被复制到堆区）
      - 1Cocoa框架的方法且方法名中含有usingBlock
      - GCD的API

- 手动对Block拷贝 调用copy方法

  - ARC模式下多次拷贝是没有问题的
  - 在不需要拷贝的情况将Block拷贝到堆会增加CPU的消耗

#### __block变量存储域

- 当Block从栈复制到堆上

  - 如果__block存储在栈上，Block复制之后,  _ _block会从栈复制到堆上并被Block持有
  - 如果__block存储在堆上，Block复制之后，_ _ _block无影响，还是被Block持有

- 当多个Block同时使用同一个__block，那么这么Block从栈复制到堆上时，也会同时持有_ _ _block变量

- 当堆上的Block被废弃，那么它使用的__block变量也会被释放

- 当堆上多个Block同时持有__block，那么当持有的这些Block都被废弃了，_ _ _block才会被销毁（这里相当于内存管理里的引用计数）

- __block变量从栈区复制到堆区后，变量的forwarding指针已经从指向栈区 的结构体转向指向堆区的结构体，那么无论是在Block块内还是外都可以访问到同一个_ _ _ block变量

  ```swift
      __block int val = 10;
      //从堆区访问val
      void (^blk)(void) = [^{++val;} copy];
      //从栈区访问val
      ++val;
  ```

  

#### 截获对象

> Block截获的对象实现超过它的变量作用域而存在

- Block虽然能够截获自动变量，但是如果变量超过它的变量作用范围就会被丢弃，那么调用Block程序就会崩溃

- 那么怎么做到尽管变量超过了它的作用范围，调用Block时仍然不会崩溃呢

- 利用Block的copy函数

  >1.对Block进行copy，那么Block就会从栈区复制到了堆区
  >
  >2.而Block内部：在impl_0结构体初始化时会生成一个id__strong对象的成员变量，有一个:_ _ _ strong修饰符修饰该对象（虽然说C语言结构体里不允许有_ _strong修饰符出现，但是OC运行时库能够准确把握Block的初始化和销毁时机，因此尽管带有strong修饰符，也可以恰当地初始化和丢弃）
  >
  >以及多出一个copy函数和dispose函数，copy函数用于捕获的对象的初始化，dispose函数用于对象的销毁，这两个函数都是自动调用的，在Block调用copy时会对捕获的对象进行初始化，在Block被丢弃时会自动调用dispose函数销毁对象




#### __block变量和对象

- __block说明符可指定任何类型的自动变量

  > 当__block修饰对象时
  >
  > - Block内部 会多出关于该对象的结构体，这结构体跟之前的自动变量不同的是，结构体内部会新增object_copy和object_dispose两个方法，而且结构体内部的对象会有__strong修饰
  > - 当Block被复制到堆时，会调用object_copy函数，让Block持有该对象，当堆上的Block被废弃时，会调用object_dispose函数，释放Block截获的对象
  > - 而如果该对象被__block修饰，Block从栈复制到堆时，____block也会从栈复制到堆，并使用object_copy(assign)函数去持有赋值给__block变量的对象，当堆上的_____block变量被废弃时，使用object_dispose函数，释放赋值给____block变量的对象

#### Block循环引用

- 在Block中使用附有__strong修饰符的对象类型自动变量，那么当Block从栈复制到堆时，该对象为Block持有，这样容易引起循环引用

  ```swift
  //这种就会造成循环引用 self持有对象blk，blk被copy之后从栈复制到堆上，blk捕获了由strong（默认是strong）修饰的对象self，并持有了self，因此就会造成循环引用
  @property (nonatomic, copy) void (^blk)(void);
  self.blk = ^{NSLog(@"%@",self);};
  self.blk = ^{NSLog(@"%@",self.view);};
  //上面两种都会造成循环引用
  ```

  

- 为了避免循环引用，可声明附有__weak修饰符的变量

  ```swift
  id __weak temp = self;
  self.blk = ^{NSLog(@"%@",temp);};
  ```

  

- 除了使用__weak来避免循环引用，还可以使用____block来避免循环引用

  图中的代码如果不执行Block是会造成循环引用的

  - 对象持有了Block
  - Block持有__block变量
  - __block变量持有对象，因此造成了循环引用

  但是执行了Block之后 是不会造成循环引用了，因为temp被置为nil

  <img src="/Applications/DoYourDataRecovery Recovered 202106091006/APFS_0001/Unknown/Users/macbookpro/Library/Containers/com.tencent.xinWeChat/Data/Library/Application Support/com.tencent.xinWeChat/2.0b4.0.9/0e01e663ae266b1753fc436daed5ba79/Message/MessageTemp/65a35f52e6f76b5882485ce0406cc140/OpenData/image-20210407191602412.png" alt="image-20210407191602412" style="zoom:50%;" />

#### copy/release

- 一般@property声明Block时都是用copy修饰

- ARC无效时，一般需要手动复制Block，利用copy方法进行复制，用release方法来释放Block

- 另外ARC无效时，__block说明符用来避免Block中的循环引用。

  > 当Block从栈复制到堆
  >
  > 若Block使用的变量为附有__block说明符的id类型或者对象类型的自动变量，不会被retain（不会被Block持有）
  >
  > 若Block使用的变量为没有__block说明赋的id类型或者对象类型的自动变量，就会被retain（被Block持有）

- 在ARC有效时和无效时__block说明符的用途有很大的区别





### tableViewCell自适应高度

- 自定义cell，并且cell内部的控件做好约束

- 设置``tableView.estimatedRowHeight``的值，这个值要尽量跟实际的cell的高度相近或者相等，这样效率会更高

  > ```swift
  > tableView.rowHeight = UITableViewAutomaticDimension;//给cell高度一个预估的值
  > tableView.estimatedRowHeight = 140;
  > ```
  >
  > 1.```estimatedRowHeight```这个值要尽量跟cell的高度相近
  >
  > 当```tableView```要显示时，先会根据要创建的cell的个数给每一个cell返回一个```estimatedRowHeight```高度，然后根据```estimatedRowHeight*count```去得出```tableView```的```contentsize```（```tableView```继承于`scrollView`），contentsize被赋值之后，cell才能够显示
  >
  > 2.因此，如果没有设置`estimatedRowHeight`那么就要先把cell的真实高度都算出来才能得出`contentsize`，这样`cell`才能够显示，这也会消耗一点时间以及损耗性能
  >
  > 3.由于一开始tableView的`contensize`并不是最终的值，那么`tableView`在滑动过程中`contensize`会不断得被更新，这样就可能会出现页面抖动的情况
  >
  > 4.解决页面抖动的情况
  >
  > - `estimatedRowHeight`贴近真的cell高度值
  >
  > - `estimatedRowHeight`设置为0，但就是有性能的损耗
  >
  >   ```swift
  >     _tableView.estimatedSectionHeaderHeight = 0;
  >     _tableView.estimatedSectionFooterHeight = 0;
  >     _tableView.estimatedRowHeight = 0;
  >   ```

- 没使用estimatedRowHeight

  > ```undefined
  > 1.先调用numberOfRowsInSection
  > 2.再调用heightForRowAtIndexPath
  > 3.再调用cellForRowAtIndexPath
  > ```

- 使用了estimatedRowHeight

  ```
  1.numberOfRowsInSection
  2.estimatedHeightForRowAtIndexPath
  3.cellForRowAtIndexPath
  4.heightForRowAtIndexPath
  ```

  

### UDID

> 所谓UDID指的是设备的唯一设备识别符，移动广告商和游戏[网络运营商](https://baike.baidu.com/item/网络运营商/10725392)往往需要通过UDID用来识别玩家用户，并对用户活动进行跟踪。

### GCD

#### 队列

```swift
dispatch_queue_t queue = dispatch_queue_create("gcdTest", DISPATCH_QUEUE_SERIAL);
//这也是创建了一个串行队列
dispatch_queue_t queue = dispatch_queue_create("net.bujige.testQueue", NULL);
```

- gcdTest 是队列的名字

- DISPATCH_QUEUE_SERIAL 表示串行队列

- DISPATCH_QUEUE_CONCURRENT表示并行队列

- ```swift
  dispatch_queue_t queue = dispatch_get_main_queue();
  //获取主队列，主队列就是串行队列
  ```

- ```swift
  dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
  //获取全局队列，是一个并发队列,可以理解为开辟了全局线程
  //DISPATCH_QUEUE_PRIORITY_DEFAULT 表示该队列的优先级为默认 0
  //DISPATCH_QUEUE_PRIORITY_HIGH 表示为高优先级 2
  //DISPATCH_QUEUE_PRIORITY_LOW 表示为低优先级 -2
  //DISPATCH_QUEUE_PRIORITY_BACKGROUND 表示为后台 INT16_MIN
  //第二个参数默认为0，暂时没什么用
  ```

#### dispatch_set_target_queue

有两个作用，一个是变更指定队列queue的优先级，第二个是可以做成队列的执行阶层

- 变更队列queue的优先级

  > 由于创建SERIAL或者CONcurrent队列都使用与默认优先级Global Disoatch Queue相同执行优先级的线程

```swift
//一般变更优先级是用在异步中的，如果用在同步中，是有执行顺序，不管优先级的   
dispatch_queue_t serialDiapatchQueue=dispatch_queue_create("com.GCD_demo.www", DISPATCH_QUEUE_SERIAL);
    dispatch_queue_t dispatchgetglobalqueue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        
    //第一个参数为要设置优先级的queu
    //第二个参数是参照物，既将第一个queue的优先级和第二个queue的优先级设置一样。
    dispatch_set_target_queue(serialDiapatchQueue, dispatchgetglobalqueue);
        
        
    dispatch_async(serialDiapatchQueue, ^{
        NSLog(@"我优先级低，先让让");
    });
        
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSLog(@"我优先级高,我先block");
    });
//打印出
//我优先级高,我先block
//我优先级低，先让让
```

- 可以做成队列的执行阶层

  可以理解为将三个队列加到了串行队列中，由原来的并发执行变成同步执行

  如果target queue是并发队列，那么三个队列加进去之后还是并发的

```swift
 //1.创建目标队列
        dispatch_queue_t targetQueue = dispatch_queue_create("test.target.queue", DISPATCH_QUEUE_SERIAL);
        
        //2.创建3个串行队列
        dispatch_queue_t queue1 = dispatch_queue_create("test.1", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_t queue2 = dispatch_queue_create("test.2", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_t queue3 = dispatch_queue_create("test.3", DISPATCH_QUEUE_SERIAL);
        
        //3.将3个串行队列分别添加到目标队列
        dispatch_set_target_queue(queue1, targetQueue);
        dispatch_set_target_queue(queue2, targetQueue);
        dispatch_set_target_queue(queue3, targetQueue);
        
        
        dispatch_async(queue1, ^{
            NSLog(@"1 in");
            [NSThread sleepForTimeInterval:3.f];
            NSLog(@"1 out");
        });
        
        dispatch_async(queue2, ^{
            NSLog(@"2 in");
            [NSThread sleepForTimeInterval:2.f];
            NSLog(@"2 out");
        });
        dispatch_async(queue3, ^{
            NSLog(@"3 in");
            [NSThread sleepForTimeInterval:1.f];
            NSLog(@"3 out");
        });
//打印结果
2021-04-15 10:50:09.942751+0800 basicLearn[4085:125000] 1 in
2021-04-15 10:50:12.946472+0800 basicLearn[4085:125000] 1 out
2021-04-15 10:50:12.946856+0800 basicLearn[4085:125000] 2 in
2021-04-15 10:50:14.948848+0800 basicLearn[4085:125000] 2 out
2021-04-15 10:50:14.949121+0800 basicLearn[4085:125000] 3 in
2021-04-15 10:50:15.949637+0800 basicLearn[4085:125000] 3 out
```

#### dispatch_after - GCD的延时方法

dispatch_after并不是在指定时间之后开始执行，而是在指定时间之后将任务添加到队列中

dispatch_after本身是一个异步函数，具有开辟新线程的能力

```swift
    //DISPATCH_TIME_NOW表示当前时间
		//ull 是C语言的数值字面量
		//NSEC_PER_SEC是以秒为单位 
		//NSEC_PER_MSEC是以毫秒为单位
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, 1ull * NSEC_PER_SEC);
    dispatch_after(time,dispatch_get_main_queue(), ^{
        NSLog(@"1");
        NSLog(@"%@",[NSThread currentThread]);
    });
    NSLog(@"q");
//打印
//q
//1（经过了1秒）
//线程
```



#### Dispatch Group

- 实现追加到队列中的多个处理全部结束后想执行结束处理，那么这时可以使用Dispatch Group

  等到并行执行的线程执行完之后 有一个结束处理

  ```swift
  //将Block添加到队列queue1，并指定这个Block属于这个group
  //当属于该group的Block都执行完之后，group就会检测到执行结束，就会把结束处理添加到queue中
  dispatch_group_async(group, queue1, ^{
          NSLog(@"1");
      });
  ```

  

  ```swift
   NSLog(@"begin");
      NSLog(@"%@",[NSThread currentThread]);
      
      dispatch_group_t group = dispatch_group_create();
      
      dispatch_queue_t queue1 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
      
      dispatch_queue_t queue2 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
      
      dispatch_group_async(group, queue1, ^{
          NSLog(@"1");
      });
  
      dispatch_group_async(group, queue2, ^{
          NSLog(@"2");
      });
  
      dispatch_group_notify(group, queue1, ^{
          NSLog(@"3");
      });
      
      NSLog(@"end");
  
  //最后输出为
  begin
  线程
  end
  1
  2
  3
  ```

  

#### dispatch_group_wait

- 阻塞当前线程，等指定的group里的任务都执行完成之后，才会继续往下执行

  ```swift
  NSLog(@"begin");
      NSLog(@"%@",[NSThread currentThread]);
      
      dispatch_group_t group = dispatch_group_create();
      
      dispatch_queue_t queue1 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
      
      dispatch_queue_t queue2 = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
      
      dispatch_group_async(group, queue1, ^{
          NSLog(@"1");
      });
  
      dispatch_group_async(group, queue2, ^{
          NSLog(@"2");
      });
  //阻塞了主线程，等group里的任务都执行完了之后再执行输出end的操作
      dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
      
      NSLog(@"end");
  ```

  

#### dispatch_barrier_async

- GCD的栅栏方法：相当于将queue里的任务分成了前后部分，栅栏前的任务执行完之后，才可以去执行栅栏后的任务

  ```swift
  NSLog(@"begin");
      
      
      dispatch_queue_t queue = dispatch_queue_create("net.bujige.testQueue", DISPATCH_QUEUE_CONCURRENT);
          
          dispatch_async(queue, ^{
              // 模拟耗时操作
              NSLog(@"1---%@",[NSThread currentThread]);      // 打印当前线程
          });
          dispatch_async(queue, ^{
              // 模拟耗时操作
              NSLog(@"2---%@",[NSThread currentThread]);      // 打印当前线程
          });
          
          dispatch_barrier_async(queue, ^{
                  // 模拟耗时操作
              NSLog(@"barrier---%@",[NSThread currentThread]);// 打印当前线程
          });
          
          dispatch_async(queue, ^{
                           // 模拟耗时操作
              NSLog(@"3---%@",[NSThread currentThread]);      // 打印当前线程
          });
          dispatch_async(queue, ^{
                          // 模拟耗时操作
              NSLog(@"4---%@",[NSThread currentThread]);      // 打印当前线程
          });
      NSLog(@"end");
      //输出 
  //begin
  //end
  //12顺序不定
  //barrier
  //34顺序不定
  ```

  

#### dispath_async

- 意味着“非同步”，就是把指定的Block“非同步”地追加到指定的Dispatch Queue中，dispatch_async不做任何等待
- dispatch_sync意味着同步

#### dispatch_apply

该函数按指定的次数将Block追加到指定的Dispatch Queue中，并等待全部处理执行结束

```swift
dispatch_apply(10, queue, ^(size_t index) {
            NSLog(@"%zu",index);
        });
NSLog(@"q");
//第一次参数 是指明 要重复的次数
//第二个参数 是指明 要添加到的队列
//第三个参数 是指明 次数的下标
//如果queue是串行的，那么就会按照次序输出，如果是并行的，就是没有次序输出，有利于提高效率
//只有dispatch_apply里的Block都执行完之后 才会去输出q，可以将dispatch_apply理解为dispatch_sync，相当于是同步的，但还是有开辟新的线程的
```

```objective-c
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    dispatch_async(queue, ^{
        dispatch_apply(10, queue, ^(size_t index) {
            NSLog(@"%zu",index);
        });
    });
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"%@",[NSThread currentThread]);
    });
//输出
//先随机输出dispatch_apply函数的Block的index值
//才会去输出线程
```

#### dispatch_suspend/dispatch_resume

当追加了大量处理到Dispatch Queue时，在追加处理的过程中，有时希望不执行已追加的处理，这时可以对queue进行挂起，挂起后，追加到Queue里但还没执行的处理会停止执行，恢复之后，queue里的处理能够继续执行

```swift
    //挂起队列
    dispatch_suspend(queue);
    //恢复队列
    dispatch_resume(queue);
```

#### Dispatch Semaphore

Dispatch Semaphore是GCD的信号量，用来管理对资源的并发访问

当信号量为0时等待，当信号量大于等于1时不等待

```objective-c
//第一个参数为信号量semaphore，判断当前信号量是否>=1若是，那么该信号量➖1，不用等待，如果信号量为0，那么要阻塞当前线程。
//第二个参数DISPATCH_TIME_FOREVER是dispatch_time_t类型，这个表示一直等待，当这个参数设置了一定时间之后，经过时间也是会继续执行的
//当信号量大于等于1或者超过一定的时间限制，会继续执行不等待
dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
```

```objective-c
//semaphore信号量会➕1
dispatch_semaphore_signal(semaphore);
```

- 信号量的使用有两大作用
- 保持线程同步 和 为线程加锁

##### 保持线程同步

```objc
dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
   dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

   __block int j = 0;
   dispatch_async(queue, ^{
        j = 100;
        dispatch_semaphore_signal(semaphore);
   });

   dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
   NSLog(@"finish j = %zd", j);
//最后输入j = 100
//Block块异步添加到了全局并发队列中，所以程序在主线程会跳过Block块（同时开辟子线程异步执行Block块），执行Block块外的代码dispatch_semaphore_wait，因为semaphore信号量的值为0，而且时间为DISPATCH_TIME_FOREVER，所以会阻塞当前线程（主线程），当子线程里的Block块执行完之后，信号量semaphore➕1，那么被阻塞的线程（主线程）会恢复执行，这样就保证了线程之间的同步
```

##### 为线程加锁

```objc
//queue创建是一个默认优先级的全局并发队列
dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
dispatch_semaphore_t semaphore = dispatch_semaphore_create(1);

for (int i = 0; i < 100; i++) {
     dispatch_async(queue, ^{
          // 相当于加锁
          dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
          NSLog(@"i = %zd semaphore = %@", i, semaphore);
          // 相当于解锁
          dispatch_semaphore_signal(semaphore);
      });
}
//当线程1执行到dispatch_semaphore_wait这一行时，semaphore的信号量为1，继续执行后面的输出语句，此时semaphore信号量➖1，如果在线程1执行NSLog输出语句时，线程2来访问，由于semaphore信号量已经为0，这么线程2只能等待，无法继续执行，知道线程1执行完dispatch_semaphore_signal，semaphore信号量➕1，那么线程2才能解除阻塞继续往下执行，这样就可以保证只有一个线程在执行NSlog这一行代码，所以就相当于给线程加锁
```

#### dispatch_once

单例模式——使用dispatch_once方法能保证某段代码在程序运行过程中只执行1次，并且在多线程的环境下，dispatch_once也可以保证线程安全

```objc
//利用单例模式创建一个AccountManager的对象
//以后调用sharedManager方法就会返回它的对象，不用每一次都alloc init
//static 修饰变量，那么只占一份内存，就不用每次调用这个方法 又占一份内存
+ (AccountManager *)sharedManager {
    static AccountManager *sharedAccountManagerInstance = nil;

    static dispatch_once_t predicate; dispatch_once(&predicate, ^{      
          sharedAccountManagerInstance = [[self alloc] init];
    });

    return sharedAccountManagerInstance;

}
```

#### Dispatch I/O

- 实现多线程并列读取文件

