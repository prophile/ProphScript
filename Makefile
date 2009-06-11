#CC=clang
#LD=clang
#CFLAGS=-O4 -emit-llvm -DNDEBUG
#LDFLAGS=-framework Foundation
CC=gcc
LD=gcc
CFLAGS=-O0 -gfull -arch x86_64
LDFLAGS=-framework Foundation -arch x86_64 -gfull

PS: PSLexer.o PSParser.o PS.o PSInterpreter.o PSStandardLibrary.o
	$(LD) $(LDFLAGS) -o PS PSLexer.o PSParser.o PS.o PSInterpreter.o PSStandardLibrary.o

PSInterpreter.o: PSInterpreter.m PSInterpreter.h PSParser.h PSLexer.h PSStandardLibrary.h
	$(CC) $(CFLAGS) -c PSInterpreter.m -o PSInterpreter.o

PSLexer.o: PSLexer.m PSLexer.h
	$(CC) $(CFLAGS) -c PSLexer.m -o PSLexer.o

PSParser.o: PSParser.m PSParser.h PSLexer.h
	$(CC) $(CFLAGS) -c PSParser.m -o PSParser.o

PS.o: PS.m PSParser.h PSLexer.h
	$(CC) $(CFLAGS) -c PS.m -o PS.o

PSStandardLibrary.o: PSStandardLibrary.m PSStandardLibrary.h
	$(CC) $(CFLAGS) -c PSStandardLibrary.m -o PSStandardLibrary.o

clean:
	rm -f *.o PS
