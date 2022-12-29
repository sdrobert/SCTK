cmake_minimum_required(VERSION 3.16)
project(SCTK_acomp)

configure_file(acomp.pl acomp.pl COPYONLY)

install(FILES acomp.pl TYPE BIN)
