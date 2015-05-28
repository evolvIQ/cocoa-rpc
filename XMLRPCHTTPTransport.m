#import "XMLRPCHTTPTransport.h"
#import "XMLRPCRequest.h"
#import "XMLRPCResponse.h"
#import "Parsing.h"
#import "ClientOperation.h"

@interface XMLRPCClientHTTPTransport () {
    NSURL* _url;
}
@end

@interface HTTPClientOperation : ClientOperation <NSURLConnectionDelegate> {
@public
    XMLRPCRequest* _request;
    NSMutableData* _data;
    NSURLConnection* _connection;
    NSURLRequest* _urlRequest;
    NSURL* _url;
    NSString* _userAgent;
    id<XMLRPCClientDelegate> _delegate;
}
@end

@implementation XMLRPCClientHTTPTransport

- (id) initWithURL:(NSURL*)url {
    if(self = [self init]) {
        _url = url;
    }
    return self;
}

- (NSOperation<XMLRPCClientTransportOperation>*)sendRequest:(XMLRPCRequest*)request delegate: (id<XMLRPCClientDelegate>)delegate {
    HTTPClientOperation* op = [HTTPClientOperation new];
    op->_delegate = delegate;
    op->_request = request;
    op->_url = _url;
    op->_userAgent = self.userAgent;
    return op;
}

- (BOOL)supportsConcurrentRequests {
    return YES;
}

@end

@implementation HTTPClientOperation

- (BOOL)isAsynchronous {
    return YES;
}

- (void)cancel {
    [_connection cancel];
    [super cancel];
}

- (void)start {
    NSData *content = [[_request body] dataUsingEncoding: NSUTF8StringEncoding];
    NSMutableURLRequest* r = [NSMutableURLRequest requestWithURL:_url];
    [r setHTTPMethod: @"POST"];
    NSString* mime = [_request mimeType];
    if(mime) {
        [r addValue: mime forHTTPHeaderField: @"Content-Type"];
        [r addValue: mime forHTTPHeaderField: @"Accept"];
    }

    if (_userAgent) {
        [r addValue: _userAgent forHTTPHeaderField:@"User-Agent"];
    }

    [r addValue:[NSString stringWithFormat:@"%lu", (unsigned long)[content length]] forHTTPHeaderField: @"Content-Length"];
    [r setHTTPBody: content];
    _urlRequest = r;
    [super start];
}

- (void)main {
    _data = [NSMutableData data];
    _connection = [NSURLConnection connectionWithRequest:_urlRequest delegate:self];
    _urlRequest = nil;
    [_connection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                               forMode:NSDefaultRunLoopMode];
    [_connection start];
}

- (void)connection: (NSURLConnection *)connection didReceiveResponse: (NSURLResponse *)response {
    if([response respondsToSelector: @selector(statusCode)]) {
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];

        if(statusCode >= 400) {
            NSError *error = [NSError errorWithDomain: @"HTTP" code: statusCode
                                             userInfo: @{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"HTTP error code %ld", (long)statusCode]}];

            [_connection cancel];
            _connection = nil;
            [_delegate request: _request didFailWithError: error];
            [self finishWithResponse:nil error:error];
        }
    }

    [_data setLength: 0];
}

- (void)connection: (NSURLConnection *)connection didReceiveData: (NSData *)data {
    [_data appendData: data];
}

- (void)connection: (NSURLConnection *)connection didSendBodyData: (NSInteger)bytesWritten totalBytesWritten: (NSInteger)totalBytesWritten totalBytesExpectedToWrite: (NSInteger)totalBytesExpectedToWrite {
    if ([_delegate respondsToSelector: @selector(request:didSendBodyData:)]) {
        float percent = totalBytesWritten / (float)totalBytesExpectedToWrite;

        [_delegate request:_request didSendBodyData:percent];
    }
}

- (void)connection: (NSURLConnection *)connection didFailWithError: (NSError *)error {
    [_delegate request: _request didFailWithError: error];
    _connection = nil;
    [self finishWithResponse:nil error:error];
}

#pragma mark -

- (BOOL)connection: (NSURLConnection *)connection canAuthenticateAgainstProtectionSpace: (NSURLProtectionSpace *)protectionSpace {
    return [_delegate request: _request canAuthenticateAgainstProtectionSpace: protectionSpace];
}

- (void)connection: (NSURLConnection *)connection didReceiveAuthenticationChallenge: (NSURLAuthenticationChallenge *)challenge {
    [_delegate request: _request didReceiveAuthenticationChallenge: challenge];
}

- (void)connection: (NSURLConnection *)connection didCancelAuthenticationChallenge: (NSURLAuthenticationChallenge *)challenge {
    [_delegate request: _request didCancelAuthenticationChallenge: challenge];
}

- (void)connectionDidFinishLoading: (NSURLConnection *)connection {
    _connection = nil;
    if ([_data length] > 0) {
        [Parsing parseXMLRPCResponseAsyncFromData:_data withCompletion:^(XMLRPCResponse *response) {
            response.userObject = _request.userObject;
            [_delegate request:_request didReceiveResponse:response];
            [self finishWithResponse:response error:nil];
        }];
    }
    else {
        [_delegate request:_request didReceiveResponse:nil];
        [self finishWithResponse:nil error:nil];
    }
}

@end
