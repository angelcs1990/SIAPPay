#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "SIAPPay.h"
#import "SIAPPayError.h"
#import "SIAPPersistence.h"
#import "SIAPReceiptRefreshService.h"

FOUNDATION_EXPORT double SIAPPayVersionNumber;
FOUNDATION_EXPORT const unsigned char SIAPPayVersionString[];

