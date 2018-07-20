//
//  SIAPPersistence.h
//  chef
//
//  Created by chens on 2018/6/26.
//  Copyright © 2018年 hannengclub. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

@interface SIAPPersistenceModel : NSObject <NSCoding>

@property (nonatomic, copy) NSString *base64;

@property (nonatomic, copy) NSString *productId;

@property (nonatomic, copy) NSString *order;

@property (nonatomic, copy) NSString *transactionIdentifier;

- (NSString *)genKeyId;

@end

@protocol SIAPPersistenceProtocol <NSObject>

@required
- (void)saveTransaction:(SKPaymentTransaction *)transaction success:(void (^)(SIAPPersistenceModel *model))success failure:(void (^)(NSError *error))failure;

- (void)removeTransaction:(NSString *)transactionIden;

- (NSArray<SIAPPersistenceModel *> *)fetchAllTransaction;

- (void)removeAllTransaction;

@optional
- (void)debugOutput;

@end




@interface SIAPPersistence : NSObject <SIAPPersistenceProtocol>



@end
