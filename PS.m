#import "PSParser.h"
#import "PSLexer.h"
#import "PSInterpreter.h"

int main ()
{
	id pool = [[NSAutoreleasePool alloc] init];
	NSData* data = [NSData dataWithContentsOfFile:@"input.txt"];
	NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	[str autorelease];
	NSLog(@"Creating lexer...");
	PSLexer* lexer = [[PSLexer alloc] initWithSource:str];
	NSLog(@"Creating parser...");
	PSParser* parser = [[PSParser alloc] initWithLexer:lexer];
	PSASTNode* root;
#ifdef NDEBUG
	@try
	{
#endif
		NSLog(@"Parsing...");
		root = [parser parseOpenBlock];
#ifdef NDEBUG
	}
	@catch (NSException* except)
	{
		if ([[except name] isEqualToString:@"PSParseError"])
		{
			NSLog(@"%@", [except reason]);
		}
		root = nil;
	}
#endif
	[root retain];
	//[root print];
	NSLog(@"Interpreting...");
	[PSInterpreter runAST:root];
	NSLog(@"Cleaning up...");
	[pool release];
	[parser release];
	[lexer release];
	[root release];
	return 0;
}
