cmake_minimum_required(VERSION 3.16)
project(SCTK_chfilt)
option(TESTING_CHFILT "Whether to test chfilt.pl" ON)

configure_file(chfilt.pl chfilt.pl COPYONLY)

install(FILES chfilt.pl TYPE BIN)

if (TESTING_CHFILT)
  find_package(Perl REQUIRED)

  if (UNIX)
    add_test(
      NAME test_chfilt_testmss
      COMMAND sh -c "$1 $2 -m -l english testmss.in -- - | diff - testmss.stm" -- ${PERL_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/chfilt.pl
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../test_suite
    )
    add_test(
      NAME test_chfilt_testmss_numbers
      COMMAND sh -c "$1 $2 -C numbers -m -l english testmss.in -- - | diff - testmss.numbers.stm" -- ${PERL_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/chfilt.pl
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../test_suite
    )
    add_test(
      NAME test_chfilt_test_optdel
      COMMAND sh -c "$1 $2 -l english -i -b 0 -e 999999 test.txt -- - | diff - test.txt.-optdel.stm" -- ${PERL_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/chfilt.pl
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../test_suite
    )
    add_test(
      NAME test_chfilt_test
      COMMAND sh -c "$1 $2 -d -l english -i -b 0 -e 999999 -k test.txt -- - | diff - test.txt.stm" -- ${PERL_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/chfilt.pl
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../test_suite
    )
    add_test(
      NAME test_chfilt_test_contexp
      COMMAND sh -c "$1 $2 -c -l english -i -b 0 -e 999999 -k test.txt -- - | diff - test.txt.-contexp.stm" -- ${PERL_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/chfilt.pl
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../test_suite
    )
    add_test(
      NAME test_chfilt_arb2004
      COMMAND sh -c "$1 $2 -c -l arabic -i -b 0 -e 999999 -d -k test.arb2004.txt -- - | diff - test.arb2004.txt.stm" -- ${PERL_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/chfilt.pl
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../test_suite
    )
    add_test(
      NAME test_chfilt_man2004
      COMMAND sh -c "$1 $2 -c -l mandarin -i -b 0 -e 999999 -d -k test.man2004.txt -- - | diff - test.man2004.txt.stm" -- ${PERL_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/chfilt.pl
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/../test_suite
    )
  endif()
endif()