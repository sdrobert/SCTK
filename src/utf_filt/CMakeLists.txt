cmake_minimum_required(VERSION 3.16)
project(SCTK_utf_filt)
find_package(Perl REQUIRED)
option(
  FORCE_UTF_FILT
  "Whether to force installation of utf_filt.pl, regardless of whether \
  nsgmls and the Perl module are available"
  OFF
)

set(TESTING_UTF_DEFAULT ON)
find_program(NSGMLS NAMES nsgmls onsgmls DOC "Path to (o)nsgmls executable")
if (NOT NSGMLS)
  set(TESTING_UTF_DEFAULT OFF)
  if (FORCE_UTF_FILT)
    message(
      WARNING
      "Neither the nsgnmls nor onsgmls executable was found.\
      FORCE_UTF_FILT is true so we will continue, but you'll likely run \
      into errors if you try to run utf_filt.pl later.")
    set(NSGMLS "nsgmls")  # stop bugging us on successive builds
  else()
    message(
      FATAL_ERROR
      "Neither the nsgnmls nor onsgmls executable was found.\
      Either hard-code the path with -DNSGMLS=<path> or force installation \
      to continue with -DFORCE_UTF_FILT=ON."
    )
  endif()
endif()
message(STATUS "Checking for perl module SGMLS")
if (NOT SGMLS_PATH)
  execute_process(
    COMMAND ${PERL_EXECUTABLE} -MSGMLS -e "print \$INC{\"SGMLS.pm\"}"
    RESULT_VARIABLE SGMLS_RETCODE
    OUTPUT_VARIABLE SGMLS_PATH
    OUTPUT_STRIP_TRAILING_WHITESPACE
    ERROR_QUIET
  )
endif()
if (SGMLS_RETCODE EQUAL 0)
  message(STATUS "Checking for perl module SGMLS - found at ${SGMLS_PATH}")
else()
  set(TESTING_UTF_DEFAULT OFF)
  if (FORCE_UTF_FILT)
    message(
      WARNING
      "Perl module SGMLS could not be found. \
      FORCE_UTF_FILT is true so we will continue, but you'll likely run \
      into errors if you try to run utf_filt.pl later."
    )
    set(SGMLS_PATH "sgmls")
  else()
    message(
      FATAL_ERROR
      "Perl module SGMLS could not be found. \
      Either install the module (e.g. 'cpanm SGMLS') or force installation \
      to continue with -DFORCE_UTF_FILT=ON."
    )
  endif()
endif()

option(TESTING_UTF_FILT "Whether to test utf_filt.pl" ${TESTING_UTF_DEFAULT})

configure_file(utf_filt.pl.in utf_filt.pl @ONLY)

install(FILES utf_filt.pl TYPE BIN)

if (TESTING_UTF_FILT)
  add_test(
    NAME test_utf_filt
    COMMAND ${PERL_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/UtfFiltTests.pl
      -i ${CMAKE_CURRENT_SOURCE_DIR}/../test_suite
  )
endif()