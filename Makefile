UNAME := $(strip $(shell uname -s))

# Custom project data is placed in file "Makefile_project"
# This file contain only common instructions

include Makefile_project

# Common flags

ifndef $(CC)
	CC = gcc
endif
ifndef $(CXX)
	CXX = g++
endif
ifndef $(FC)
	FC = gfortran
endif
ifndef $(LD)
	LD = ld
endif

ifeq ($(MODE),C)
	COMP = $(CC)
endif
ifeq ($(MODE),C++)
	COMP = $(CXX)
endif
ifeq ($(MODE),FORTRAN)
	COMP = $(FC)
endif

CFLAGS += -Wall

CXXFLAGS += -Wall

FFLAGS += -Wall -fimplicit-none -ffree-form -Jmod -Imod

# Compilation

ifeq ($(sources_dir),)
	sources_dir = src
endif

objects = $(addprefix obj/, $(addsuffix .o, $(basename $(sources)) $(resources)))
objectsd = $(addprefix objd/, $(addsuffix .o, $(basename $(sources)) $(resources)))

ifeq ($(UNAME),windows32)
ifneq ($(windows_rc),)
	objects += obj/$(target).rc.o
	objectsd += objd/$(target).rc.o
endif
endif

ifeq ($(UNAME),windows32)
	exe_suffix = .exe
else
	exe_suffix =
endif

# Make targets

default_configuration = $(word 1, $(CONFIGURATIONS))

default : $(default_configuration)

clean : clean_$(default_configuration)

release : $(objects)
ifeq ($(BUILD_EXE),TRUE)
	@mkdir -p bin
	$(COMP) $(LDFLAGS) -o bin/$(target)$(exe_suffix) $(objects) $(ext_objects) $(LIBS)
endif
ifeq ($(BUILD_LIB),TRUE)
	@mkdir -p lib
	ar rcs lib/lib$(target).a $(objects) $(ext_objects)
endif
ifeq ($(BUILD_DLL),TRUE)
	@mkdir -p dll
	$(COMP) -shared \
		-Wl,--output-def,dll/$(target).def \
		-Wl,--out-implib,dll/lib$(target).a \
		-o dll/$(target).dll $(objects) $(ext_objects) $(LIBS)
endif

debug : $(objectsd)
ifeq ($(BUILD_EXE),TRUE)
	@mkdir -p bin
	$(COMP) $(LDFLAGS) -o bin/$(target)d$(exe_suffix) $(objectsd) $(ext_objectsd) $(LIBSD)
endif
ifeq ($(BUILD_LIB),TRUE)
	@mkdir -p lib
	ar rcs lib/lib$(target)d.a $(objectsd) $(ext_objectsd)
endif
ifeq ($(BUILD_DLL),TRUE)
	@mkdir -p dll
	$(COMP) -shared \
		-Wl,--output-def,dll/$(target)d.def \
		-Wl,--out-implib,dll/lib$(target)d.a \
		-o dll/$(target)d.dll $(objectsd) $(ext_objectsd) $(LIBSD)
endif

obj/%.o : $(sources_dir)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -c -o $@ $<

objd/%.o : $(sources_dir)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -O0 -g $(INCLUDES) -c -o $@ $<

obj/%.o : $(sources_dir)/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c -o $@ $<

objd/%.o : $(sources_dir)/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -O0 -g $(INCLUDES) -c -o $@ $<

obj/%.o : $(sources_dir)/%.f90
	@mkdir -p $(dir $@)
	@mkdir -p mod
	$(FC) $(FFLAGS) $(INCLUDES) -c -o $@ $<

objd/%.o : $(sources_dir)/%.f90
	@mkdir -p $(dir $@)
	@mkdir -p mod
	$(FC) $(FFLAGS) -O0 -g $(INCLUDES) -c -o $@ $<

obj/%.o : res/%
	@mkdir -p $(dir $@)
	$(LD) -r -b binary -o $@ $<

objd/%.o : res/%
	@mkdir -p $(dir $@)
	$(LD) -r -b binary -o $@ $<

obj/$(target).rc.o : $(windows_rc)
	@mkdir -p $(dir $@)
	windres $< $@

objd/$(target).rc.o : $(windows_rc)
	@mkdir -p $(dir $@)
	windres $< $@

.PHONY : doc
doc :
ifeq ($(BUILD_DOC),TRUE)
	@mkdir -p doc/html
	doxygen doc/Doxyfile
endif

clean_release :
	rm -f $(objects)
ifeq ($(MODE),FORTRAN)
	rm -f mod/*
endif
ifeq ($(BUILD_EXE),TRUE)
	rm -f bin/$(target)$(exe_suffix)
endif
ifeq ($(BUILD_LIB),TRUE)
	rm -f lib/lib$(target).a
endif
ifeq ($(BUILD_DLL),TRUE)
	rm -f dll/$(target).def
	rm -f dll/lib$(target).a
	rm -f dll/$(target).dll
endif

clean_debug :
	rm -f $(objectsd)
ifeq ($(MODE),FORTRAN)
	rm -f mod/*
endif
ifeq ($(BUILD_EXE),TRUE)
	rm -f bin/$(target)d$(exe_suffix)
endif
ifeq ($(BUILD_LIB),TRUE)
	rm -f lib/lib$(target)d.a
endif
ifeq ($(BUILD_DLL),TRUE)
	rm -f dll/$(target)d.def
	rm -f dll/lib$(target)d.a
	rm -f dll/$(target)d.dll
endif

DOC_FILES = $(strip $(shell ls -A doc/html))

clean_doc :
ifeq ($(BUILD_DOC),TRUE)
ifneq ($(DOC_FILES),)
	rm -f doc/html/*
endif
endif

all : $(CONFIGURATIONS)

cleanall : $(addprefix clean_, $(CONFIGURATIONS))

rebuild : cleanall all
