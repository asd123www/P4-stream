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
include CMakeFiles/libUDP.dir/depend.make
# Include any dependencies generated by the compiler for this target.
include CMakeFiles/libUDP.dir/compiler_depend.make

# Include the progress variables for this target.
include CMakeFiles/libUDP.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/libUDP.dir/flags.make

CMakeFiles/libUDP.dir/src/senderUDP.c.o: CMakeFiles/libUDP.dir/flags.make
CMakeFiles/libUDP.dir/src/senderUDP.c.o: ../src/senderUDP.c
CMakeFiles/libUDP.dir/src/senderUDP.c.o: CMakeFiles/libUDP.dir/compiler_depend.ts
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/bfsde/wzz-p4-stream/p4-stream/speed_test/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building C object CMakeFiles/libUDP.dir/src/senderUDP.c.o"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -MD -MT CMakeFiles/libUDP.dir/src/senderUDP.c.o -MF CMakeFiles/libUDP.dir/src/senderUDP.c.o.d -o CMakeFiles/libUDP.dir/src/senderUDP.c.o -c /home/bfsde/wzz-p4-stream/p4-stream/speed_test/src/senderUDP.c

CMakeFiles/libUDP.dir/src/senderUDP.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/libUDP.dir/src/senderUDP.c.i"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/bfsde/wzz-p4-stream/p4-stream/speed_test/src/senderUDP.c > CMakeFiles/libUDP.dir/src/senderUDP.c.i

CMakeFiles/libUDP.dir/src/senderUDP.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/libUDP.dir/src/senderUDP.c.s"
	/usr/bin/cc $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/bfsde/wzz-p4-stream/p4-stream/speed_test/src/senderUDP.c -o CMakeFiles/libUDP.dir/src/senderUDP.c.s

# Object files for target libUDP
libUDP_OBJECTS = \
"CMakeFiles/libUDP.dir/src/senderUDP.c.o"

# External object files for target libUDP
libUDP_EXTERNAL_OBJECTS =

liblibUDP.so: CMakeFiles/libUDP.dir/src/senderUDP.c.o
liblibUDP.so: CMakeFiles/libUDP.dir/build.make
liblibUDP.so: CMakeFiles/libUDP.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/bfsde/wzz-p4-stream/p4-stream/speed_test/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking C shared library liblibUDP.so"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/libUDP.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/libUDP.dir/build: liblibUDP.so
.PHONY : CMakeFiles/libUDP.dir/build

CMakeFiles/libUDP.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/libUDP.dir/cmake_clean.cmake
.PHONY : CMakeFiles/libUDP.dir/clean

CMakeFiles/libUDP.dir/depend:
	cd /home/bfsde/wzz-p4-stream/p4-stream/speed_test/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/bfsde/wzz-p4-stream/p4-stream/speed_test /home/bfsde/wzz-p4-stream/p4-stream/speed_test /home/bfsde/wzz-p4-stream/p4-stream/speed_test/build /home/bfsde/wzz-p4-stream/p4-stream/speed_test/build /home/bfsde/wzz-p4-stream/p4-stream/speed_test/build/CMakeFiles/libUDP.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/libUDP.dir/depend
