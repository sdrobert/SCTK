cmake_minimum_required(VERSION 3.16)
project(SCTK_tanween_filt)
option(TESTING_TANWEEN_FILT "Whether to test Hamza Norm script" ON)

configure_file(tanweenFilt.pl tanweenFilt.pl COPYONLY)

install(FILES tanweenFilt.pl TYPE BIN)

if (TESTING_TANWEEN_FILT)
  find_package(Perl REQUIRED)
  add_test(
    NAME test_tanween_filt
    COMMAND ${PERL_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/TanweenFiltTests.pl
      -i ${CMAKE_CURRENT_SOURCE_DIR}/../test_suite
      -o out
  )
endif()