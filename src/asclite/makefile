#########   Main Makefile for the sctk  #############


####  Creation Date:  Aug 26, 2004
MAKE=make
### Set the installation prefix directory to the default.  (If
### relative paths are used, the are relative to two directories below
### 'src'.)
PREFIX=`cd ../../.. && pwd`

all clean distclean:
	(cd core && if test -f makefile ; then $(MAKE) $@ ; fi)
	(cd test && if test -f makefile ; then $(MAKE) $@ ; fi)

install:
	(cd core && if test -f makefile ; then $(MAKE) $@ ; fi)
	(cd test && if test -f makefile ; then $(MAKE) $@ ; fi)

config:
	(cd core && sh config.sh -prefix=${PREFIX})
	(cd test && sh config.sh -prefix=${PREFIX})

checkFast: all
	(cd testfiles && perl ascliteTest.pl -s std -a ../core/asclite -b ../../sclite/sclite)

setTests: all
	(cd testfiles && perl ascliteTest.pl -s all -a ../core/asclite -b ../../sclite/sclite -w)

check: all
	(cd core && if test -f makefile ; then $(MAKE) $@ ; fi)
	(cd test && if test -f makefile ; then $(MAKE) $@ ; fi)
	(cd testfiles && perl ascliteTest.pl -s all -a ../core/asclite -b ../../sclite/sclite)
