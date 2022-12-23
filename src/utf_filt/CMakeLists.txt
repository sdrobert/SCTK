cmake_minimum_required(VERSION 3.16)
project(SCTK_utf_filt)
find_package(Perl REQUIRED)
option(
  FORCE_UTF_FILT
  "Whether to force installation of utf_filt.pl, regardless of whether \
  nsgmls and the Perl module are available"
  OFF
)

set(TESTING_UTF_DEFAULT ON CACHE BOOL "" FORCE)
set(TRP_PATH "" CACHE STRING "" FORCE)
mark_as_advanced(TESTING_UTF_DEFAULT TRP_PATH)

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
message(STATUS "Checking for perl module Tag::Reader::Perl")
if (TESTING_UTF_FILT)
  if (NOT TRP_PATH)
    execute_process(
      COMMAND ${PERL_EXECUTABLE} -MTag::Reader::Perl -e "print \$INC{\"Tag/Reader/Perl.pm\"}"
      RESULT_VARIABLE TRP_RETCODE
      OUTPUT_VARIABLE TRP_PATH
      OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_QUIET
    )
  endif()
  if (TRP_RETCODE EQUAL 0)
    message(STATUS "Checking for perl module Tag::Reader::Perl - found at ${TRP_PATH}")
  else()
    set(TESTING_UTF_DEFAULT OFF)
    set(TRP_PATH "")
    if (FORCE_UTF_FILT)
      message(
        WARNING
        "Perl module Tag::Reader::Perl could not be found. \
        FORCE_UTF_FILT is true so we will continue, but you'll likely run \
        into errors if you try to run utf_filt.pl later."
      )
      set(TRP_PATH "Tag::Reader::Perl")
    else()
      message(
        FATAL_ERROR
        "Perl module Tag::Reader::Perl could not be found. \
        Either install the module (e.g. 'cpanm Tag::Reader::Perl') or force installation \
        to continue with -DFORCE_UTF_FILT=ON."
      )
    endif()
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
      -e ${CMAKE_CURRENT_SOURCE_DIR}/utf-1.2.dtd
      -o out
  )
endif()