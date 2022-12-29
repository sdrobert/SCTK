cmake_minimum_required(VERSION 3.16)
project(SCTK_rttm_smooth)

configure_file(rttmSmooth.pl rttmSmooth.pl COPYONLY)

install(FILES rttmSmooth.pl TYPE BIN)
