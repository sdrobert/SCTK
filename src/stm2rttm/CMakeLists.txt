cmake_minimum_required(VERSION 3.16)
project(SCTK_stm2rttm)

configure_file(stm2rttm.pl stm2rttm.pl COPYONLY)

install(FILES stm2rttm.pl TYPE BIN)
