cmake_minimum_required(VERSION 3.16)
project(SCTK_md_eval)

# No need to copy from source directory - no testing needed
# FIXME(sdrobert): the script test/RunTests.sh might be a good starting point,
# but it looks like a number of these tests fail. The test suite was removed
# as a target of the makefiles some time in the past, so it was probably
# intentional

install(FILES md-eval.pl TYPE BIN)
