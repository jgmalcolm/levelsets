CFLAGS = -Wall -std=c99
MAKE=make --no-print-directory
DFLAGS = $(shell test -f .DEBUG && echo -g -DDEBUG || echo -O -DNDEBUG)
CFLAGS += $(DFLAGS)
LDLIBS =

#- Mac
MFLAGS = -D_MEX_ -I/Applications/MATLAB74/extern/include/
MEXT = mexmaci
#- Linux
#MFLAGS = -D_MEX_ -I/opt/matlabR2006a/extern/include/
#MEXT = mexglx


MEX = mex -cxx
CFLAGS += $(MFLAGS)

BIN=../ls_discrete.$(MEXT)
SRC=ls_discrete main_mex icoll move bitfield

all: .depend $(BIN)

$(BIN): $(patsubst %, %.o, $(SRC))

../%.$(MEXT): %.o
	$(MEX) -o $@ $^ $(LDLIBS)

.depend: *.c *.h
	$(CC) -MM $(CFLAGS) $(filter-out %.h, $^) >$@

clean:
	rm -f $(patsubst %, %.o, $(SRC)) $(BIN) main_*.o
debug:
	@test -f .DEBUG && (rm .DEBUG; echo off) || (touch .DEBUG; echo on)
	@$(MAKE) clean

include .depend
