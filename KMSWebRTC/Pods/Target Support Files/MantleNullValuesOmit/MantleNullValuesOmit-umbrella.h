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

#import "MantleNullValuesOmit.h"
#import "MTLJSONAdapter+NullValuesOmit.h"
#import "MTLModel+NullValuesOmit.h"

FOUNDATION_EXPORT double MantleNullValuesOmitVersionNumber;
FOUNDATION_EXPORT const unsigned char MantleNullValuesOmitVersionString[];

