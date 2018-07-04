//
//  ImPacketPhone.swift
//  ChatDemo
//
//  Created by 杨天礼 on 2018/6/22.
//  Copyright © 2018 杨天礼. All rights reserved.
//
//

//FIXME: 注意保持与server中ImPacket关键方法一致

import UIKit

struct ImPacketPhone {
    
    /* FIXME:  心跳字节 */
    public static let HEARTBEAT_BYTE = -128;
    
    /* FIXME:  握手字节 */
    public static let HANDSHAKE_BYTE = -127;
    
    /* FIXME:  协议版本号 */
    public static let VERSION:UInt8 = 1;
    
    /* FIXME:  消息体最多为多少 */
    public static let MAX_LENGTH_OF_BODY:Int = (Int(1024 * 1024 * 2.1)); //只支持多少M数据
    
    /* FIXME:  消息头最少为多少个字节 */
    public static let LEAST_HEADER_LENGHT:Int = 4; ////1+1+2 + (2+4)
    
    /* FIXME:  压缩标识位mack，1为压缩，否则不压缩 */
    public static let FIRST_BYTE_MASK_COMPRESS:UInt8 = 64;
    
    /* FIXME:  是否有同步序列号标识位mask，如果有同步序列号，则消息头会带有同步序列号，否则不带 */
    public static let FIRST_BYTE_MASK_HAS_SYNSEQ:UInt8 = 32;
    
    /* FIXME:  是否是用4字节来表示消息体的长度 */
    public static let FIRST_BYTE_MASK_4_BYTE_LENGTH:UInt8 = 16;
    
    /* FIXME:  版本号mask */
    public static let FIRST_BYTE_MASK_VERSION:UInt8 = 15;
    
    /* FIXME:  同步发送时，需要的同步序列号 */
    private  var synSeq:Int = 0;
    
    /*
     /* FIXME:  是否压缩消息体 */
     private let isCompress:Bool = false;
     
     /* FIXME:  是否带有同步序列号 */
     private let boolean:Bool = false;
     
     /* FIXME:  是否用4字节来表示消息体的长度，false:2字节，true:4字节 */
     private let is4ByteLength:Bool = false;
     */
    
    /* FIXME:  decodeCompress */
    public static func decodeCompress(version:UInt8)->Bool{
        return (FIRST_BYTE_MASK_COMPRESS & version) != 0
    }
    
    /* FIXME:  encodeCompress */
    public static func encodeCompress(bs:UInt8,isCompress:Bool)->UInt8{
        if isCompress {
            return bs | FIRST_BYTE_MASK_COMPRESS;
        }else{
            return bs & (FIRST_BYTE_MASK_COMPRESS ^ 127);
        }
    }
    
    /* FIXME:  decodeHasSynSeq */
    public static func decodeHasSynSeq(firstByte:UInt8)->Bool{
        return (FIRST_BYTE_MASK_HAS_SYNSEQ & firstByte) != 0;
    }
    
    /* FIXME:  encodeHasSynSeq */
    public static func encodeHasSynSeq(bs:UInt8,hasSynSeq:Bool)->UInt8{
        if hasSynSeq {
            return (bs | FIRST_BYTE_MASK_HAS_SYNSEQ);
        }else{
            return (bs & (FIRST_BYTE_MASK_HAS_SYNSEQ ^ 127));
        }
    }
    
    /* FIXME:  decode4ByteLength */
    public static func decode4ByteLength(version:UInt8)->Bool{
        return (FIRST_BYTE_MASK_4_BYTE_LENGTH & version) != 0;
    }
    
    /* FIXME:  encode4ByteLength */
    public static func encode4ByteLength(bs:UInt8,is4ByteLength:Bool)->UInt8{
        if is4ByteLength {
            return  (bs | FIRST_BYTE_MASK_4_BYTE_LENGTH);
        }else{
            return  (bs & (FIRST_BYTE_MASK_4_BYTE_LENGTH ^ 127));
        }
    }
    
    /* FIXME:  decodeVersion */
    public static func decodeVersion(version:UInt8)->UInt8{
        return (FIRST_BYTE_MASK_VERSION & version);
    }
    
    /* FIXME:  计算消息头占用了多少字节数 */
    public func calcHeaderLength(is4byteLength:Bool)->Int{
        var ret = ImPacketPhone.LEAST_HEADER_LENGHT;
        if is4byteLength {
            ret += 2;
        }
        if self.getSynSeq()>0 {
            ret += 4;
        }
        return ret;
    }
    
    
    
    /* FIXME:  添加标记 */
    private var body:[UInt8]?

    
    /* FIXME:  command */
    private var command:Command?;
    public func getCommand()->Command{
        return command!
    }
    public mutating func setCommand(type:Command){
        command = type
    }
    
    /* FIXME:  get body */
    public func getBody()->[UInt8]{
        return body!
    }
    /* FIXME:  set body */
    public mutating func setBody(body:[UInt8]){
        self.body = body
    }
    
    
    
    public func logstr()->String{
        return String(self.command!.rawValue)
    }
    
    
    public func getSynSeq()->Int{
        return synSeq;
    }
    
    
    public mutating func setSynSeq(synSeq:Int) {
        self.synSeq = synSeq;
    }
}
















