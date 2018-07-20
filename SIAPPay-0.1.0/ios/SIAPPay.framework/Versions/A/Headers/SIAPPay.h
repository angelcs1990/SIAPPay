//
//  SIAPPay.h
//  chef
//
//  Created by chens on 2018/6/26.
//  Copyright © 2018年 hannengclub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#import "SIAPPersistence.h"
#import "SIAPPayError.h"

typedef void(^SIAPPayActionSuccess)(NSString *reciept);
typedef void(^SIAPPayActionFailure)(NSError *error);

@protocol SIAPReceiptVerifyProtocol <NSObject>


/**
 验证凭证是否成功，

 @param transaction 凭证相关信息
 @param success 成功回掉
 @param failure 失败回掉
 */
- (void)verifyTransaction:(SIAPPersistenceModel *)transaction success:(void (^)(NSString *))success failure:(void (^)(NSError *error))failure;

@end

@interface SIAPPay : NSObject

+ (instancetype)shareInstance;

- (void)debugOutUnverifiedInfo;

- (void)registerReceiptVerifier:(id<SIAPReceiptVerifyProtocol>)receiptVerifier;

- (void)registerPersistence:(id<SIAPPersistenceProtocol>)persistence;



- (void)fetchReceiptDataOnSuccess:(void (^)(NSString *receiptData))success failure:(void (^)(NSError *error))failure;


/**
 *  调用该函数，只需要调用一次，会自动调用start开始，你只需要在不用的时候调用stop
 *  当然也需要调用registerReceiptVerifier注册验证着
 */
- (void)handlerUnverifiedTransactionWithIden:(NSString *)iden;

//一下三个函数必须使用
- (void)start;
- (void)stop;

/**
 * @brief ios内购商品
 * @param productID     商品ID
 * @param orderId       订单号（可以用其他的自定义）
 * @param failure       完成block
 **/
- (void)buyProductWidthID:(NSString *)productID withOrderId:(NSString *)orderId success:(SIAPPayActionSuccess)success failure:(SIAPPayActionFailure)failure;



@end
