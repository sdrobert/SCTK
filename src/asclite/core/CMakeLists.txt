cmake_minimum_required(VERSION 3.16)
project(SCTK_asclite_core LANGUAGES CXX)

include(CheckIncludeFiles)
check_include_files("stdlib.h;stdarg.h;string.h;float.h" STDC_HEADERS)
check_include_files(sys/types.h HAVE_SYS_TYPES_H LANGUAGE C)
check_include_files(sys/stat.h HAVE_SYS_STAT_H LANGUAGE C)
check_include_files(stdlib.h HAVE_STDLIB_H LANGUAGE C)
check_include_files(stddef.h HAVE_STDDEF_H LANGUAGE C)
check_include_files(string.h HAVE_STRING_H LANGUAGE C)
check_include_files(strings.h HAVE_STRINGS_H LANGUAGE C)
check_include_files(inttypes.h HAVE_INTTYPES_H LANGUAGE C)
check_include_files(stdint.h HAVE_STDINT_H LANGUAGE C)
check_include_files(unistd.h HAVE_UNISTD_H LANGUAGE C)

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

foreach(macroname
  "HAVE_LIBM" "STDC_HEADERS" "HAVE_SYS_TYPES_H" "HAVE_SYS_STAT_H"
  "HAVE_STDLIB_H" "HAVE_STDDEF_H" "HAVE_STRING_H" "HAVE_STRINGS_H"
  "HAVE_INTTYPES_H" "HAVE_STDINT_H" "HAVE_UNISTD_H")
  if (${macroname})
    target_compile_definitions(asclite-core PUBLIC ${macroname})
  endif()
endforeach()

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