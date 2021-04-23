cmake_minimum_required(VERSION 3.16)
project(SCTK_sclite LANGUAGES C)

option(SCLITE_TESTING "Build testing suite" ON)

include(CheckIncludeFile)
check_include_file(unistd.h HAVE_UNISTD_H)
check_include_file(sys/time.h HAVE_SYS_TIME_H)

include(CheckLibraryExists)
check_library_exists(m pow "" HAVE_LIBM)


# this library is split into 4 libraries in the original makefiles.
# However, they were never linked separately. I also got an undefined
# symbol error for one. I decided to combine them.

add_library(sclite-core
  order.c rsprintf.c path.c text.c scores.c word.c rpg.c statdist.c
  pad.c sgml.c readpipe.c alex.c sc_dtl.c det.c wwscr_f.c corresp.c
  slm_intf.c rank.c range.c anovar.c signtest.c wilcoxon.c sentmcn.c
  mtchprs.c addarc1.c delarc1.c llist.c marc1.c arcseq1.c mnode1.c
  boolpr1.c killarc1.c net_adt.c knode2.c net_dp.c
  stm.c align.c dwtoke2.c fillmrks.c wtokeini.c lur.c stm2ctm.c ctm2ctm.c
  mfa.c cores.c
)
if (HAVE_UNISTD_H)
  target_compile_definitions(sclite-core PUBLIC HAVE_UNISTD_H)
endif()
if (HAVE_LIBM)
  target_link_libraries(sclite-core PUBLIC m)
  # I don't think this define is actually used anywhere
  target_compile_definitions(sclite-core PUBLIC HAVE_LIBM)
endif()
if (HAVE_SYS_TIME_H)
  target_compile_definitions(sclite-core PUBLIC HAVE_SYS_TIME_H)
endif()
target_include_directories(sclite-core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

add_executable(sclite sclite.c)
target_link_libraries(sclite PUBLIC sclite-core)

add_executable(sclite_tolower sclite_tolower.c)
target_link_libraries(sclite_tolower PUBLIC sclite-core)

add_executable(sc_stats sc_stats.c)
target_link_libraries(sc_stats PUBLIC sclite-core)

add_executable(rover rover.c)
target_link_libraries(rover PUBLIC sclite-core)

# set_target_properties(
#   sclite sclite_tolower sc_stats rover
#   PROPERTIES
#     SUFFIX ""
# )


install(
  TARGETS sclite-core sclite sclite_tolower sc_stats rover
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

if (SCLITE_TESTING)
  find_package(Perl REQUIRED)


  add_executable(sign sign.c)
  target_link_libraries(sign PUBLIC sclite-core)

  add_executable(sctkUnit sctkUnit.c)
  target_link_libraries(sctkUnit PUBLIC sclite-core)
  target_compile_definitions(sctkUnit PUBLIC TESTDATA=${CMAKE_CURRENT_SOURCE_DIR}/testdata)

  add_executable(mcnemar mcnemar.c)
  target_link_libraries(mcnemar PUBLIC sclite-core)

  add_test(NAME test_sign COMMAND $<TARGET_FILE:sign>)
  add_test(NAME test_sctkUnit COMMAND $<TARGET_FILE:sctkUnit>)
  add_test(NAME test_mcnemar COMMAND $<TARGET_FILE:mcnemar>)

  add_test(
    NAME test_sclite
    COMMAND ${PERL_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/ScliteTests.pl
      -i ${CMAKE_CURRENT_SOURCE_DIR}/testdata
      -s $<TARGET_FILE:sclite>
  )

  add_test(
    NAME test_sc_stats
    COMMAND ${PERL_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/ScStatsTests.pl
    -i ${CMAKE_CURRENT_SOURCE_DIR}/testdata
    -s $<TARGET_FILE:sc_stats>
  )

  # if (UNIX)
  #   add_test(NAME test_sclite COMMAND sh -c "./tsclite.sh -clean; ./tsclite.sh -ed $1 && ./tsclite.sh -clean" -- ${CMAKE_CURRENT_BINARY_DIR} WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/testdata)
  #   add_test(NAME test_sc_stats COMMAND sh -c "./tsc_stats.sh -clean; ./tsc_stats.sh -ed $1 && ./tsc_stats.sh -clean" == ${CMAKE_CURRENT_BINARY_DIR} WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/testdata)
  # endif (UNIX)
endif (SCLITE_TESTING)
