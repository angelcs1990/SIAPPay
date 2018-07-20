//
//  SIAPPay.m
//  chef
//
//  Created by chens on 2018/6/26.
//  Copyright © 2018年 hannengclub. All rights reserved.
//

#import "SIAPPay.h"

#import "SIAPReceiptRefreshService.h"
#import "SIAPPersistence.h"

#define SLog(...) printf("[%s:%s] %s\n", __FILE__, __func__, [[NSString stringWithFormat:__VA_ARGS__]UTF8String])
#define SErrBaseCode 100000
#define SErr(_code, _msg) [NSError errorWithDomain:@"com.SIAPPay" code:SErrBaseCode + (_code) userInfo:@{NSLocalizedDescriptionKey:(_msg)}]


@interface SIAPPayModel : NSObject

@property (nonatomic, copy) NSString *productID;

@property (nonatomic, copy) NSString *orderID;

@property (nonatomic, copy) SIAPPayActionSuccess success;

@property (nonatomic, copy) SIAPPayActionFailure failure;

@end

@implementation SIAPPayModel

@end


@interface SIAPPay()<SKPaymentTransactionObserver, SKProductsRequestDelegate>

//@property (nonatomic, copy) NSString *receipt; //base64购买凭证

@property (nonatomic, copy) SIAPPayModel *payModel;

@property (nonatomic, strong) id<SIAPReceiptVerifyProtocol> receiptVerifier;

@property (nonatomic, strong) id<SIAPPersistenceProtocol> persistence;

@property (nonatomic, strong) SIAPReceiptRefreshService *receiptRefreshService;

@end

@implementation SIAPPay
{
    BOOL _isHandlingUnverifyTransactionNow;
}

+ (instancetype)shareInstance
{
    static SIAPPay *pay = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pay = [SIAPPay new];
        pay->_isHandlingUnverifyTransactionNow = NO;
    });
    
    return pay;
}

- (void)debugOutUnverifiedInfo
{
    [self.persistence debugOutput];
}

- (void)handlerUnverifiedTransactionWithIden:(NSString *)iden
{
    SLog(@"本地验证开始");
    
    if (_isHandlingUnverifyTransactionNow) {
        return;
    }
    
    _isHandlingUnverifyTransactionNow = YES;
    [self start];
    
    NSArray<SIAPPersistenceModel *> *arr = [self.persistence fetchAllTransaction];
    __weak __typeof(self) weakSelf = self;
    [arr enumerateObjectsUsingBlock:^(SIAPPersistenceModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        __strong __typeof(self) self = weakSelf;
        if ([[obj genKeyId] isEqualToString:iden]) {
            NSLog(@"验证产品ID：%@", obj.productId);
            NSLog(@"识别号：%@", obj.transactionIdentifier);
            [self requestVerifyFromServerWithLocalTransaction:obj];
        } else {
            NSLog(@"不是本账号的");
        }
        
    }];
    
    _isHandlingUnverifyTransactionNow = NO;
}

- (void)start
{
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
}

- (void)stop
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

- (void)buyProductWidthID:(NSString *)productID withOrderId:(NSString *)orderId success:(SIAPPayActionSuccess)success failure:(SIAPPayActionFailure)failure
{
    if (productID == nil || productID.length == 0) {
        //tip
        if (failure) {
            failure(SErr(1, @"产品ID为空"));
        }
        return;
    }
    
    //check can pay
    if ([SKPaymentQueue canMakePayments]) {
        self.payModel = nil;
        self.payModel.success = success;
        self.payModel.failure = failure;
        [self requestProductInfoWidthID:productID withOrderID:orderId];
    } else {
        //tip
        if (failure) {
            failure(SErr(2, @"没有开启内购功能"));
        }
    }
}

- (void)registerPersistence:(id<SIAPPersistenceProtocol>)persistence
{
    self.persistence = persistence;
}

- (void)registerReceiptVerifier:(id<SIAPReceiptVerifyProtocol>)receiptVerifier
{
    self.receiptVerifier = receiptVerifier;
}

#pragma mark - private other
- (void)refreshReceipt
{
    [self refreshReceiptOnSuccess:nil failure:nil];
}

- (void)refreshReceiptOnSuccess:(void (^)(void))success failure:(void (^)(NSError *error))failure
{
    [self.receiptRefreshService refreshReceiptOnSuccess:^{
        if (success) {
            success();
        }
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

- (void)fetchReceiptDataOnSuccess:(void (^)(NSString *receiptData))success failure:(void (^)(NSError *error))failure
{
    void (^handler)(NSURL *url) = ^(NSURL *url) {
        NSData *receiptData = [NSData dataWithContentsOfURL:url];
        NSString *receiptBase64 = [receiptData base64EncodedStringWithOptions:0];
        if (success) {
            success(receiptBase64);
        }
    };
    
    //获取交易凭证
    NSURL *receiptUrl = [[NSBundle mainBundle] appStoreReceiptURL];
    
    if (receiptUrl) {
        handler(receiptUrl);
    } else {
        [self refreshReceiptOnSuccess:^{
            NSURL *url = [NSBundle mainBundle].appStoreReceiptURL;
            if (url) {
                handler(url);
            } else {
                if (failure) {

                    failure(SErr(3, @"None app store receiptURL"));
                }
            }
        } failure:failure];
    }
    
}

#pragma mark - private start buy
- (void)requestProductInfoWidthID:(NSString *)productID withOrderID:(NSString *)orderId
{
    NSLog(@"requestProductInfoWithID:%@", productID);
    
    self.payModel.productID = productID;
    self.payModel.orderID = orderId;
    
    NSArray *productArray = [[NSArray alloc] initWithObjects:productID, nil];
    NSSet *productSet = [NSSet setWithArray:productArray];
    
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:productSet];
    request.delegate = self;
    [request start];
}

- (void)requestPayWithProduct:(SKProduct *)product
{
    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:product];
    payment.applicationUsername = self.payModel.orderID;     //添加用户ID
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma mark - private buy over
- (void)requestCheckReceiptWithTransaction:(SKPaymentTransaction *)transaction
{
    NSString *order = transaction.payment.applicationUsername;  //这个没有传过来，还得传下
    NSLog(@"订单号：%@", order);
    
    //存储交易凭证  (改为放到异步获取base64的函数中存储，不知道会不会又问题）
    __weak typeof(self) weakSelf = self;
    [self.persistence saveTransaction:transaction success:^(SIAPPersistenceModel *model) {
        __strong typeof(self) self = weakSelf;
        [self requestVerifyFromServerWithTransaction:model];
    } failure:^(NSError *error) {
        __strong typeof(self) self = weakSelf;
        if (self.payModel.failure) {
            self.payModel.failure(error);
        }
    }];
}

- (void)requestVerifyFromServerWithLocalTransaction:(SIAPPersistenceModel *)transaction
{
    //传给服务器进行验证，也可以本地验证,验证是异步的
    if (self.receiptVerifier) {
        __weak typeof(self) weakSelf = self;
        [self.receiptVerifier verifyTransaction:transaction success:^(NSString *amount){
            //成功：1.删除本地存储的交易凭证
            __strong typeof(self) self = weakSelf;
            [self.persistence removeTransaction:[transaction genKeyId]];
        } failure:^(NSError *error) {
//            //验证失败错误处理
//            FCStrongify(self);
//            [self.persistence removeTransaction:transaction.transactionIdentifier];
        }];
    } else {
        if (self.payModel.success) {
            self.payModel.success(@"No receiptVerifier");
        }
    }
}

- (void)requestVerifyFromServerWithTransaction:(SIAPPersistenceModel *)transaction
{
    //传给服务器进行验证，也可以本地验证,验证是异步的
    if (self.receiptVerifier) {
        __weak typeof(self) weakSelf = self;

        [self.receiptVerifier verifyTransaction:transaction success:^(NSString *amount){
            //成功：1.删除本地存储的交易凭证
            __strong typeof(self) self = weakSelf;
            [self.persistence removeTransaction:[transaction genKeyId]];
            //
            if (self.payModel.success) {
                self.payModel.success(amount);
            }
        } failure:^(NSError *error) {
            //验证失败错误处理
            __strong typeof(self) self = weakSelf;
//            [self.persistence removeTransaction:transaction.transactionIdentifier];
            if (self.payModel.failure) {
                self.payModel.failure(error);
            }
        }];
    } else {
        if (self.payModel.success) {
            self.payModel.success(@"No receiptVerifier");
        }
    }
}

- (void)finishTransaction:(SKPaymentTransaction *)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    //验证支付凭证
    [self requestCheckReceiptWithTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    if (transaction.error.code == SKErrorPaymentCancelled) {
        //tip:取消
        if (self.payModel.failure) {
            self.payModel.failure(SErr(5, @"payment cancelled"));
        }
    } else {
        if (self.payModel.failure) {
            self.payModel.failure(SErr(6, @"payment failed"));
        }
    }
    
    
}

- (void)restoredTransaction:(SKPaymentTransaction *)transaction
{
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    if (self.payModel.failure) {
        self.payModel.failure(SErr(8, @"restored"));
    }
    
}

#pragma mark - SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    SLog(@"交易结果");
    for (SKPaymentTransaction *itemTran in transactions) {
        switch (itemTran.transactionState) {
            case SKPaymentTransactionStatePurchased:
                NSLog(@"交易完成");
                [self finishTransaction:itemTran];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:itemTran];
                NSLog(@"交易失败");
                break;
            case SKPaymentTransactionStateRestored:
                [self restoredTransaction:itemTran];
                NSLog(@"重复支付");
                break;
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"购买中。。。");
                break;
            default:
                break;
        }
    }
}

#pragma mark - SKProductsRequestDelegate
//商品信息返回
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    //reqeustProductInfoWidhID 代理过来的
    SLog(@"收到商品信息");
    
    NSArray *productInfo = response.products;
    if (productInfo.count == 0) {
        SLog(@"没有找到该商品");
        if (self.payModel.failure) {
            self.payModel.failure(SErr(6, @"cannot query product info"));
        }
        return;
    }
    
    SKProduct *product = nil;
    for (SKProduct *itemProduct in productInfo) {
        NSLog(@"Description:%@", [itemProduct description]);
        NSLog(@"ProductTitle:%@", itemProduct.localizedTitle);
        NSLog(@"ProductDesc:%@", itemProduct.localizedDescription);
        NSLog(@"Price:%@", itemProduct.price);
        NSLog(@"ProductID:%@", itemProduct.productIdentifier);
        
        if ([itemProduct.productIdentifier isEqualToString:self.payModel.productID]) {
            product = itemProduct;
            break;
        }
    }
    
    if (product) {
        [self requestPayWithProduct:product];
    } else {
        SLog(@"没有匹配的商品");
    }
    
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    SLog(@"查询失败了");
    //tip
    if (self.payModel.failure) {
        self.payModel.failure(SErr(7, [error localizedDescription]));
    }
}

- (void)requestDidFinish:(SKRequest *)request
{
    
}

#pragma mark - lazy load
- (SIAPReceiptRefreshService *)receiptRefreshService
{
    if (_receiptRefreshService == nil) {
        _receiptRefreshService = [SIAPReceiptRefreshService new];
    }
    
    return _receiptRefreshService;
}

- (SIAPPayModel *)payModel
{
    if (_payModel == nil) {
        _payModel = [SIAPPayModel new];
    }
    
    return _payModel;
}

- (id<SIAPPersistenceProtocol>)persistence
{
    if (_persistence == nil) {
        _persistence = [SIAPPersistence new];
    }
    
    return _persistence;
}

@end
