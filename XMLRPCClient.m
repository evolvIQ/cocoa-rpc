#import "XMLRPCClient.h"
#import "XMLRPCRequest.h"
#import "XMLRPCResponse.h"
#import "XMLRPCHTTPTransport.h"
#import "NSStringAdditions.h"
#import "Parsing.h"
#import "ClientOperation.h"

static const NSTimeInterval DEFAULT_TIMEOUT = 240;

static NSOperationQueue *parsingQueue;

@interface _XMLRPCRequestWithCallbacks : NSObject <XMLRPCClientDelegate> {
    @public
    XMLRPCRequest* request;
    RPCCompletion completion;
    RPCError error;
    __weak id<XMLRPCClientDelegate> delegate;
}
@end

@interface XMLRPCClient () {
    id<XMLRPCClientTransport> _transport;
    NSMutableSet *_currentRequests;
    NSOperationQueue* _requestQueue;
}
@end

#pragma mark -

@implementation XMLRPCClient

- (id)initWithURL:(NSURL*)url {
    return [self initWithTransport:[[XMLRPCClientHTTPTransport alloc] initWithURL:url]];
}

- (id)initWithTransport: (id<XMLRPCClientTransport>)transport {
    if (self = [super init]) {
        _transport = transport;
        _currentRequests = [NSMutableSet set];
        _requestQueue = [NSOperationQueue new];
        _requestQueue.maxConcurrentOperationCount = 1;
        self.timeout = DEFAULT_TIMEOUT;
    }
    
    return self;
}

- (NSInteger) maximumConcurrentRequests {
    return _requestQueue.maxConcurrentOperationCount;
}

- (void) setMaximumConcurrentRequests:(NSInteger)maximumConcurrentRequests {
    if([_transport supportsConcurrentRequests]) {
        [_requestQueue setMaxConcurrentOperationCount:maximumConcurrentRequests];
    }
}

#pragma mark -

- (NSOperation*)startRequest:(XMLRPCRequest*)request completion:(RPCCompletion)completion error:(RPCError)error {
    NSOperation<XMLRPCClientTransportOperation>* op = [_transport sendRequest:request delegate:_delegate];
    [[Parsing queue] addOperation:op];
    __weak NSOperation<XMLRPCClientTransportOperation>* wop = op;
    op.completionBlock = ^{
        if(wop && !wop.isCancelled) {
            if(wop.error) {
                error(wop.error);
            } else {
                completion(wop.response);
            }
        }
    };
    return op;
}

- (XMLRPCResponse*)performRequest:(XMLRPCRequest*)request error:(NSError**)error {
    __block XMLRPCResponse* ret = nil;
    __block BOOL done;
    [self startRequest:request completion:^(XMLRPCResponse *r) {
        if(error) *error = nil;
        ret = r;
        done = true;
    } error:^(NSError *e) {
        if(error) *error = e;
        ret = nil;
        done = true;
    }];
    while(!done) [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
    return ret;
}

#pragma mark -


@end
