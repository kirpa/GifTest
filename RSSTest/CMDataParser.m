#import "CMDataParser.h"
#import "CMRssRecord.h"

@interface CMDataParser()

@property (retain, nonatomic) NSMutableString *currentString;

@end

@implementation CMDataParser


#pragma mark XML parser delegate

- (void) parseData:(NSData *) data
{
    NSLog(@"Start parsing");
    _dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [_dateFormatter setLocale:locale];
    [_dateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss zzz"];
    [locale release];
    _parser = [[NSXMLParser alloc] initWithData:data];
    _parser.delegate = self;
    [_parser parse];
    NSLog(@"Parsing finished");
}

#pragma mark Parsing support methods

- (void) finishedRecord
{ 
    [self.delegate recordParsed:_currentRecord];
    [_currentRecord release];
    _currentRecord = nil;
}


#pragma mark NSXMLParser delegate methods

static NSString *cElementItem  = @"item";
static NSString *cElementTitle = @"title";
static NSString *cElementURL   = @"link";
static NSString *cElementDate  = @"pubDate";

- (void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict
{ 
    _needElement = NO;
    if ([elementName isEqualToString:cElementItem])
    {
        [_currentRecord release];
        _currentRecord = [[CMRssRecord alloc] init];
    }
    else if ([elementName isEqualToString:cElementTitle] || [elementName isEqualToString:cElementURL] || [elementName isEqualToString:cElementDate])
    {
        self.currentString = [NSMutableString string];
        _needElement = YES;
    }
}

- (void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    
    if ([elementName isEqualToString:cElementItem])
        [self finishedRecord];
    else if ([elementName isEqualToString:cElementTitle])
        _currentRecord.title = _currentString;
    else if ([elementName isEqualToString:cElementURL])
        _currentRecord.url = _currentString;
    else if ([elementName isEqualToString:cElementDate])
        _currentRecord.date = [_dateFormatter dateFromString:_currentString];
}

- (void) parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if (_needElement)
        [_currentString appendString:string];
}

- (void) parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"Error parsing rss: %@", parseError);
    [self.delegate finishedParsing];
}

- (void) parserDidEndDocument:(NSXMLParser *)parser
{
    [self.delegate finishedParsing];
}

- (void) dealloc
{
    [_parser release];
    self.currentString = nil;
    [_currentRecord release];
    [_dateFormatter release];
    [super dealloc];
}

@end
