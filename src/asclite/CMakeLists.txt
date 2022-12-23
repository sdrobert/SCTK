cmake_minimum_required(VERSION 3.16)
project(SCTK_asclite LANGUAGES CXX)
option(ASCLITE_TESTING "Whether to build asclite test materials" ON)

add_subdirectory(core)
if (ASCLITE_TESTING)
  add_subdirectory(test)

  find_package(Perl)
  if (PERL_FOUND)
    add_test(
      NAME perl_asclite_test
      COMMAND ${PERL_EXECUTABLE} ascliteTest.pl
        -a $<TARGET_FILE:asclite>
        -b $<TARGET_FILE:sclite>
        -o ${CMAKE_CURRENT_BINARY_DIR}/out
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/testfiles)
  endif()
endif()