//
//  SIAPReceiptRefresh.h
//  chef
//
//  Created by chens on 2018/6/26.
//  Copyright © 2018年 hannengclub. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SIAPReceiptRefreshService : NSObject

- (void)refreshReceiptOnSuccess:(void (^)(void))successBlock failure:(void(^)(NSError *error))failure;

@end
