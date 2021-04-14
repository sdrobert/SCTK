cmake_minimum_required(VERSION 3.16)
project(SCTK_asclite_core LANGUAGES CXX)

include(CheckIncludeFile)
check_include_file(sys/types.h HAVE_SYS_TYPES_H)
check_include_file(sys/stat.h HAVE_SYS_STAT_H)
check_include_file(stdlib.h HAVE_STDLIB_H)
check_include_file(stddef.h HAVE_STDDEF_H)
if (DEFINED HAVE_STDLIB_H AND DEFINED HAVE_STDEF_H)
  set(HAVE_STDC_HEADERS ON)
endif ()
check_include_file(string.h HAVE_STRING_H)
if (NOT DEFINED HAVE_STDC_HEADERS)
  check_include_file(memory.h HAVE_MEMORY_H)
endif ()
check_include_file(strings.h HAVE_STRINGS_H)
check_include_file(inttypes.h HAVE_INTTYPES_H)
check_include_file(stdint.h HAVE_STDINT_H)
check_include_file(unistd.h HAVE_UNISTD_H)

include(CheckLibraryExists)
check_library_exists(m pow "" HAVE_LIBM)

# we separate main.cpp from the rest so that we can link the rest to the
# testing stuff
add_library(asclite-core
  lzma/Alloc.c lzma/LzFind.c lzma/LzmaDec.c lzma/LzmaEnc.c lzma/LzmaLib.c
  alignedsegment.cpp alignedsegmentiterator.cpp alignedspeech.cpp
  alignedspeechiterator.cpp aligner.cpp alignment.cpp arraylevenshteinmatrix.cpp
  checker.cpp compressedlevenshteinmatrix.cpp ctm_inputparser.cpp
  ctmstmrttm_segmentor.cpp filter.cpp graph_coordinate.cpp graph.cpp
  graphalignedsegment.cpp graphalignedtoken.cpp id.cpp inputparser.cpp
  levenshtein.cpp levenshteinmatrix.cpp linestyle_inputparser.cpp
  logger.cpp properties.cpp rawsys_reportgenerator.cpp
  recording.cpp reportgenerator.cpp rttm_inputparser.cpp scorer.cpp
  segment.cpp segmentor.cpp segmentsgroup.cpp sgml_generic_reportgenerator.cpp
  sgml_reportgenerator.cpp speakermatch.cpp speech.cpp speechset.cpp
  spkrautooverlap.cpp statistics.cpp stm_inputparser.cpp stt_scorer.cpp
  timedobject.cpp token.cpp tokenalignment.cpp trn_inputparser.cpp
  trntrn_segmentor.cpp uemfilter.cpp
)
target_include_directories(asclite-core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

if (HAVE_SYS_TYPES_H)
  target_compile_definitions(asclite-core PUBLIC HAVE_SYS_TYPES_H)
endif()
if (HAVE_SYS_STAT_H)
  target_compile_definitions(asclite-core PUBLIC HAVE_SYS_STAT_H)
endif()
if (HAVE_STDLIB_H)
  target_compile_definitions(asclite-core PUBLIC HAVE_STDLIB_H)
endif()
if (HAVE_STDDEF_H)
  target_compile_definitions(asclite-core PUBLIC HAVE_STDDEF_H)
endif()
if (HAVE_STDC_HEADERS)
  target_compile_definitions(asclite-core PUBLIC HAVE_STDC_HEADERS)
endif()
if (HAVE_STRING_H)
  target_compile_definitions(asclite-core PUBLIC HAVE_STRING_H)
endif()
if (HAVE_MEMORY_H)
  target_compile_definitions(asclite-core PUBLIC HAVE_MEMORY_H)
endif()
if (HAVE_STRINGS_H)
  target_compile_definitions(asclite-core PUBLIC HAVE_STRINGS_H)
endif()
if (HAVE_INTTYPES_H)
  target_compile_definitions(asclite-core PUBLIC HAVE_INTTYPES_H)
endif()
if (HAVE_STDINT_H)
  target_compile_definitions(asclite-core PUBLIC HAVE_STDINT_H)
endif()
if (HAVE_UNISTD_H)
  target_compile_definitions(asclite-core PUBLIC HAVE_UNISTD_H)
endif()
if (HAVE_LIBM)
  target_link_libraries(asclite-core PUBLIC m)
endif()

add_executable(asclite main.cpp)
# set_target_properties(asclite PROPERTIES SUFFIX "")
target_link_libraries(asclite PUBLIC asclite-core)

install(
  TARGETS asclite-core asclite
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)