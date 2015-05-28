#import "XMLRPCRequest.h"
#import "XMLRPCEncoder.h"
#import "XMLRPCDefaultEncoder.h"

@interface XMLRPCRequest () {
    id<XMLRPCEncoder> _encoder;
}
@end

@implementation XMLRPCRequest

- (id)initWithEncoder: (id<XMLRPCEncoder>)encoder {
    if (self = [super init]) {
        _encoder = encoder;
    }
    
    return self;
}

- (id)init {
    return [self initWithEncoder:[XMLRPCDefaultEncoder new]];
}

#pragma mark -

- (void)setMethod: (NSString *)method {
    [_encoder setMethod: method withParameters: nil];
}

- (void)setMethod: (NSString *)method withParameter: (id)parameter {
    NSArray *parameters = nil;
    
    if (parameter) {
        parameters = [NSArray arrayWithObject: parameter];
    }
    
    [_encoder setMethod: method withParameters: parameters];
}

- (void)setMethod: (NSString *)method withParameters: (NSArray *)parameters {
    [_encoder setMethod: method withParameters: parameters];
}

#pragma mark -

- (NSString *)method {
    return [_encoder method];
}

- (NSArray *)parameters {
    return [_encoder parameters];
}

#pragma mark -

- (NSString *)body {
    return [_encoder encode];
}

- (NSString*) mimeType {
    return @"text/xml";
}

@end
