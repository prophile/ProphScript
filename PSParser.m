#import "PSParser.h"

@implementation PSParser
- (void)parseError:(NSString*)error
{
	NSUInteger line, column;
	[_lexer getSourceLine:&line column:&column];
	char sysbuf[512];
	sprintf(sysbuf, "see -g %lu:%lu input.txt", line, column);
	system(sysbuf);
	[NSException raise:@"PSParseError" format:@"Parse error: %@ at %lu:%lu", error, line, column];
}

- (PSASTNode*)parseInteger
{
	NSString* value = [_lexer lex:PS_TOK_INTEGER];
	if (!value)
		return nil;
	PSASTNode* node = [[PSASTNode alloc] initWithType:@"integer"];
	[node setData:value];
	return [node autorelease];
}

- (PSASTNode*)parseValue
{
	PSASTNode* node;
	if (node = [self parseFunction])
		return node;
	else if (node = [self parseString])
		return node;
	else if (node = [self parseInteger])
		return node;
	else if (node = [self parseVariable])
	{
		if ([_lexer lex:PS_TOK_OPEN_BRACKET])
		{
			// function call
			PSASTNode* callNode = [[PSASTNode alloc] initWithType:@"call"];
			[callNode addChild:node];
			BOOL moreParameters = YES;
			PSASTNode* parameterNode;
			do
			{
				if ([_lexer lex:PS_TOK_CLOSE_BRACKET])
				{
					moreParameters = NO;
				}
				else
				{
					parameterNode = [self parseExpression];
					[callNode addChild:parameterNode];
					if ([_lexer lex:PS_TOK_COMMA])
						moreParameters = YES;
					else if ([_lexer lex:PS_TOK_CLOSE_BRACKET])
						moreParameters = NO;
					else
					{
						[callNode release];
						[self parseError:@"expected comma or close bracket in parameter list"];
						return nil;
					}
				}
			} while(moreParameters);
			return [callNode autorelease];
		}
		else
		{
			return node;
		}
	}
	else if ([_lexer lex:PS_TOK_OPEN_BRACKET])
	{
		PSASTNode* subExpression = [self parseExpression];
		if (![_lexer lex:PS_TOK_CLOSE_BRACKET])
		{
			[self parseError:@"missing close bracket"];
			return nil;
		}
		return subExpression;
	}
	return nil;
}

- (PSASTNode*)parseExpression
{
	PSASTNode* node;
	NSString* part;
	if (part = [_lexer lex:PS_TOK_UNARY_OPERATOR])
	{
		node = [[PSASTNode alloc] initWithType:@"unop"];
		PSASTNode* expr = [self parseExpression];
		if (!expr)
		{
			[node release];
			[self parseError:@"missing expression for unary operator"];
			return nil;
		}
		[node addChild:expr];
		[node setData:part];
		return [node autorelease];
	}
	else if (node = [self parseValue])
	{
		NSString* binop;
		if (binop = [_lexer lex:PS_TOK_BINARY_OPERATOR])
		{
			PSASTNode* expression = [self parseExpression];
			PSASTNode* binNode = [[PSASTNode alloc] initWithType:@"binop"];
			[binNode setData:binop];
			[binNode addChild:node];
			[binNode addChild:expression];
			return [binNode autorelease];
		}
		else
		{
			return node;
		}
	}
	else
	{
		//[self parseError:@"expected expression"];
		return nil;
	}
}

- (PSASTNode*)parseString
{
	NSString* value;
	if (!(value = [_lexer lex:PS_TOK_STRING]))
	{
		return nil;
	}
	PSASTNode* node = [[PSASTNode alloc] initWithType:@"string"];
	[node setData:value];
	return [node autorelease];
}

- (PSASTNode*)parseStatement
{
	PSASTNode* block;
	PSASTNode* exprNode;
	if (block = [self parseBlock])
	{
		return block;
	}
	else if ([_lexer lex:PS_TOK_SEMICOLON])
	{
		// empty statement
		return [self parseStatement];
	}
	else if ([_lexer lex:PS_TOK_IF])
	{
		PSASTNode* ifNode = [[PSASTNode alloc] initWithType:@"if"];
		PSASTNode* conditionNode = [self parseExpression];
		if (!conditionNode)
		{
			[ifNode release];
			[self parseError:@"missing condition for if"];
			return nil;
		}
		PSASTNode* blockNode = [self parseStatement];
		if (!blockNode)
		{
			[ifNode release];
			[self parseError:@"missing block for if"];
			return nil;
		}
		[ifNode addChild:conditionNode];
		[ifNode addChild:blockNode];
		if ([_lexer lex:PS_TOK_ELSE])
		{
			blockNode = [self parseStatement];
			if (!blockNode)
			{
				[ifNode release];
				[self parseError:@"missing block for else clause of if"];
				return nil;
			}
			[ifNode addChild:blockNode];
		}
		return [ifNode autorelease];
	}
	else if ([_lexer lex:PS_TOK_WHILE])
	{
		PSASTNode* whileNode = [[PSASTNode alloc] initWithType:@"while"];
		PSASTNode* conditionNode = [self parseExpression];
		if (!conditionNode)
		{
			[whileNode release];
			[self parseError:@"missing condition for while loop"];
			return nil;
		}
		PSASTNode* blockNode = [self parseStatement];
		if (!blockNode)
		{
			[whileNode release];
			[self parseError:@"missing block for while loop"];
			return nil;
		}
		[whileNode addChild:conditionNode];
		[whileNode addChild:blockNode];
		return [whileNode autorelease];
	}
	else if ([_lexer lex:PS_TOK_RETURN])
	{
		PSASTNode* returnNode = [[PSASTNode alloc] initWithType:@"return"];
		PSASTNode* exprNode;
		if (!(exprNode = [self parseExpression]))
		{
			[returnNode release];
			[self parseError:@"missing expression for return"];
			return nil;
		}
		[returnNode addChild:exprNode];
		return [returnNode autorelease];
	}
	else if (exprNode = [self parseExpression])
	{
		PSASTNode* node = [[PSASTNode alloc] initWithType:@"statement"];
		[node addChild:exprNode];
		if (![_lexer hadCloseBrace] && ![_lexer lex:PS_TOK_SEMICOLON])
		{
			[node release];
			[self parseError:@"missing semicolon"];
			return nil;
		}
		return [node autorelease];
	}
	else
	{
		return nil;
	}
}

- (PSASTNode*)parseFunction
{
	if (![_lexer lex:PS_TOK_FUNCTION])
		return nil;
	if (![_lexer lex:PS_TOK_OPEN_BRACKET])
	{
		[_lexer unlex];
		return nil;
	}
	PSASTNode* node = [[PSASTNode alloc] initWithType:@"function"];
	PSASTNode* param;
	BOOL moreParameters = YES;
	do
	{
		if ([_lexer lex:PS_TOK_CLOSE_BRACKET])
		{
			moreParameters = NO;
		}
		else
		{
			param = [self parseVariable];
			[node addChild:param];
			if ([_lexer lex:PS_TOK_COMMA])
				moreParameters = YES;
			else if ([_lexer lex:PS_TOK_CLOSE_BRACKET])
				moreParameters = NO;
			else
			{
				[node release];
				[self parseError:@"expected comma or close bracket"];
				return nil;
			}
		}
	} while(moreParameters);
	PSASTNode* stmt = [self parseStatement];
	if (!stmt)
	{
		[node release];
		[self parseError:@"missing implementation for function"];
		return nil;
	}
	[node addChild:stmt];
	return [node autorelease];
}

- (PSASTNode*)parseVariable
{
	PSASTNode* node = [[PSASTNode alloc] initWithType:@"variable"];
	NSString* value = [_lexer lex:PS_TOK_IDENTIFIER];
	if (!value)
	{
		[node release];
		return nil;
	}
	else
	{
		[node setData:value];
		return [node autorelease];
	}
}

- (PSASTNode*)parseOpenBlock
{
	PSASTNode* node = [[PSASTNode alloc] initWithType:@"block"];
	PSASTNode* stmt;
	while (stmt = [self parseStatement])
	{
		[node addChild:stmt];
	}
	return [node autorelease];
}

- (PSASTNode*)parseBlock
{
	if (![_lexer lex:PS_TOK_OPEN_BRACE])
	{
		return nil;
	}
	PSASTNode* block = [self parseOpenBlock];
	if (![_lexer lex:PS_TOK_CLOSE_BRACE])
	{
		[self parseError:@"missing close brace in block"];
		return nil;
	}
	return block;
}

- (id)initWithLexer:(PSLexer*)lexer
{
	id s;
	if (s = [super init])
	{
		_lexer = [lexer retain];
	}
	return s;
}

- (void)dealloc
{
	[_lexer release];
	[super dealloc];
}
@end

@implementation PSASTNode
- (id)initWithType:(NSString*)type
{
	id s = [super init];
	if (s == self)
	{
		_type = [type copy];
		_children = [[NSMutableArray alloc] init];
		_data = nil;
	}
	return s;
}

- (void)dealloc
{
	[_data release];
	[_children release];
	[_type release];
	[super dealloc];
}

- (void)addChild:(PSASTNode*)addChild
{
	[_children addObject:addChild];
}

- (NSString*)data
{
	return [[_data retain] autorelease];
}

- (void)setData:(NSString*)data
{
	data = [data copy];
	[_data release];
	_data = data;
}

- (NSString*)type
{
	return [[_type retain] autorelease];
}

- (NSArray*)children
{
	return [[_children retain] autorelease];
}

- (void)_printAtLevel:(NSUInteger)level
{
	NSUInteger i;
	for (i = 0; i < level; i++)
	{
		printf("\t");
	}
	printf("%s", [_type UTF8String]);
	if (_data)
	{
		printf(" (%s)", [[_data description] UTF8String]);
	}
	printf("\n");
	PSASTNode* child;
	for (child in _children)
	{
		[child _printAtLevel:level + 1];
	}
}

- (void)print
{
	[self _printAtLevel:0];
}
@end
