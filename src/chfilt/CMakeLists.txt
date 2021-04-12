cmake_minimum_required(VERSION 3.16)
project(SCTK_chfilt)
option(TESTING_CHFILT "Whether to test chfilt.pl" ON)

configure_file(chfilt.pl chfilt.pl COPYONLY)

install(FILES chfilt.pl TYPE BIN)

if (TESTING_CHFILT)
  find_package(Perl REQUIRED)

  #FIXME(sdrobert): switch to build hubscr.pl
  add_test(
    NAME test_chfilt
    COMMAND ${PERL_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/ChfiltTests.pl
      -i ${CMAKE_CURRENT_SOURCE_DIR}/../test_suite
      -h ${CMAKE_CURRENT_SOURCE_DIR}/../hubscr/hubscr.pl
  )
endif()