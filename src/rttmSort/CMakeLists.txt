cmake_minimum_required(VERSION 3.16)
project(SCTK_rttm_sort)

configure_file(rttmSort.pl rttmSort.pl COPYONLY)

install(FILES rttmSort.pl TYPE BIN)
