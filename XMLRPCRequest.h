#import <Foundation/Foundation.h>

#import "XMLRPCEncoder.h"

@interface XMLRPCRequest : NSObject 

- (id)initWithEncoder: (id<XMLRPCEncoder>)encoder;

#pragma mark -

- (void)setMethod: (NSString *)method;
- (void)setMethod: (NSString *)method withParameter: (id)parameter;
- (void)setMethod: (NSString *)method withParameters: (NSArray *)parameters;

#pragma mark -

- (NSString *)method;

- (NSArray *)parameters;

@property NSTimeInterval timeout;

@property (nonatomic, retain) id userObject;

#pragma mark -

- (NSString *)body;

- (NSString *)mimeType;

@end
