//
//  SIAPPersistence.m
//  chef
//
//  Created by chens on 2018/6/26.
//  Copyright © 2018年 hannengclub. All rights reserved.
//

#import "SIAPPersistence.h"

#import "SIAPPay.h"

#define SIAP_KEY_PERSISTENCE @"SIAP_Persistence"



@implementation SIAPPersistenceModel

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_base64 forKey:@"base64"];
    [aCoder encodeObject:_productId forKey:@"productId"];
    [aCoder encodeObject:_order forKey:@"order"];
    [aCoder encodeObject:_transactionIdentifier forKey:@"transactionIdentifier"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    [aDecoder decodeObjectForKey:@"base64"];
    [aDecoder decodeObjectForKey:@"productId"];
    [aDecoder decodeObjectForKey:@"order"];
    [aDecoder decodeObjectForKey:@"transactionIdentifier"];
    
    return self;
}

- (NSString *)genKeyId
{
    return [NSString stringWithFormat:@"%@-%@", self.order, self.transactionIdentifier];
}

@end


@interface SIAPPersistence ()

@property (nonatomic, strong) NSString *persistencePath;

@end

@implementation SIAPPersistence

- (NSString *)genKeyIdWithTransaction:(SKPaymentTransaction *)transaction
{
    return [NSString stringWithFormat:@"%@-%@", transaction.payment.applicationUsername, transaction.transactionIdentifier];
}

- (void)saveTransaction:(SKPaymentTransaction *)transaction success:(void (^)(SIAPPersistenceModel *model))success failure:(void (^)(NSError *))failure
{
    NSString *keyId = [self genKeyIdWithTransaction:transaction];
    
    SIAPPersistenceModel *model = [SIAPPersistenceModel new];
    model.order = transaction.payment.applicationUsername;
    model.productId = transaction.payment.productIdentifier;
    model.transactionIdentifier = transaction.transactionIdentifier;

    [[SIAPPay shareInstance] fetchReceiptDataOnSuccess:^(NSString *receiptData) {
//        [self updateBase64:receiptData withKey:transaction.transactionIdentifier];
        model.base64 = receiptData;
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:self.persistencePath];
        if (dict == nil) {
            dict = [NSMutableDictionary dictionary];
        }
        
        if (keyId && [dict objectForKey:keyId]) {
            return;
        } else {
            [dict setObject:model forKey:keyId];
        }
        
        [dict writeToFile:self.persistencePath atomically:YES];
        
        if (success) {
            success(model);
        }
    } failure:^(NSError *error) {
        NSLog(@"saveTransaction Error get base64");
        if (failure) {
            failure(error);
        }
    }];
    
    
}

//- (void)updateBase64:(NSString *)receipt withKey:(NSString *)key
//{
//    NSMutableDictionary<NSString *, SIAPPersistenceModel *> *dict = [NSMutableDictionary dictionaryWithContentsOfFile:self.persistencePath];
//    if (dict && [dict containsObjectForKey:key]) {
//        dict[key].base64 = receipt;
//        [dict writeToFile:self.persistencePath atomically:YES];
//    }
//}

- (void)removeAllTransaction
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic writeToFile:self.persistencePath atomically:YES];
}

- (void)removeTransaction:(NSString *)iden
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:self.persistencePath];
    if (dict && iden && [dict objectForKey:iden]) {
        [dict removeObjectForKey:iden];
        
        [dict writeToFile:self.persistencePath atomically:YES];
    }
}

- (NSArray<SIAPPersistenceModel *> *)fetchAllTransaction
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:self.persistencePath];
    
 
    return [dict allValues];
}

- (void)debugOutput
{
    NSArray<SIAPPersistenceModel *> *arr = [self fetchAllTransaction];
    NSLog(@"未验证数量：%ld", arr.count);
    [arr enumerateObjectsUsingBlock:^(SIAPPersistenceModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@"产品ID:%@ -- 识别号：%@", obj.productId, obj.transactionIdentifier);
    }];
}

#pragma mark - private


#pragma mark - lazy load
- (NSString *)persistencePath
{
    if (_persistencePath == nil) {
        _persistencePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"SIAP_persistence.plist"];
    }
    
    return _persistencePath;
}

@end
