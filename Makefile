include config.mk

TARGET:=.
ifeq (${TARGET},)
    $(error "Cannot use TARGET as empty string!")
endif
ALL_SRCS:=$(wildcard **/*.cc) $(wildcard *.cc)
BIN_SRCS:=$(wildcard main/**/*.cc) $(wildcard main/*.cc)
TEST_SRCS:=$(wildcard **/*_test.cc) $(wildcard *_test.cc)
BINS:=$(BIN_SRCS:main/%.cc=${TARGET}/bin/%)
TEST_NAMES:=$(TEST_SRCS:%.cc=build/%)
TESTS:=$(TEST_NAMES:%=${TARGET}/%)
RUNTEST:=$(TEST_NAMES:%=${TARGET}/.test_outputs/%)
SRCS:=$(filter-out ${BIN_SRCS}, ${ALL_SRCS})
SRCS:=$(filter-out ${TEST_SRCS}, ${SRCS})
ALL_OBJS:=$(ALL_SRCS:%.cc=${TARGET}/build/%.o)
OBJS:=$(SRCS:%.cc=${TARGET}/build/%.o)
DEPS:=$(ALL_SRCS:%.cc=${TARGET}/.deps/%.d)
DIRS:=$(dir ${ALL_OBJS}) $(dir ${DEPS}) \
	  $(dir ${BINS}) $(dir ${TESTS}) \
	  $(dir ${RUNTEST}) ${TARGET}/build

$(shell mkdir -p $(DIRS))

all: ${BINS}

test: ${RUNTEST}

clean:
	rm -rf ${TARGET}/bin/ ${TARGET}/build/ ${TARGET}/.deps/ ${TARGET}/.test_outputs/
	[ "${TARGET}" != "." ] && rmdir ${TARGET} || true

.PHONY: clean all test

${TARGET}/.deps/%.d: %.cc Makefile config.mk
	${CXX} $< -M -MM -MP -MT $(patsubst ${TARGET}/.deps/%.d,${TARGET}/build/%.o,$@) \
		-o $@ ${CXXFLAGS}

${TARGET}/build/%_test.o: %_test.cc ${TARGET}/.deps/%_test.d
	${CXX} $< -c -o $@ ${CXXFLAGS} $(shell pkg-config --cflags gmock gtest)

${TARGET}/build/%.o: %.cc ${TARGET}/.deps/%.d
	${CXX} $< -c -o $@ ${CXXFLAGS}

${TARGET}/build/%_test: ${TARGET}/build/%_test.o ${OBJS}
	${CXX} $^ -o $@ ${CXXFLAGS} ${LDFLAGS} $(shell pkg-config --libs gmock gtest_main)

${TARGET}/bin/%: ${TARGET}/build/main/%.o ${OBJS}
	${CXX} $^ -o $@ ${CXXFLAGS} ${LDFLAGS}

${TARGET}/.test_outputs/%: ${TARGET}/%
	./$^ &> $@ || ( cat $@ && exit 1 )

.PRECIOUS: ${DEPS} ${ALL_OBJS} ${TESTS}

-include ${DEPS}
