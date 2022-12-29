cmake_minimum_required(VERSION 3.16)
project(SCTK_rttm2ctm)

configure_file(rttm2ctm.pl rttm2ctm.pl COPYONLY)

install(FILES rttm2ctm.pl TYPE BIN)
