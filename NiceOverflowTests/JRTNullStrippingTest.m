//  JRTNullStrippingTest.m
//  Created by Richard Turton on 23/12/2013.

#import <XCTest/XCTest.h>
#import "NSJSONSerialization+RemovingNulls.h"

@interface JRTNullStrippingTest : XCTestCase

@end

@implementation JRTNullStrippingTest

- (void)setUp
{
    [super setUp];
    // Put setup code here; it will be run once, before the first test case.
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    [super tearDown];
}

-(void)testRemoveNullsAtTopLevelFromDictionary
{
    NSMutableDictionary *dictionaryWithNulls = [self dictionaryWithNulls];
    [dictionaryWithNulls recursivelyRemoveNulls];
    XCTAssertNil(dictionaryWithNulls[@"null"]);
    XCTAssertTrue([dictionaryWithNulls[@"one"] isEqual:@1]);
}

- (NSMutableDictionary *)dictionaryWithNulls
{
    return [@{@"one" : @1, @"two" : @2, @"null" : [NSNull null]} mutableCopy];
}

-(void)testRemoveNullsAtTopLevelFromArray
{
    NSMutableArray *arrayWithNulls = [self arrayWithNulls];
    [arrayWithNulls recursivelyRemoveNulls];
    XCTAssertTrue([arrayWithNulls containsObject:@1]);
    XCTAssertFalse([arrayWithNulls containsObject:[NSNull null]]);
}

-(void)testIgnoringRemoveNullsAtTopLevelFromArray
{
    NSMutableArray *arrayWithNulls = [self arrayWithNulls];
    [arrayWithNulls recursivelyRemoveNullsIgnoringArrays:YES];
    XCTAssertTrue([arrayWithNulls containsObject:@1]);
    XCTAssertTrue([arrayWithNulls containsObject:[NSNull null]]);
}
- (NSMutableArray *)arrayWithNulls
{
    return [@[@1,@2,[NSNull null]] mutableCopy];
}

-(void)testRemoveNullsFromArrayInDictionary
{
    NSMutableDictionary *dictionary = [self dictionaryWithNulls];
    NSMutableArray *array = [self arrayWithNulls];
    [dictionary setObject:array forKey:@"array"];
    [dictionary recursivelyRemoveNulls];
    XCTAssertFalse([array containsObject:[NSNull null]]);
}

-(void)testIgnoringRemoveNullsFromArrayInDictionary
{
    NSMutableDictionary *dictionary = [self dictionaryWithNulls];
    NSMutableArray *array = [self arrayWithNulls];
    [dictionary setObject:array forKey:@"array"];
    [dictionary recursivelyRemoveNullsIgnoringArrays:YES];
    XCTAssertTrue([array containsObject:[NSNull null]]);
}

-(void)testRemoveNullsFromDictionaryInDictionary
{
    NSMutableDictionary *dictionary = [self dictionaryWithNulls];
    NSMutableDictionary *nestedDictionary = [self dictionaryWithNulls];
    [dictionary setObject:nestedDictionary forKey:@"dictionary"];
    [dictionary recursivelyRemoveNulls];
    XCTAssertNil([nestedDictionary objectForKey:@"null"]);
    XCTAssertTrue([nestedDictionary[@"one"] isEqual:@1]);
}

-(void)testRemoveNullsFromDictionaryInArrayInDictionary
{
    NSMutableDictionary *dictionary = [self dictionaryWithNulls];
    NSMutableArray *array = [self arrayWithNulls];
    NSMutableDictionary *nestedDictionary = [self dictionaryWithNulls];
    [dictionary setObject:array forKey:@"array"];
    [array addObject:nestedDictionary];
    [dictionary recursivelyRemoveNulls];
    XCTAssertNil([nestedDictionary objectForKey:@"null"]);
    XCTAssertTrue([nestedDictionary[@"one"] isEqual:@1]);
    NSLog(@"dictionary is %@",dictionary);
}

-(void)testJSONSerializationIsNotBroken
{
    NSMutableDictionary *dictionary = [self dictionaryWithNulls];
    NSMutableArray *array = [self arrayWithNulls];
    NSMutableDictionary *nestedDictionary = [self dictionaryWithNulls];
    [dictionary setObject:array forKey:@"array"];
    [array addObject:nestedDictionary];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:0 error:nil];
    
    id standard = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    id stripped = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil removingNulls:NO ignoreArrays:YES];
    
    XCTAssertEqualObjects(standard, stripped);
    
    stripped = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil removingNulls:YES ignoreArrays:NO];
    
    XCTAssertFalse([standard isEqual:stripped]);
}

-(void)testJSONSerializationErrorStillReturned
{
    NSString *invalidJSON = @"I am not JSON!";
    NSData *data = [invalidJSON dataUsingEncoding:NSUTF8StringEncoding];
    
    NSError *standard = nil;
    NSError *category = nil;
    [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&standard];
    [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&category removingNulls:YES ignoreArrays:NO];
    XCTAssertNotNil(standard);
    XCTAssertNotNil(category);
    XCTAssertEqualObjects(standard, category);
    NSLog(@"%@",category);
}

@end
