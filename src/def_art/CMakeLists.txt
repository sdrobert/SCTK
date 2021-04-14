cmake_minimum_required(VERSION 3.16)
project(SCTK_def_art)

configure_file(def_art.pl def_art.pl COPYONLY)

install(FILES def_art.pl TYPE BIN)
