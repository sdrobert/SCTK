cmake_minimum_required(VERSION 3.16)
project(SCTK_ctm_validator)
option(TESTING_CTM_VALIDATOR "Whether to test CTM Validator" ON)

configure_file(ctmValidator.pl ctmValidator.pl COPYONLY)

install(FILES ctmValidator.pl TYPE BIN)

if (TESTING_CTM_VALIDATOR)
  find_package(Perl REQUIRED)
  add_test(
    NAME test_ctm_validator
    COMMAND ${PERL_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/CtmValidatorTests.pl
      -i ${CMAKE_CURRENT_SOURCE_DIR}/test_suite
  )
endif()