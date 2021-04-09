cmake_minimum_required(VERSION 3.16)
project(SCTK_csrfilt)
option(TESTING_CSRFILT "Whether to test csrfilt.pl" ON)

configure_file(csrfilt.pl csrfilt.pl COPYONLY)

install(FILES csrfilt.pl TYPE BIN)

if (TESTING_CSRFILT)
  find_package(Perl REQUIRED)

  add_test(
    NAME test_csrfilt
    COMMAND ${PERL_EXECUTABLE} RunTests.pl -r $<TARGET_FILE:rfilter1>
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  )
endif()