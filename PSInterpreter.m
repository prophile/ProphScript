#import "PSInterpreter.h"
#import "PSStandardLibrary.h"

static const NSUInteger STACK_NONE = ~(NSUInteger)0;

@interface PSInterpreter(PrivateAPI)
- (void)newStackContext;
- (void)exitStackContext;
- (void)newFrame;
- (void)exitFrame;
- (NSUInteger)newStackSlot;
- (id)stackGet:(NSUInteger)slot;
- (void)stackWrite:(NSUInteger)slot value:(id)val;
- (NSUInteger)symTabGet:(NSString*)name;
- (void)symTabWrite:(NSString*)name value:(NSUInteger)slot;
- (NSDictionary*)copySymTab;
- (BOOL)stackBooleanate:(NSUInteger)slot;
@end

@interface PSASTNode(Interpreter)
- (NSUInteger)visitFromInterpreter:(PSInterpreter*)interpreter;
@end

@interface PSInterpreterFunction : NSObject
{
}
- (id)runWithInterpreter:(PSInterpreter*)interpreter arguments:(NSArray*)arguments;
@end

@implementation PSInterpreterFunction
- (id)runWithInterpreter:(PSInterpreter*)interpreter arguments:(NSArray*)arguments
{
	return nil;
}
@end

@interface PSBuiltinFunction : PSInterpreterFunction
{
	id _target;
	SEL _selector;
	BOOL _variableArguments;
}
- (id)initWithTarget:(id)target selector:(SEL)selector;
- (id)initWithTarget:(id)target selector:(SEL)selector withVariableArguments:(BOOL)varargs;
- (id)runWithInterpreter:(PSInterpreter*)interpreter arguments:(NSArray*)arguments;
@end

@implementation PSBuiltinFunction
- (id)initWithTarget:(id)target selector:(SEL)selector withVariableArguments:(BOOL)varargs
{
	id s = [super init];
	if (s == self)
	{
		_target = [target retain];
		_selector = selector;
		_variableArguments = varargs;
	}
	return s;
}

- (id)initWithTarget:(id)target selector:(SEL)selector
{
	return [self initWithTarget:target selector:selector withVariableArguments:NO];
}

- (void)dealloc
{
	[_target release];
	[super dealloc];
}

- (id)runWithInterpreter:(PSInterpreter*)interpreter arguments:(NSArray*)arguments
{
	if (_variableArguments)
	{
		return [_target performSelector:_selector withObject:arguments];
	}
	NSMethodSignature* sig = [_target methodSignatureForSelector:_selector];
	NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
	[invocation setSelector:_selector];
	[invocation setTarget:_target];
	NSUInteger i, count = [arguments count];
	for (i = 0; i < count; i++)
	{
		id val = [arguments objectAtIndex:i];
		[invocation setArgument:&val atIndex:i+2];
	}
	[invocation invoke];
	const char* rt = [sig methodReturnType];
	if (!strcmp(rt, @encode(void)))
	{
		return nil;
	}
	else if (!strcmp(rt, @encode(id)))
	{
		id rv;
		[invocation getReturnValue:&rv];
		return rv;
	}
	else
	{
		NSLog(@"Unknown return type for selector %s", _selector);
		exit(1);
		return nil;
	}
}
@end

@interface PSASTFunction : PSInterpreterFunction
{
	PSASTNode* _node;
	NSDictionary* _symTab;
}
- (id)initWithASTNode:(PSASTNode*)node inInterpreter:(PSInterpreter*)interpreter;
- (id)runWithInterpreter:(PSInterpreter*)interpreter arguments:(NSArray*)arguments;
@end

@implementation PSASTFunction
- (id)initWithASTNode:(PSASTNode*)node inInterpreter:(PSInterpreter*)interpreter
{
	id s = [super init];
	if (s == self)
	{
		_symTab = [[interpreter copySymTab] copy];
		_node = node;
	}
	return s;
}

- (void)dealloc
{
	[_symTab release];
	[super dealloc];
}

- (id)runWithInterpreter:(PSInterpreter*)interpreter arguments:(NSArray*)arguments
{
	[interpreter newFrame];
	[interpreter newStackContext];
	NSString* key;
	NSUInteger slot = [interpreter newStackSlot];
	for (key in _symTab)
	{
		id value = [_symTab objectForKey:key];
		[interpreter stackWrite:slot value:value];
		[interpreter symTabWrite:key value:slot];
	}
	NSUInteger numArguments = [[_node children] count] - 1;
	NSAssert([arguments count] == numArguments, @"wrong argument count");
	NSUInteger i;
	for (i = 0; i < numArguments; i++)
	{
		[interpreter stackWrite:slot value:[arguments objectAtIndex:i]];
		[interpreter symTabWrite:(NSString*)[[[_node children] objectAtIndex:i] data] value:slot];
	}
	PSASTNode* block = [[_node children] objectAtIndex:numArguments];
	NSUInteger resultSlot = [block visitFromInterpreter:interpreter];
	id value = [interpreter stackGet:resultSlot];
	[value retain];
	[interpreter exitStackContext];
	[interpreter exitFrame];
	return [value autorelease];
}
@end

@implementation PSASTNode(Interpreter)
- (NSUInteger)visitFromInterpreter:(PSInterpreter*)interpreter
{
	//NSLog(@"Visit %@ (%@)", _type, _data);
	if ([_type isEqualToString:@"block"])
	{
		[interpreter newFrame];
		[interpreter newStackContext];
		for (id statement in _children)
		{
			NSUInteger val = [statement visitFromInterpreter:interpreter];
			if (val != STACK_NONE)
			{
				id value = [[interpreter stackGet:val] retain];
				[interpreter exitStackContext];
				[interpreter exitFrame];
				NSUInteger slot = [interpreter newStackSlot];
				[interpreter stackWrite:slot value:value];
				[value release];
				return slot;
			}
		}
		[interpreter exitStackContext];
		[interpreter exitFrame];
		NSUInteger slot = [interpreter newStackSlot];
		[interpreter stackWrite:slot value:nil];
		return slot;
	}
	else if ([_type isEqualToString:@"variable"])
	{
		return [interpreter symTabGet:_data];
	}
	else if ([_type isEqualToString:@"string"])
	{
		NSUInteger slot = [interpreter newStackSlot];
		[interpreter stackWrite:slot value:_data];
		return slot;
	}
	else if ([_type isEqualToString:@"integer"])
	{
		NSUInteger slot = [interpreter newStackSlot];
		[interpreter stackWrite:slot value:[NSNumber numberWithInteger:[_data integerValue]]];
		return slot;
	}
	else if ([_type isEqualToString:@"return"])
	{
		PSASTNode* child = [_children objectAtIndex:0];
		return [child visitFromInterpreter:interpreter];
	}
	else if ([_type isEqualToString:@"statement"])
	{
		PSASTNode* child = [_children objectAtIndex:0];
		[interpreter newStackContext];
		[child visitFromInterpreter:interpreter];
		[interpreter exitStackContext];
		return STACK_NONE;
	}
	else if ([_type isEqualToString:@"if"])
	{
		[interpreter newStackContext];
		NSUInteger conditionSlot = [[_children objectAtIndex:0] visitFromInterpreter:interpreter];
		BOOL val = [interpreter stackBooleanate:conditionSlot];
		[interpreter exitStackContext];
		if (val)
		{
			return [[_children objectAtIndex:1] visitFromInterpreter:interpreter];
		}
		else
		{
			if ([_children count] > 2)
			{
				return [[_children objectAtIndex:2] visitFromInterpreter:interpreter];
			}
			else
			{
				return STACK_NONE;
			}
		}
	}
	else if ([_type isEqualToString:@"while"])
	{
		while (1)
		{
			[interpreter newStackContext];
			NSUInteger conditionSlot = [[_children objectAtIndex:0] visitFromInterpreter:interpreter];
			BOOL continueLoop = [interpreter stackBooleanate:conditionSlot];
			[interpreter exitStackContext];
			if (!continueLoop)
				break;
			[interpreter newStackContext];
			NSUInteger valueSlot = [[_children objectAtIndex:1] visitFromInterpreter:interpreter];
			if (valueSlot != STACK_NONE)
			{
				id value = [[interpreter stackGet:valueSlot] retain];
				[interpreter exitStackContext];
				NSUInteger newSlot = [interpreter newStackSlot];
				[interpreter stackWrite:newSlot value:value];
				[value release];
				return newSlot;
			}
			else
			{	
				[interpreter exitStackContext];
			}
		}
		return STACK_NONE;
	}
	else if ([_type isEqualToString:@"binop"])
	{
		if ([_data isEqualToString:@"="])
		{
			[interpreter newStackContext];
			NSString* target = (NSString*)[[_children objectAtIndex:0] data];
			NSUInteger value = [[_children objectAtIndex:1] visitFromInterpreter:interpreter];
			[interpreter symTabWrite:target value:value];
			[interpreter exitStackContext];
			return [interpreter symTabGet:target];
		}
		else
		{
			NSString* operatorName = [NSString stringWithFormat:@"__binop%@", _data];
			[interpreter newStackContext];
			NSUInteger leftStack  = [[_children objectAtIndex:0] visitFromInterpreter:interpreter];
			NSUInteger rightStack = [[_children objectAtIndex:1] visitFromInterpreter:interpreter];
			id left, right;
			left  = [interpreter stackGet:leftStack];
			right = [interpreter stackGet:rightStack];
			[left retain];
			[right retain];
			[interpreter exitStackContext];
			NSArray* arguments = [NSArray arrayWithObjects:left, right, nil];
			[left release];
			[right release];
			NSUInteger functionSlot = [interpreter symTabGet:operatorName];
			id fn = [interpreter stackGet:functionSlot];
			NSAssert([fn isKindOfClass:[PSInterpreterFunction class]], @"bad function");
			id returnValue = [fn runWithInterpreter:interpreter arguments:arguments];
			[interpreter stackWrite:functionSlot value:returnValue];
			return functionSlot;
		}
	}
	else if ([_type isEqualToString:@"unop"])
	{
		NSString* operatorName = [NSString stringWithFormat:@"__unop%@", _data];
		[interpreter newStackContext];
		NSUInteger argStack  = [[_children objectAtIndex:0] visitFromInterpreter:interpreter];
		id arg = [interpreter stackGet:argStack];
		[arg retain];
		[interpreter exitStackContext];
		NSArray* arguments = [NSArray arrayWithObjects:arg, nil];
		[arg release];
		NSUInteger functionSlot = [interpreter symTabGet:operatorName];
		id fn = [interpreter stackGet:functionSlot];
		NSAssert([fn isKindOfClass:[PSInterpreterFunction class]], @"bad function");
		id returnValue = [fn runWithInterpreter:interpreter arguments:arguments];
		[interpreter stackWrite:functionSlot value:returnValue];
		return functionSlot;
	}
	else if ([_type isEqualToString:@"function"])
	{
		PSASTFunction* fn = [[PSASTFunction alloc] initWithASTNode:self inInterpreter:interpreter];
		NSUInteger slot = [interpreter newStackSlot];
		[interpreter stackWrite:slot value:fn];
		[fn release];
		return slot;
	}
	else if ([_type isEqualToString:@"call"])
	{
		[interpreter newStackContext];
		NSMutableArray* arguments = [NSMutableArray array];
		NSUInteger i, count = [_children count];
		NSUInteger slot;
		for (i = 1; i < count; i++)
		{
			slot = [[_children objectAtIndex:i] visitFromInterpreter:interpreter];
			[arguments addObject:[interpreter stackGet:slot]];
		}
		slot = [[_children objectAtIndex:0] visitFromInterpreter:interpreter];
		id fn = [interpreter stackGet:slot];
		[fn retain];
		[interpreter exitStackContext];
		[fn autorelease];
		if ([fn isKindOfClass:[PSInterpreterFunction class]])
		{
			id result = [fn runWithInterpreter:interpreter arguments:arguments];
			NSUInteger slot = [interpreter newStackSlot];
			[interpreter stackWrite:slot value:result];
			return slot;
		}
		else
		{
			NSLog(@"Tried to call a non-function (actual kind: %@)", [fn class]);
			NSLog(@"%@", [interpreter copySymTab]);
			exit(1);
			return STACK_NONE;
		}
	}
	else
	{
		NSLog(@"Tried to visit AST node type %@ which is not implemented", _type);
		exit(1);
		return STACK_NONE;
	}
}
@end

@implementation PSInterpreter
- (id)initWithBlock:(PSASTNode*)block
{
	id s = [super init];
	if (s == self)
	{
		_block = [block retain];
		_symbolTable = [[NSMutableArray alloc] init];
		_stack = [[NSMutableArray alloc] init];
	}
	return s;
}

- (void)run
{
	id stdlib = [[PSStandardLibrary alloc] init];
	[self newFrame];
	[self declareBuiltin:@"dump" target:self selector:@selector(_dump:)];
	[self declareBuiltin:@"__binop+" target:stdlib selector:@selector(add:and:)];
	[self declareBuiltin:@"__binop-" target:stdlib selector:@selector(sub:and:)];
	[self declareBuiltin:@"__binop*" target:stdlib selector:@selector(mul:and:)];
	[self declareBuiltin:@"__binop/" target:stdlib selector:@selector(div:and:)];
	[self declareBuiltin:@"__binop==" target:stdlib selector:@selector(is:equalTo:)];
	[self declareBuiltin:@"__binop~=" target:stdlib selector:@selector(is:notEqualTo:)];
	[self declareBuiltin:@"__binop<" target:stdlib selector:@selector(is:lessThan:)];
	[self declareBuiltin:@"__binop>" target:stdlib selector:@selector(is:greaterThan:)];
	[self declareBuiltin:@"__binop<=" target:stdlib selector:@selector(is:lessThanOrEqualTo:)];
	[self declareBuiltin:@"__binop>=" target:stdlib selector:@selector(is:greaterThanOrEqualTo:)];
	[self declareBuiltin:@"__unop-" target:stdlib selector:@selector(is:greaterThanOrEqualTo:)];
	[self declareVarArgBuiltin:@"print" target:stdlib selector:@selector(print:)];
	[_block visitFromInterpreter:self];
	[self exitFrame];
	[stdlib release];
}

+ (void)runAST:(PSASTNode*)node
{
	PSInterpreter* interpreter = [[PSInterpreter alloc] initWithBlock:node];
	[interpreter run];
	[interpreter release];
}

- (void)newFrame
{
	[_symbolTable addObject:[NSMutableDictionary dictionary]];
}

- (void)exitFrame
{
	[_symbolTable removeLastObject];
}

- (void)newStackContext
{
	[_stack addObject:[NSNumber numberWithUnsignedInteger:_stackSize]];
	_stackSize = 0;
}

- (void)exitStackContext
{
	while (_stackSize > 0)
	{
		[_stack removeLastObject];
		_stackSize--;
	}
	_stackSize = [[_stack lastObject] unsignedIntegerValue];
	[_stack removeLastObject];
}

- (NSUInteger)newStackSlot
{
	NSUInteger slot = [_stack count];
	[_stack addObject:[NSNull null]];
	_stackSize++;
	return slot;
}

- (id)stackGet:(NSUInteger)slot
{
	return [_stack objectAtIndex:slot];
}

- (void)stackWrite:(NSUInteger)slot value:(id)val
{
	if (val == nil)
		val = [NSNull null];
	[_stack replaceObjectAtIndex:slot withObject:val];
}

- (NSUInteger)symTabGet:(NSString*)name
{
	NSUInteger count = [_symbolTable count];
	NSUInteger i, index;
	NSUInteger slot = [self newStackSlot];
	for (i = count; i > 0; i--)
	{
		index = i - 1;
		NSMutableDictionary* dict = [_symbolTable objectAtIndex:index];
		id val;
		if (val = [dict objectForKey:name])
		{
			[self stackWrite:slot value:val];
			return slot;
		}
	}
	[self stackWrite:slot value:nil];
	return slot;
}

- (NSDictionary*)copySymTab
{
	NSMutableDictionary* md = [NSMutableDictionary dictionary];
	NSUInteger count = [_symbolTable count];
	NSUInteger i;
	for (i = 0; i < count; i++)
	{
		NSDictionary* st = [_symbolTable objectAtIndex:i];
		[md addEntriesFromDictionary:st];
	}
	return md;
}

- (void)symTabWrite:(NSString*)name value:(NSUInteger)slot
{
	NSUInteger index = [_symbolTable count] - 1;
	// look down for other possibles
	NSMutableDictionary* dict = nil;
	NSUInteger i = index + 1;
	for (; i > 0 && ![dict objectForKey:name]; i--)
	{
		NSUInteger idx = i - 1;
		dict = [_symbolTable objectAtIndex:index];
	}
	if (![dict objectForKey:name])
		dict = [_symbolTable objectAtIndex:index];
	[dict setObject:[self stackGet:slot] forKey:name];
}

- (BOOL)stackBooleanate:(NSUInteger)slot
{
	id val = [self stackGet:slot];
	if (!val)
		return NO;
	if ([val isKindOfClass:[NSString class]])
		return [val isEqualToString:@""];
	if ([val isKindOfClass:[NSNumber class]])
		return [val boolValue];
	return YES;
}

- (void)declareBuiltin:(NSString*)name target:(id)target selector:(SEL)selector
{
	PSBuiltinFunction* func = [[PSBuiltinFunction alloc] initWithTarget:target selector:selector];
	[self newStackContext];
	NSUInteger slot = [self newStackSlot];
	[self stackWrite:slot value:func];
	[func release];
	[self symTabWrite:name value:slot];
	[self exitStackContext];
}

- (void)declareVarArgBuiltin:(NSString*)name target:(id)target selector:(SEL)selector
{
	PSBuiltinFunction* func = [[PSBuiltinFunction alloc] initWithTarget:target selector:selector withVariableArguments:YES];
	[self newStackContext];
	NSUInteger slot = [self newStackSlot];
	[self stackWrite:slot value:func];
	[func release];
	[self symTabWrite:name value:slot];
	[self exitStackContext];
}

- (void)_dump:(id)value
{
	NSLog(@"%@", value);
}
@end
