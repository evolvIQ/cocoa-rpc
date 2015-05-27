// 
// Copyright (c) 2010 Eric Czarny <eczarny@gmail.com>
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of  this  software  and  associated documentation files (the "Software"), to
// deal  in  the Software without restriction, including without limitation the
// rights  to  use,  copy,  modify,  merge,  publish,  distribute,  sublicense,
// and/or sell copies  of  the  Software,  and  to  permit  persons to whom the
// Software is furnished to do so, subject to the following conditions:
// 
// The  above  copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE  SOFTWARE  IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED,  INCLUDING  BUT  NOT  LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS  OR  COPYRIGHT  HOLDERS  BE  LIABLE  FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY,  WHETHER  IN  AN  ACTION  OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
// 

#import "XMLRPCParserTest.h"
#import "XMLRPCEventBasedParser.h"
#import "NSDataAdditions.h"

@interface XMLRPCParserTest (XMLRPCParserTestPrivate)
- (id) parseTestCase:(NSString*)name;
- (id) parseData:(NSData*)data;
- (NSData*) testCaseNamed:(NSString*)name;
- (NSBundle *)unitTestBundle;
- (NSDictionary *)testCases;
@end

#pragma mark -

@implementation XMLRPCParserTest

- (void)setUp {
}

#pragma mark -

- (void)testParseAlternativeDateFormats {
    id expected = @[[NSDate dateWithString:@"2009-12-02 01:49:00 +0000"],
                    [NSDate dateWithString:@"2009-12-02 01:50:00 +0000"]];

    id parsed = [self parseTestCase:@"AlternativeDateFormats"];


    XCTAssertEqualObjects(expected, parsed);
}


- (void)testParseEmptyBoolean {
    id expected = @0;

    id parsed = [self parseTestCase:@"EmptyBoolean"];

    XCTAssertEqualObjects(expected, parsed);
}


- (void)testParseEmptyData {
    id expected = [NSData dataWithBytes:nil length:0];

    id parsed = [self parseTestCase:@"EmptyData"];

    XCTAssertEqualObjects(expected, parsed);
}


- (void)testParseEmptyDouble {
    id expected = @0;

    id parsed = [self parseTestCase:@"EmptyDouble"];

    XCTAssertEqualObjects(expected, parsed);
}


- (void)testParseEmptyString {
    id expected = @"";

    id parsed = [self parseTestCase:@"EmptyString"];

    XCTAssertEqualObjects(expected, parsed);
}


- (void)testParseSimpleArray {
    id expected = @[@"Hello World!",
                    @42,
                    @3.14,
                    @1,
                    [NSDate dateWithString:@"2009-07-18 21:34:00 +0000"],
                    [NSData base64DataFromString:@"eW91IGNhbid0IHJlYWQgdGhpcyE="]];

    id parsed = [self parseTestCase:@"SimpleArray"];

    XCTAssertEqualObjects(expected, parsed);
}


- (void)testParseSimpleStruct {
    id expected = @{@"Name" : @"Eric Czarny",
                    @"Birthday" : [NSDate dateWithString:@"1984-04-15 05:00:00 +0000"],
                    @"Age" : @25};

    id parsed = [self parseTestCase:@"SimpleStruct"];

    XCTAssertEqualObjects(expected, parsed);
}


- (void)testExtensions {
    id expected = @{@"Name" : [NSNull null] };

    id parsed = [self parseTestCase:@"Extensions"];

    XCTAssertEqualObjects(expected, parsed);
}

#pragma mark -

- (void)tearDown {
}

@end

#pragma mark -

@implementation XMLRPCParserTest (XMLRPCParserTestPrivate)

- (id) parseTestCase:(NSString*)name {
    return [self parseData:[self testCaseNamed:name]];
}

- (id) parseData:(NSData*)data {
    return [[[XMLRPCEventBasedParser alloc] initWithData: data] parse];
}

- (NSData*) testCaseNamed:(NSString*)name {
    return [NSData dataWithContentsOfFile:[[self unitTestBundle] pathForResource: [NSString stringWithFormat:@"%@TestCase", name] ofType: @"xml"]];
}

- (NSBundle *)unitTestBundle {
    return [NSBundle bundleForClass: [XMLRPCParserTest class]];
}

#pragma mark -

- (NSDictionary *)testCases {
    NSString *file = [[self unitTestBundle] pathForResource: @"TestCases" ofType: @"plist"];
    NSDictionary *testCases = [[NSDictionary alloc] initWithContentsOfFile: file];
    
    return testCases;
}

@end
