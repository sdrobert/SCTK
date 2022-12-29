cmake_minimum_required(VERSION 3.16)
project(SCTK_spkr2sad)

configure_file(spkr2sad.pl spkr2sad.pl COPYONLY)

install(FILES spkr2sad.pl TYPE BIN)
