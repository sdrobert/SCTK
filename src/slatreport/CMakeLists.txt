cmake_minimum_required(VERSION 3.16)
project(SCTK_slatreport)
option(TESTING_SLATREPORT "Whether to test the RTTM style validator" ON)

configure_file(slatreport.pl slatreport.pl COPYONLY)

# You don't actually need gnuplot to run... you just won't be able to generate
# PNG files

install(FILES slatreport.pl TYPE BIN)

if (TESTING_SLATREPORT)
  find_package(Perl REQUIRED)
  add_test(
    NAME test_slatreport
    COMMAND ${PERL_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/slatTest.pl
      -i ${CMAKE_CURRENT_SOURCE_DIR}/../test_suite
  )
endif()