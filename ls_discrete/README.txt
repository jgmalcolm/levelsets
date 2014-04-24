James Malcolm (malcolm@gatech.edu)
www.ece.gatech.edu/~malcolm

From papers:
    @InProceedings{Malcolm2008spie_ei,
      author = {J. Malcolm and Y. Rathi and A. Yezzi and A. Tannenbaum},
      title = {Fast approximate curve evolution},
      booktitle = {SPIE Electronic Imaging},
      year = 2008
    }
    @InProceedings{Malcolm2008spie_mi,
      author = {J. Malcolm and Y. Rathi and A. Yezzi and A. Tannenbaum},
      title = {Fast approximate surface evolution in arbitrary dimension},
      booktitle = {SPIE Medical Imaging},
      year = 2008
    }


For demo, run from inside Matlab:
  >> run
Select rectangular region (left click top left, drag and release at bottom
right)



To compile C version, from inside Matlab:
  >> cd src
  >> compile
  >> cd ..
  >> run

If it gives C99 complaints, ...
  In Linux, edit mexopts.sh and append '-std=c99' to end of appropriate CFLAGS
  variable

  In Windows, get a better compiler.  Just kidding.  Email me.
