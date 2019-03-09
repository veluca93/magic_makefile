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
ALL_OBJS:=$(ALL_SRCS:%.cc=${TGT}build/%.o)
ARCHIVES:=$(ALL_OBJS:%.o=%.o.tar)
TEST_OBJS:=$(TEST_SRCS:%.cc=${TGT}build/%.o)
OTHER_OBJS:=$(filter-out ${TEST_OBJS}, ${ALL_OBJS})
DEPS:=$(ALL_SRCS:%.cc=${TGT}.deps/%.d)
OBJDEPS:=$(DEPS:%.d=%.od)
DIRS:=$(dir ${ALL_OBJS}) $(dir ${DEPS}) \
	  $(dir ${BINS}) $(dir ${TESTS}) \
	  $(dir ${RUNTEST}) ${TGT}build

MAKEFILEDIR := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))

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

include config.mk

.PHONY: clean all test

${DEPS}: ${TGT}.deps/%.d: %.cc Makefile config.mk
	${CXX} $< -M -MM -MP -MT $(patsubst ${TGT}.deps/%.d,${TGT}build/%.o,$@) \
		-o $@ ${CXXFLAGS}

${OBJDEPS}: ${TGT}.deps/%.od: ${TGT}.deps/%.d ${MAKEFILEDIR}obj_deps.py
	${MAKEFILEDIR}obj_deps.py $< "${TGT}" <<< "${ALL_OBJS}" > $@
	
${TEST_OBJS}: ${TGT}build/%_test.o: %_test.cc ${TGT}.deps/%_test.d ${TGT}.deps/%_test.od
	${CXX} $< -c -o $@ ${CXXFLAGS} $(shell pkg-config --cflags gmock gtest)

${OTHER_OBJS}: ${TGT}build/%.o: %.cc ${TGT}.deps/%.d ${TGT}.deps/%.od
	${CXX} $< -c -o $@ ${CXXFLAGS}

%.o.tar: %.o
	${MAKEFILEDIR}make_archive.sh $@ $^

${TESTS}: ${TGT}build/%_test: ${TGT}build/%_test.o.tar | ${TGT}.deps/%_test.od
	mkdir -p ${@}_deps
	for dep in $^; do tar xf $$dep -C ${@}_deps ; done
	${CXX} $$(find ${@}_deps/ -type f ) -o $@ ${CXXFLAGS} ${LDFLAGS} \
		$(shell pkg-config --libs gmock gtest_main)
	rm -rf ${@}_deps

${BINS}: ${TGT}bin/%: ${TGT}build/main/%.o.tar | ${TGT}.deps/main/%.od
	mkdir -p ${@}_deps
	for dep in $^; do tar xf $$dep -C ${@}_deps ; done
	${CXX} $$(find ${@}_deps/ -type f ) -o $@ ${CXXFLAGS} ${LDFLAGS}
	rm -rf ${@}_deps

ifeq (${TGT},)
${RUNTEST}: .test_outputs/%: %
	./$^ &> $@ || ( cat $@ && exit 1 )
else
${RUNTEST}: ${TGT}.test_outputs/%: ${TGT}%
	cd ${TGT} && ./$^ &> $@ || ( cat $@ && exit 1 )
endif

.PRECIOUS: ${DEPS} ${OBJDEPS} ${ALL_OBJS} ${TESTS}

-include ${DEPS} ${OBJDEPS}
