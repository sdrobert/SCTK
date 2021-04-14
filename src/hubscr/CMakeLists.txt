cmake_minimum_required(VERSION 3.16)
project(SCTK_hubscr)
option(TESTING_HUBSCR "Whether to test the hubscr.pl script" ON)

configure_file(hubscr.pl hubscr.pl COPYONLY)

install(FILES hubscr.pl TYPE BIN)

if (TESTING_HUBSCR)
  find_package(Perl REQUIRED)
  add_test(
    NAME test_hubscr
    COMMAND ${PERL_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/HubscrTests.pl
      -e ${CMAKE_CURRENT_SOURCE_DIR}
      -i ${CMAKE_CURRENT_SOURCE_DIR}/../test_suite
      -p "\
$<TARGET_FILE_DIR:rfilter1>,\
$<TARGET_FILE_DIR:asclite>,\
$<TARGET_FILE_DIR:sclite>,\
${CMAKE_CURRENT_BINARY_DIR}/../csrfilt,\
${CMAKE_CURRENT_BINARY_DIR}/../def_art,\
${CMAKE_CURRENT_BINARY_DIR}/../acomp,\
${CMAKE_CURRENT_BINARY_DIR}/../hamzaNorm,\
${CMAKE_CURRENT_BINARY_DIR}/../md-eval,\
${CMAKE_CURRENT_BINARY_DIR}/../rttmSort,\
${CMAKE_CURRENT_BINARY_DIR}/../align2html,\
${CMAKE_CURRENT_BINARY_DIR}/../stm2rttm,\
${CMAKE_CURRENT_BINARY_DIR}/../ctmValidator,\
${CMAKE_CURRENT_BINARY_DIR}/../stmValidator,\
${CMAKE_CURRENT_BINARY_DIR}/../rttmValidator,\
${CMAKE_CURRENT_BINARY_DIR}/../tanweenFilt"
      -o out
  )
endif()