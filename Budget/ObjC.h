//
//  ObjC.h
//  Budget
//
//  Created by Samuel Ivarsson on 2024-03-03.
//

#import <Foundation/Foundation.h>

@interface ObjC : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end
