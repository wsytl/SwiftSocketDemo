//
//  ViewController.swift
//  ChatDemo
//
//  Created by 杨天礼 on 2018/6/22.
//  Copyright © 2018 杨天礼. All rights reserved.
//

import UIKit
import SwiftSocket
import Gzip
import SwiftProtobuf

//clone新版本

class ViewController: UIViewController {
    
    //消息输入框
    @IBOutlet weak var textFiled: UITextField!
    //消息输出列表
    @IBOutlet weak var textView: UITextView!
    
    //socket客户端类对象
    var socketClient:TCPClient?
    
    var isLogin:Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        //启动服务器
        //        socketServer = MyTcpSocketServer()
        //        socketServer?.start()
        
        //初始化客户端，并连接服务器
        processClientSocket()
    }
    
    //初始化客户端，并连接服务器
    func processClientSocket(){
        socketClient=TCPClient(address: "localhost", port: 9655)
        DispatchQueue.global(qos: .background).async {
            //用于读取并解析服务端发来的消息
            func readmsg()->[String:Any]?{
                //read 4 byte int as type
                if let data=self.socketClient!.read(4){
                    if data.count==4{
                        let ndata=NSData(bytes: data, length: data.count)
                        var len:Int32=0
                        ndata.getBytes(&len, length: data.count)
                        if let buff=self.socketClient!.read(Int(len)){
                            let msgd = Data(bytes: buff, count: buff.count)
                            if !self.isLogin {
                                do{
                                    let loginReqBody = try LoginReqBody(serializedData: msgd)
                                    print("登陆了用户"+loginReqBody.loginname)
                                    self.isLogin = true
                                }catch{
                                    
                                }
                            }else{
                                do{
                                    let chatReqBody = try ChatReqBody(serializedData: msgd)
                                    let text = chatReqBody.text
                                    print("给\(chatReqBody.toID)"+"发送了消息\(chatReqBody.text)")
                                    self.isLogin = true
                                }catch{
                                    
                                }
                            }
                        }
                    }
                }
                return nil
            }
            
            //连接服务器
            switch self.socketClient!.connect(timeout: 5) {
            case .success:
                DispatchQueue.main.async {
                    self.alert(msg: "connect success", after: {
                    })
                }
                
                //登录
                _ = self.socketClient!.send(data: self.encode2())
                
                //不断接收服务器发来的消息
                while true{
                    if let msg=readmsg(){
                        DispatchQueue.main.async {
                            self.processMessage(msg: msg)
                        }
                    }else{
                        DispatchQueue.main.async {
                            //self.disconnect()
                        }
                        //break
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.alert(msg: error.localizedDescription,after: {
                    })
                }
            }
        }
    }
    
    //“发送消息”按钮点击
    @IBAction func sendMsg(_ sender: AnyObject) {
                let content=textFiled.text!
        _ = self.socketClient!.send(data: self.sendMessage(msgtosend: content))
        textFiled.text=nil
    }
    
    
    //处理服务器返回的消息
    func processMessage(msg:[String:Any]){
        let cmd:String=msg["cmd"] as! String
        switch(cmd){
        case "msg":
            self.textView.text = self.textView.text +
                (msg["from"] as! String) + ": " + (msg["content"] as! String) + "\n"
        default:
            print(msg)
        }
    }
    
    
    //弹出消息框
    func alert(msg:String,after:()->(Void)){
        let alertController = UIAlertController(title: "",
                                                message: msg,
                                                preferredStyle: .alert)
        self.present(alertController, animated: true, completion: nil)
        
        //1.5秒后自动消失
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.5) {
            alertController.dismiss(animated: false, completion: nil)
        }
    }
    
    
    //发送消息
    func sendMessage(msgtosend:String)-> [Byte]{
        var chatReqBody:ChatReqBody = ChatReqBody()
        chatReqBody.toID = "1123wew"
        chatReqBody.text = msgtosend
        chatReqBody.type = ChatType(rawValue: 2)!
        
        
        //从data转为[UInt8]
        var data:Data = Data()
        do {
            data = try chatReqBody.serializedData()
        }catch{
            
        }
        
        var body:[Byte] = data.withUnsafeBytes {
            [UInt8](UnsafeBufferPointer(start: $0, count: data.count)) as [Byte]
        }
        
        
        var bodyLen:Int = 0
        var isCompress:Bool = false
        var is4ByteLength:Bool = false
        
        if data.count != 0 {
            bodyLen = data.count
            if bodyLen > 300 {
                do {
                    //压缩数据
                    let compressedData = try! data.gzipped()
                    //从data转为[UInt8]
                    let gzipedbody:[UInt8] = compressedData.withUnsafeBytes {
                        [UInt8](UnsafeBufferPointer(start: $0, count: compressedData.count))
                    }
                    if gzipedbody.count < body.count {
                        body = gzipedbody
                        bodyLen = gzipedbody.count
                        isCompress = true
                    }
                }
            }
            if bodyLen > Int16.max {
                is4ByteLength = true
            }
        }
        
        
        let allLen:Int = bodyLen + 4
        var buffer = [UInt8](repeating: 0, count: allLen)
        
        var firstbyte = ImPacketPhone.encodeCompress(bs: ImPacketPhone.VERSION, isCompress: isCompress)
        firstbyte = ImPacketPhone.encodeHasSynSeq(bs: firstbyte, hasSynSeq: 0 > 0)
        firstbyte = ImPacketPhone.encode4ByteLength(bs: firstbyte, is4ByteLength: is4ByteLength)
        
        buffer[0] = firstbyte
        buffer[1] = 8 as Byte
        
        
        if is4ByteLength {
            buffer[3] = Byte(bodyLen)
        }else{
            buffer.insert(Byte(bodyLen), at: 3)
        }
        
        if body.count != 0 {
            if is4ByteLength {
                for i in (0..<body.count) {
                    buffer[i+3] = body[i]
                }
            }else{
                for i in (0..<body.count) {
                    buffer[i+4] = body[i]
                }
                buffer.removeLast()
            }
        }
        return buffer
    }
    
    
    
    public func encode2() -> [Byte] {
        
        var chatReqBody:LoginReqBody = LoginReqBody()
        chatReqBody.loginname = "111"
        chatReqBody.password = "123"
        chatReqBody.token = "111"
        
        //从data转为[UInt8]
        var data:Data = Data()
        do {
            data = try chatReqBody.serializedData()
        }catch{
            
        }
        
        var body:[Byte] = data.withUnsafeBytes {
            [UInt8](UnsafeBufferPointer(start: $0, count: data.count)) as [Byte]
        }
        
        
        var bodyLen:Int = 0
        var isCompress:Bool = false
        var is4ByteLength:Bool = false
        
        if data.count != 0 {
            bodyLen = data.count
            if bodyLen > 300 {
                do {
                    //压缩数据
                    let compressedData = try! data.gzipped()
                    //从data转为[UInt8]
                    let gzipedbody:[UInt8] = compressedData.withUnsafeBytes {
                        [UInt8](UnsafeBufferPointer(start: $0, count: compressedData.count))
                    }
                    if gzipedbody.count < body.count {
                        body = gzipedbody
                        bodyLen = gzipedbody.count
                        isCompress = true
                    }
                }
            }
            if bodyLen > Int16.max {
                is4ByteLength = true
            }
        }
        
        
        let allLen:Int = bodyLen + 4
        var buffer = [UInt8](repeating: 0, count: allLen)
        
        var firstbyte = ImPacketPhone.encodeCompress(bs: ImPacketPhone.VERSION, isCompress: isCompress)
        firstbyte = ImPacketPhone.encodeHasSynSeq(bs: firstbyte, hasSynSeq: 0 > 0)
        firstbyte = ImPacketPhone.encode4ByteLength(bs: firstbyte, is4ByteLength: is4ByteLength)
        
        buffer[0] = firstbyte
        buffer[1] = 18 as Byte
        
        if is4ByteLength {
            buffer[3] = Byte(bodyLen)
        }else{
            buffer.insert(Byte(bodyLen), at: 3)
        }
        
        if body.count != 0 {
            if is4ByteLength {
                for i in (0..<body.count) {
                    buffer[i+3] = body[i]
                }
            }else{
                for i in (0..<body.count) {
                    buffer[i+4] = body[i]
                }
                buffer.removeLast()
            }
        }
        return buffer
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}


