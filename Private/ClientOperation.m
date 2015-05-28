//
//  ClientOperation.m
//  XMLRPC
//
//  Created by Rickard Lyrenius on 28/05/15.
//
//

#import "ClientOperation.h"

@interface ClientOperation () {
    XMLRPCResponse* _response;
    NSError* _error;
    BOOL _isFinished, _isStarted;
}
@end

@implementation ClientOperation
@synthesize response=_response, error=_error;

- (void)finishWithResponse:(XMLRPCResponse*)response error:(NSError*)error {
    if(!_error && error) {
        _error = error;
    }
    [self willChangeValueForKey:@"isFinished"];
    if(_isStarted) {
        [self willChangeValueForKey:@"isExecuting"];
    }
    _isFinished = YES;
    [self didChangeValueForKey:@"isFinished"];
    if(_isStarted) {
        [self didChangeValueForKey:@"isExecuting"];
    }
}

- (void)cancel {
    if([self isExecuting]) {
        [self finishWithResponse:nil error:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
    }
}

- (void)start {
    if(!_isStarted && !_isFinished) {
        [self willChangeValueForKey:@"isExecuting"];
        _isStarted = YES;
        [self didChangeValueForKey:@"isExecuting"];
        [self performSelectorOnMainThread:@selector(main) withObject:nil waitUntilDone:NO];
    }
}

- (BOOL)isFinished {
    return _isFinished;
}

- (BOOL)isExecuting {
    return _isStarted && !_isFinished;
}

@end
