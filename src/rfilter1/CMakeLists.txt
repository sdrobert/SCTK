cmake_minimum_required(VERSION 3.16)
project(SCTK_rfilter1 LANGUAGES C)
option(TESTING_RFILTER1 "Whether to test rfilter1" ON)

# this one's really weird. The c source in the 'include/' directory are
# added to the end of rfilter1.c via #include directives. Uggh.

add_executable(rfilter1 rfilter1.c)
target_include_directories(rfilter1 PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

install(
  TARGETS rfilter1
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

if (TESTING_RFILTER1)
  if (UNIX)
    # easy enough for unix
    add_test(
      NAME test_rfilter1_arb2004
      COMMAND bash -c "$1 $2.glm < $2.txt | diff - $2.txt.rfilter1" -- $<TARGET_FILE:rfilter1> ${CMAKE_CURRENT_SOURCE_DIR}/../test_suite/test.arb2004
    )
    add_test(
      NAME test_rfilter1_man2004
      COMMAND bash -c "$1 $2.glm < $2.txt | diff - $2.txt.rfilter1" -- $<TARGET_FILE:rfilter1> ${CMAKE_CURRENT_SOURCE_DIR}/../test_suite/test.man2004
    )
  elseif (WIN32)
    # uh oh
  endif()
# ./rfilter1 ../test_suite/test.arb2004.glm < ../test_suite/test.arb2004.txt | diff - ../test_suite/test.arb2004.txt.rfilter1
# ./rfilter1 ../test_suite/test.man2004.glm < ../test_suite/test.man2004.txt | diff - ../test_suite/test.man2004.txt.rfilter1
endif()