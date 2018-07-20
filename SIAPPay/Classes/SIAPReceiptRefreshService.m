//
//  SIAPReceiptRefresh.m
//  chef
//
//  Created by chens on 2018/6/26.
//  Copyright © 2018年 hannengclub. All rights reserved.
//

#import "SIAPReceiptRefreshService.h"
#import <StoreKit/StoreKit.h>

@interface SIAPReceiptRefreshService()<SKRequestDelegate>

@property (nonatomic, strong) SKReceiptRefreshRequest *refreshRequest;

@property (nonatomic, copy) void (^actionSuccess)(void);

@property (nonatomic, copy) void (^actionFailure)(NSError *error);


@end

@implementation SIAPReceiptRefreshService

- (void)refreshReceiptOnSuccess:(void (^)(void))successBlock failure:(void (^)(NSError *))failure
{
    self.actionSuccess = successBlock;
    self.actionFailure = failure;
    
    self.refreshRequest = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:@{}];
    self.refreshRequest.delegate = self;
    [self.refreshRequest start];
}

#pragma mark - SKRequestDelegate
- (void)requestDidFinish:(SKRequest *)request
{
    NSLog(@"Refresh receipt finished");
    
    self.refreshRequest = nil;
    if (self.actionSuccess) {
        self.actionSuccess();
        self.actionSuccess = nil;
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    NSLog(@"Refresh receipt failed Error:%@", error.debugDescription);
    
    self.refreshRequest = nil;
    if (self.actionFailure) {
        self.actionFailure(error);
        self.actionFailure = nil;
    }
}

@end
