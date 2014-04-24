function compile
  mex -O -o ../ls_discrete ls_discrete.c icoll.c bitfield.c main_mex.c move.c
