cmake_minimum_required(VERSION 3.16)
project(SCTK_asclite_test LANGUAGES CXX)

add_executable(asclite_test
  alignedsegment_test.cpp alignedspeech_test.cpp alignment_test.cpp
  asctools.cpp benchmark.cpp perf_benchmark.cpp std_benchmark.cpp
  test_ctm_inputparser.cpp test_ctmstm_segmentor.cpp test_graph.cpp
  test_graphalignedsegment.cpp test_graphalignedtoken.cpp
  test_levenshtein.cpp test_properties.cpp test_rttm_inputparser.cpp
  test_segment.cpp test_speech.cpp test_speechset.cpp
  test_stm_inputparser.cpp test_token.cpp test_trn_inputparser.cpp
  test_trntrn_segmentor.cpp test_unit.cpp tokenalignment_test.cpp
)
target_link_libraries(asclite_test PUBLIC asclite-core)
target_include_directories(asclite_test PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

add_test(NAME test_asclite COMMAND $<TARGET_FILE:asclite_test> -d ${CMAKE_CURRENT_SOURCE_DIR}/../testfiles)