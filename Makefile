#CC=clang
#LD=clang
#CFLAGS=-O4 -emit-llvm -DNDEBUG
#LDFLAGS=-framework Foundation
CC=gcc
LD=gcc
CFLAGS=-O0 -gfull -arch x86_64
LDFLAGS=-framework Foundation -arch x86_64 -gfull

PS: Objects/PSLexer.o Objects/PSParser.o Objects/PS.o Objects/PSInterpreter.o Objects/PSStandardLibrary.o
	$(LD) $(LDFLAGS) -o PS Objects/PSLexer.o Objects/PSParser.o Objects/PS.o Objects/PSInterpreter.o Objects/PSStandardLibrary.o

Objects/PSInterpreter.o: PSInterpreter.m PSInterpreter.h PSParser.h PSLexer.h PSStandardLibrary.h
	$(CC) $(CFLAGS) -c PSInterpreter.m -o Objects/PSInterpreter.o

Objects/PSLexer.o: PSLexer.m PSLexer.h
	$(CC) $(CFLAGS) -c PSLexer.m -o Objects/PSLexer.o

Objects/PSParser.o: PSParser.m PSParser.h PSLexer.h
	$(CC) $(CFLAGS) -c PSParser.m -o Objects/PSParser.o

Objects/PS.o: PS.m PSParser.h PSLexer.h
	$(CC) $(CFLAGS) -c PS.m -o Objects/PS.o

Objects/PSStandardLibrary.o: PSStandardLibrary.m PSStandardLibrary.h
	$(CC) $(CFLAGS) -c PSStandardLibrary.m -o Objects/PSStandardLibrary.o

clean:
	rm -rf Objects/*.o PS
