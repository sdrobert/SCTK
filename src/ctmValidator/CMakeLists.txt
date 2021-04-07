cmake_minimum_required(VERSION 3.16)
project(SCTK_ctm_validator)
option(TESTING_CTM_VALIDATOR "Whether to test CTM Validator" ON)

# Data::Dumper and Getopt::Long are core, I think

configure_file(ctmValidator.pl ctmValidator.pl COPYONLY)

install(FILES ctmValidator.pl TYPE BIN)

if (TESTING_CTM_VALIDATOR)
  find_package(Perl REQUIRED)
  if (UNIX)
    add_test(
      NAME test_ctm_validator
      COMMAND sh RunTest.sh ${CMAKE_CURRENT_BINARY_DIR}/ctmValidator.pl
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/test_suite)
  endif()
endif()