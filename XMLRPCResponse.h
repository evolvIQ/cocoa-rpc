#import <Foundation/Foundation.h>

@class XMLRPCDecoder;

@interface XMLRPCResponse : NSObject 

- (id)initWithData: (NSData *)data;
- (BOOL)isFault;
- (NSNumber *)faultCode;
- (NSString *)faultString;
- (id)object;
- (NSString *)body;
@property (nonatomic, retain) id userObject;
@end
