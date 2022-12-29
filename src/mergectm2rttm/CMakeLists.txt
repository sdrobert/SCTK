cmake_minimum_required(VERSION 3.16)
project(SCTK_mergectm2rttm)

configure_file(mergectm2rttm.pl mergectm2rttm.pl COPYONLY)

install(FILES mergectm2rttm.pl TYPE BIN)
