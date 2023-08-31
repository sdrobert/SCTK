cmake_minimum_required(VERSION 3.16)
project(SCTK_asclite LANGUAGES CXX)
set(ASCLITE_TESTING_SUITE "all" CACHE STRING "Which suite of tests to run for asclite")
set_property(CACHE ASCLITE_TESTING_SUITE PROPERTY STRINGS
  "all" "sastt" "std" "mdm04" "mdm04ByFile" "cts04" "mdmVariations" "passed" "notpassed" "todebug" "none"
)


add_subdirectory(core)
if (NOT ASCLITE_TESTING_SUITE STREQUAL "none")
  add_subdirectory(test)

  find_package(Perl)
  if (PERL_FOUND)
    add_test(
      NAME perl_asclite_test
      COMMAND ${PERL_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/testfiles/ascliteTest.pl
        -s ${ASCLITE_TESTING_SUITE}
        -a $<TARGET_FILE:asclite>
        -b $<TARGET_FILE:sclite>
        -c ${CMAKE_CURRENT_SOURCE_DIR}/testfiles/scliteCompatTestOutDir
        -d ${CMAKE_CURRENT_SOURCE_DIR}/testfiles/ascliteTestOutDir
        -o ${CMAKE_CURRENT_BINARY_DIR}/out
    )
  endif()
endif()