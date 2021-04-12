cmake_minimum_required(VERSION 3.16)
project(SCTK_hamza_norm)
option(TESTING_HAMZA_NORM "Whether to test Hamza Norm script" ON)

configure_file(hamzaNorm.pl hamzaNorm.pl COPYONLY)

install(FILES hamzaNorm.pl TYPE BIN)

if (TESTING_HAMZA_NORM)
  find_package(Perl REQUIRED)
  add_test(
    NAME test_hamza_norm
    COMMAND ${PERL_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/HamzaNormTests.pl
      -i ${CMAKE_CURRENT_SOURCE_DIR}/../test_suite
  )
endif()