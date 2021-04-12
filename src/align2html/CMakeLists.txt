cmake_minimum_required(VERSION 3.16)
project(SCTK_align2html)

find_package(Perl REQUIRED)

add_custom_target(
  align2html ALL
  COMMAND ${PERL_EXECUTABLE} buildInstallVersion.pl > ${CMAKE_CURRENT_BINARY_DIR}/align2html.pl
  BYPRODUCTS align2html.pl
  SOURCES align2html-main.pl buildInstallVersion.pl
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/align2html.pl TYPE BIN)