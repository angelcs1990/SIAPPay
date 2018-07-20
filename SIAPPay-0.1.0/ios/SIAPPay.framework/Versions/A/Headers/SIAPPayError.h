//
//  SIAPPayError.h
//  chef
//
//  Created by chens on 2018/6/26.
//  Copyright © 2018年 hannengclub. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SIAPPayErrorType){
    SIAPPayErrorProductIDInvalid, //产品ID无效
    SIAPPayErrorIAPNotAllow, //未开启内购功能
    SIAPPayErrorReceiptURLCannotGet, //无法获取购买凭证
    SIAPPayErrorVerifierNotRegist, //没有注册验证者
    SIAPPayErrorPaymentCancelled, //支付取消
    SIAPPayErrorPaymentFailed, //支付失败
    SIAPPayErrorProductInfoCannotGet, //无法获取相关产品信息
    SIAPPayErrorOrigin //原始自带错误信息
};
