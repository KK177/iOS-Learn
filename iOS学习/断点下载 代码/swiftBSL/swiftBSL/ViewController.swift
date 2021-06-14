//
//  ViewController.swift
//  swiftBSL
//
//  Created by iiik- on 2021/6/11.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let str = "https://ss3.bdstatic.com/70cFv8Sh_Q1YnxGkpoWK1HF6hhy/it/u=3349541936,792281887&fm=27&gp=0.jpg"
        let url = URL.init(string: str)
        YDownLoadTool.init().downLoader(url: url!)
    }
}

