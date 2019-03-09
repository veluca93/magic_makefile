include config.mk

ifneq (${TARGET},)
TGT:=${TARGET}/
TGT:=${TGT://=/}
else
TGT:=
endif

ALL_SRCS:=$(wildcard **/*.cc) $(wildcard *.cc)
BIN_SRCS:=$(wildcard main/**/*.cc) $(wildcard main/*.cc)
TEST_SRCS:=$(wildcard **/*_test.cc) $(wildcard *_test.cc)
BINS:=$(BIN_SRCS:main/%.cc=${TGT}bin/%)
TEST_NAMES:=$(TEST_SRCS:%.cc=build/%)
TESTS:=$(TEST_NAMES:%=${TGT}%)
RUNTEST:=$(TEST_NAMES:%=${TGT}.test_outputs/%)
SRCS:=$(filter-out ${BIN_SRCS}, ${ALL_SRCS})
SRCS:=$(filter-out ${TEST_SRCS}, ${SRCS})
ALL_OBJS:=$(ALL_SRCS:%.cc=${TGT}build/%.o)
OBJS:=$(SRCS:%.cc=${TGT}build/%.o)
DEPS:=$(ALL_SRCS:%.cc=${TGT}.deps/%.d)
DIRS:=$(dir ${ALL_OBJS}) $(dir ${DEPS}) \
	  $(dir ${BINS}) $(dir ${TESTS}) \
	  $(dir ${RUNTEST}) ${TGT}build

$(shell mkdir -p $(DIRS))

all: ${BINS}

test: ${RUNTEST}

ifeq (${TGT},)
clean:
	rm -rf ${TGT}bin/ ${TGT}build/ ${TGT}.deps/ ${TGT}.test_outputs/
else
clean:
	rm -rf ${TGT}
endif

.PHONY: clean all test

${TGT}.deps/%.d: %.cc Makefile config.mk
	${CXX} $< -M -MM -MP -MT $(patsubst ${TGT}.deps/%.d,${TGT}build/%.o,$@) \
		-o $@ ${CXXFLAGS}

${TGT}build/%_test.o: %_test.cc ${TGT}.deps/%_test.d
	${CXX} $< -c -o $@ ${CXXFLAGS} $(shell pkg-config --cflags gmock gtest)

${TGT}build/%.o: %.cc ${TGT}.deps/%.d
	${CXX} $< -c -o $@ ${CXXFLAGS}

${TGT}build/%_test: ${TGT}build/%_test.o ${OBJS}
	${CXX} $^ -o $@ ${CXXFLAGS} ${LDFLAGS} $(shell pkg-config --libs gmock gtest_main)

${TGT}bin/%: ${TGT}build/main/%.o ${OBJS}
	${CXX} $^ -o $@ ${CXXFLAGS} ${LDFLAGS}

${TGT}.test_outputs/%: ${TGT}%
	./$^ &> $@ || ( cat $@ && exit 1 )

.PRECIOUS: ${DEPS} ${ALL_OBJS} ${TESTS}

-include ${DEPS}
