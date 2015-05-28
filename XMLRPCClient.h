#import <Foundation/Foundation.h>
#import "XMLRPCClientDelegate.h"

@class XMLRPCRequest, XMLRPCResponse;
@protocol XMLRPCClientTransportOperation;

@protocol XMLRPCClientTransport <NSObject>
@required
- (NSOperation<XMLRPCClientTransportOperation>*)sendRequest:(XMLRPCRequest*)request delegate: (id<XMLRPCClientDelegate>)delegate;
@optional
- (BOOL)supportsConcurrentRequests;
@end

@protocol XMLRPCClientTransportOperation <NSObject>
- (XMLRPCResponse*)response;
- (NSError*)error;
@end

typedef void (^RPCCompletion)(XMLRPCResponse*);
typedef void (^RPCError)(NSError*);

@interface XMLRPCClient : NSObject

- (id)initWithURL:(NSURL*)url;
- (id)initWithTransport: (id<XMLRPCClientTransport>)transport;

#pragma mark -

@property (nonatomic, assign) id<XMLRPCClientDelegate> delegate;

#pragma mark -

// Start an asynchronous request
- (NSOperation*)startRequest:(XMLRPCRequest*)request completion:(RPCCompletion)completion error:(RPCError)error;

// Perform a synchronous request
- (XMLRPCResponse*)performRequest:(XMLRPCRequest*)request error:(NSError**)error;

@property (nonatomic, assign) NSInteger maximumConcurrentRequests;
@property (nonatomic, assign) NSTimeInterval timeout;

@end
