cmake_minimum_required(VERSION 3.16)
project(SCTK_rttm_validator)
option(TESTING_RTTM_VALIDATOR "Whether to test the RTTM style validator" ON)

configure_file(rttmValidator.pl rttmValidator.pl COPYONLY)

install(FILES rttmValidator.pl TYPE BIN)

if (TESTING_RTTM_VALIDATOR)
  find_package(Perl REQUIRED)
  add_test(
    NAME test_rttm_validator
    COMMAND ${PERL_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/RttmValidatorTests.pl
      -i ${CMAKE_CURRENT_SOURCE_DIR}/test_suite
  )
endif()