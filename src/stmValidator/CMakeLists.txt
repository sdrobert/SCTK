cmake_minimum_required(VERSION 3.16)
project(SCTK_stm_validator)
option(TESTING_STM_VALIDATOR "Whether to test stmValidator.pl" ON)

find_package(Perl REQUIRED)

add_custom_target(
  stm_validator ALL
  COMMAND ${PERL_EXECUTABLE} buildInstallVersion.pl > ${CMAKE_CURRENT_BINARY_DIR}/stmValidator.pl
  BYPRODUCTS stmValidator.pl
  SOURCES stmValidator-main.pl buildInstallVersion.pl
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/stmValidator.pl TYPE BIN)

if (TESTING_STM_VALIDATOR)
  add_test(
    NAME test_stm_validator
    COMMAND ${PERL_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/StmValidatorTests.pl
      -i ${CMAKE_CURRENT_SOURCE_DIR}/test_suite
  )
endif()
