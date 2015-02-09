# Custom project data is placed in file "Makefile_project"
# This file contain only common instructions

# Common parameters and flags

ifneq (,$(findstring /cygdrive/,$(PATH)))
    UNAME := cygwin
else
ifneq (,$(findstring system32,$(PATH)))
    UNAME := windows32
else
    UNAME := $(strip $(shell uname -s))
endif
endif

CC = gcc
CXX = g++
FC = gfortran
LD = ld

CFLAGS = -Wall
CXXFLAGS = -Wall
FFLAGS = -Wall -fimplicit-none -ffree-form -Jmod -Imod

# Directories

sources_dir = src

# Custom project data

include Makefile_project

# Compilation

ifeq ($(MODE),C)
	COMP = $(CC)
endif
ifeq ($(MODE),C++)
	COMP = $(CXX)
endif
ifeq ($(MODE),FORTRAN)
	COMP = $(FC)
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

all : $(CONFIGURATIONS)

clean : $(addprefix clean_,$(CONFIGURATIONS))

ifneq ($(filter release,$(CONFIGURATIONS)),)
release : $(objects)
ifneq ($(filter exe,$(TARGETS)),)
	@mkdir -p bin
	$(COMP) $(LDFLAGS) -o bin/$(target)$(exe_suffix) $(objects) $(ext_objects) $(LIBS)
endif
ifneq ($(filter lib,$(TARGETS)),)
	@mkdir -p lib
	ar rcs lib/lib$(target).a $(objects) $(ext_objects)
endif
ifneq ($(filter dll,$(TARGETS)),)
ifeq ($(UNAME),windows32)
	@mkdir -p dll
	$(COMP) -shared \
		-Wl,--output-def,dll/$(target).def \
		-Wl,--out-implib,dll/lib$(target).a \
		-o dll/$(target).dll $(objects) $(ext_objects) $(LIBS)
endif
endif
endif

ifneq ($(filter debug,$(CONFIGURATIONS)),)
debug : $(objectsd)
ifneq ($(filter exe,$(TARGETS)),)
	@mkdir -p bin
	$(COMP) $(LDFLAGS) -o bin/$(target)d$(exe_suffix) $(objectsd) $(ext_objectsd) $(LIBSD)
endif
ifneq ($(filter lib,$(TARGETS)),)
	@mkdir -p lib
	ar rcs lib/lib$(target)d.a $(objectsd) $(ext_objectsd)
endif
ifneq ($(filter dll,$(TARGETS)),)
ifeq ($(UNAME),windows32)
	@mkdir -p dll
	$(COMP) -shared \
		-Wl,--output-def,dll/$(target)d.def \
		-Wl,--out-implib,dll/lib$(target)d.a \
		-o dll/$(target)d.dll $(objectsd) $(ext_objectsd) $(LIBSD)
endif
endif
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

ifneq ($(filter doc,$(TARGETS)),)

.PHONY : doc
doc :
	@mkdir -p doc/html
	doxygen doc/Doxyfile

DOC_FILES = $(strip $(shell ls -A doc/html))

clean_doc :
ifneq ($(DOC_FILES),)
	rm -f doc/html/*
endif

endif

ifneq ($(filter release,$(CONFIGURATIONS)),)
clean_release :
	rm -f $(objects)
ifeq ($(MODE),FORTRAN)
	rm -f mod/*
endif
ifneq ($(filter exe,$(TARGETS)),)
	rm -f bin/$(target)$(exe_suffix)
endif
ifneq ($(filter lib,$(TARGETS)),)
	rm -f lib/lib$(target).a
endif
ifneq ($(filter dll,$(TARGETS)),)
ifeq ($(UNAME),windows32)
	rm -f dll/$(target).def
	rm -f dll/lib$(target).a
	rm -f dll/$(target).dll
endif
endif
endif

ifneq ($(filter debug,$(CONFIGURATIONS)),)
clean_debug :
	rm -f $(objectsd)
ifeq ($(MODE),FORTRAN)
	rm -f mod/*
endif
ifneq ($(filter exe,$(TARGETS)),)
	rm -f bin/$(target)d$(exe_suffix)
endif
ifneq ($(filter lib,$(TARGETS)),)
	rm -f lib/lib$(target)d.a
endif
ifneq ($(filter dll,$(TARGETS)),)
ifeq ($(UNAME),windows32)
	rm -f dll/$(target)d.def
	rm -f dll/lib$(target)d.a
	rm -f dll/$(target)d.dll
endif
endif
endif

rebuild : clean all
