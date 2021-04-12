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
  find_package(Perl REQUIRED)
  add_test(
    NAME test_ctm_validator
    COMMAND ${PERL_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/RFilter1Tests.pl
      -i ${CMAKE_CURRENT_SOURCE_DIR}/../test_suite
      $<TARGET_FILE:rfilter1>
  )
endif()