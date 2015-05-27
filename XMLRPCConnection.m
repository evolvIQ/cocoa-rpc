#import "XMLRPCConnection.h"
#import "XMLRPCConnectionManager.h"
#import "XMLRPCRequest.h"
#import "XMLRPCResponse.h"
#import "NSStringAdditions.h"

static NSOperationQueue *parsingQueue;

@interface XMLRPCConnection (XMLRPCConnectionPrivate)

- (void)connection: (NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;

- (void)connection: (NSURLConnection *)connection didReceiveData: (NSData *)data;

- (void)connection: (NSURLConnection *)connection didSendBodyData: (NSInteger)bytesWritten totalBytesWritten: (NSInteger)totalBytesWritten totalBytesExpectedToWrite: (NSInteger)totalBytesExpectedToWrite;

- (void)connection: (NSURLConnection *)connection didFailWithError: (NSError *)error;

#pragma mark -

- (BOOL)connection: (NSURLConnection *)connection canAuthenticateAgainstProtectionSpace: (NSURLProtectionSpace *)protectionSpace;

- (void)connection: (NSURLConnection *)connection didReceiveAuthenticationChallenge: (NSURLAuthenticationChallenge *)challenge;

- (void)connection: (NSURLConnection *)connection didCancelAuthenticationChallenge: (NSURLAuthenticationChallenge *)challenge;

- (void)connectionDidFinishLoading: (NSURLConnection *)connection;

#pragma mark -

- (void)timeoutExpired;
- (void)invalidateTimer;

#pragma mark -

+ (NSOperationQueue *)parsingQueue;

@end

#pragma mark -

@implementation XMLRPCConnection

- (id)initWithXMLRPCRequest: (XMLRPCRequest *)request delegate: (id<XMLRPCConnectionDelegate>)delegate manager: (XMLRPCConnectionManager *)manager {
    if (self = [super init]) {
        myManager = manager;
        myRequest = request;
        myIdentifier = [NSString stringByGeneratingUUID];
        myData = [[NSMutableData alloc] init];
        
        myConnection = [[NSURLConnection alloc] initWithRequest: [request request] delegate: self startImmediately:NO];
        [myConnection scheduleInRunLoop:[NSRunLoop mainRunLoop]
                                forMode:NSDefaultRunLoopMode];
        [myConnection start];
        
        myDelegate = delegate;
        
        if (myConnection) {
            NSLog(@"The connection, %@, has been established!", myIdentifier);

            [self performSelector:@selector(timeoutExpired) withObject:nil afterDelay:[myRequest timeout]];
        } else {
            NSLog(@"The connection, %@, could not be established!", myIdentifier);
            
            
            return nil;
        }
    }
    
    return self;
}

#pragma mark -

+ (XMLRPCResponse *)sendSynchronousXMLRPCRequest: (XMLRPCRequest *)request error: (NSError **)error {
    NSHTTPURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest: [request request] returningResponse: &response error: error];
    
    if (response) {
        NSInteger statusCode = [response statusCode];
        
        if ((statusCode < 400) && data) {
            return [[XMLRPCResponse alloc] initWithData: data];
        }
    }
    
    return nil;
}

#pragma mark -

- (NSString *)identifier {
    return myIdentifier;
}

#pragma mark -

- (id<XMLRPCConnectionDelegate>)delegate {
    return myDelegate;
}

#pragma mark -

- (void)cancel {
    [myConnection cancel];

    [self invalidateTimer];
}

#pragma mark -


@end

#pragma mark -

@implementation XMLRPCConnection (XMLRPCConnectionPrivate)

- (void)connection: (NSURLConnection *)connection didReceiveResponse: (NSURLResponse *)response {
    if([response respondsToSelector: @selector(statusCode)]) {
        NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
        
        if(statusCode >= 400) {
            NSError *error = [NSError errorWithDomain: @"HTTP" code: statusCode userInfo: nil];
            
            [myDelegate request: myRequest didFailWithError: error];
        } else if (statusCode == 304) {
            [myManager closeConnectionForIdentifier: myIdentifier];
        }
    }
    
    [myData setLength: 0];
}

- (void)connection: (NSURLConnection *)connection didReceiveData: (NSData *)data {
    [myData appendData: data];
}

- (void)connection: (NSURLConnection *)connection didSendBodyData: (NSInteger)bytesWritten totalBytesWritten: (NSInteger)totalBytesWritten totalBytesExpectedToWrite: (NSInteger)totalBytesExpectedToWrite {
    if ([myDelegate respondsToSelector: @selector(request:didSendBodyData:)]) {
        float percent = totalBytesWritten / (float)totalBytesExpectedToWrite;
        
        [myDelegate request:myRequest didSendBodyData:percent];
    }
}

- (void)connection: (NSURLConnection *)connection didFailWithError: (NSError *)error {
    XMLRPCRequest *request = myRequest;
    
    NSLog(@"The connection, %@, failed with the following error: %@", myIdentifier, [error localizedDescription]);

    [self invalidateTimer];

    [myDelegate request: request didFailWithError: error];
    
    [myManager closeConnectionForIdentifier: myIdentifier];
}

#pragma mark -

- (BOOL)connection: (NSURLConnection *)connection canAuthenticateAgainstProtectionSpace: (NSURLProtectionSpace *)protectionSpace {
    return [myDelegate request: myRequest canAuthenticateAgainstProtectionSpace: protectionSpace];
}

- (void)connection: (NSURLConnection *)connection didReceiveAuthenticationChallenge: (NSURLAuthenticationChallenge *)challenge {
    [myDelegate request: myRequest didReceiveAuthenticationChallenge: challenge];
}

- (void)connection: (NSURLConnection *)connection didCancelAuthenticationChallenge: (NSURLAuthenticationChallenge *)challenge {
    [myDelegate request: myRequest didCancelAuthenticationChallenge: challenge];
}

- (void)connectionDidFinishLoading: (NSURLConnection *)connection {
    [self invalidateTimer];
    if (myData && ([myData length] > 0)) {
        NSBlockOperation *parsingOperation;

        parsingOperation = [NSBlockOperation blockOperationWithBlock:^{
            XMLRPCResponse *response = [[XMLRPCResponse alloc] initWithData: myData];
            XMLRPCRequest *request = myRequest;

            [[NSOperationQueue mainQueue] addOperation: [NSBlockOperation blockOperationWithBlock:^{
                [myDelegate request: request didReceiveResponse: response];

                [myManager closeConnectionForIdentifier: myIdentifier];
            }]];
        }];
        
        [[XMLRPCConnection parsingQueue] addOperation: parsingOperation];
    }
    else {
        [myManager closeConnectionForIdentifier: myIdentifier];
    }
}

#pragma mark -
- (void)timeoutExpired
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                              [myRequest URL], NSURLErrorFailingURLErrorKey,
                              [[myRequest URL] absoluteString], NSURLErrorFailingURLStringErrorKey,
                              //TODO not good to use hardcoded value for localized description
                              @"The request timed out.", NSLocalizedDescriptionKey,
                              nil];

    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:userInfo];

    [self connection:myConnection didFailWithError:error];
}

- (void)invalidateTimer
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeoutExpired) object:nil];
}

#pragma mark -

+ (NSOperationQueue *)parsingQueue {
    if (parsingQueue == nil) {
        parsingQueue = [[NSOperationQueue alloc] init];
    }
    
    return parsingQueue;
}

@end
