# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.21

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:

#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:

# Disable VCS-based implicit rules.
% : %,v

# Disable VCS-based implicit rules.
% : RCS/%

# Disable VCS-based implicit rules.
% : RCS/%,v

# Disable VCS-based implicit rules.
% : SCCS/s.%

# Disable VCS-based implicit rules.
% : s.%

.SUFFIXES: .hpux_make_needs_suffix_list

# Command-line flag to silence nested $(MAKE).
$(VERBOSE)MAKESILENT = -s

#Suppress display of executed commands.
$(VERBOSE).SILENT:

# A target that is always out of date.
cmake_force:
.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/local/bin/cmake

# The command to remove a file.
RM = /usr/local/bin/cmake -E rm -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/bfsde/wzz-p4-stream/p4-stream/speed_test

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/bfsde/wzz-p4-stream/p4-stream/speed_test/build

# Include any dependencies generated for this target.
include CMakeFiles/udp.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include CMakeFiles/udp.dir/compiler_depend.make

# Include the progress variables for this target.
include CMakeFiles/udp.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/udp.dir/flags.make

CMakeFiles/udp.dir/src/udp.c.o: CMakeFiles/udp.dir/flags.make
CMakeFiles/udp.dir/src/udp.c.o: ../src/udp.c
CMakeFiles/udp.dir/src/udp.c.o: CMakeFiles/udp.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/bfsde/wzz-p4-stream/p4-stream/speed_test/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building C object CMakeFiles/udp.dir/src/udp.c.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -MD -MT CMakeFiles/udp.dir/src/udp.c.o -MF CMakeFiles/udp.dir/src/udp.c.o.d -o CMakeFiles/udp.dir/src/udp.c.o -c /home/bfsde/wzz-p4-stream/p4-stream/speed_test/src/udp.c

CMakeFiles/udp.dir/src/udp.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/udp.dir/src/udp.c.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/bfsde/wzz-p4-stream/p4-stream/speed_test/src/udp.c > CMakeFiles/udp.dir/src/udp.c.i

CMakeFiles/udp.dir/src/udp.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/udp.dir/src/udp.c.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/bfsde/wzz-p4-stream/p4-stream/speed_test/src/udp.c -o CMakeFiles/udp.dir/src/udp.c.s

# Object files for target udp
udp_OBJECTS = \
"CMakeFiles/udp.dir/src/udp.c.o"

# External object files for target udp
udp_EXTERNAL_OBJECTS =

udp: CMakeFiles/udp.dir/src/udp.c.o
udp: CMakeFiles/udp.dir/build.make
udp: CMakeFiles/udp.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/bfsde/wzz-p4-stream/p4-stream/speed_test/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking C executable udp"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/udp.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/udp.dir/build: udp
.PHONY : CMakeFiles/udp.dir/build

CMakeFiles/udp.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/udp.dir/cmake_clean.cmake
.PHONY : CMakeFiles/udp.dir/clean

CMakeFiles/udp.dir/depend:
	cd /home/bfsde/wzz-p4-stream/p4-stream/speed_test/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/bfsde/wzz-p4-stream/p4-stream/speed_test /home/bfsde/wzz-p4-stream/p4-stream/speed_test /home/bfsde/wzz-p4-stream/p4-stream/speed_test/build /home/bfsde/wzz-p4-stream/p4-stream/speed_test/build /home/bfsde/wzz-p4-stream/p4-stream/speed_test/build/CMakeFiles/udp.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/udp.dir/depend
