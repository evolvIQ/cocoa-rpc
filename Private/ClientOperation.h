#import <Foundation/Foundation.h>
#import "XMLRPCClient.h"

@class XMLRPCResponse;

@interface ClientOperation : NSOperation <XMLRPCClientTransportOperation>
- (void)finishWithResponse:(XMLRPCResponse*)response error:(NSError*)error;

@property (nonatomic, readonly) XMLRPCResponse* response;
@property (nonatomic, readonly) NSError* error;
@end
