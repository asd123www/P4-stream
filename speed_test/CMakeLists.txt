project (speed_test)
cmake_minimum_required(VERSION 3.10)
set(CMAKE_CXX_STANDARD 11)

set(USE_DPDK "YES" CACHE BOOL "Use dpdk.")
set(USE_DEBUG "NO" CACHE BOOL "Use debug mode.")

if(${USE_DPDK})
find_package(PkgConfig REQUIRED)
pkg_search_module(DPDK REQUIRED libdpdk)
endif()

include_directories(include)

set(THREADS_PREFER_PTHREAD_FLAG ON)
find_package(Threads REQUIRED)

add_compile_options(-fgnu89-inline -mssse3 -Wall -fcommon -march=native)
if(${USE_DEBUG})
    add_compile_options(-g)
else()
    add_compile_options(-Ofast)
endif()

# set(LIB_NUMA_IMGPROC_DIR /lib/x86_64-linux-gnu/)
# add_library(libnuma SHARED IMPORTED)

function(add_dpdk_link_include target_name)
    if(${USE_DPDK})
        target_link_libraries(${target_name} PUBLIC ${DPDK_LIBRARIES})
        target_include_directories(${target_name} PUBLIC ${DPDK_INCLUDE_DIRS})
        target_compile_options(${target_name} PUBLIC -DUSE_DPDK)
    endif()
endfunction()

# generate the .so file
ADD_LIBRARY(sender SHARED src/senderUDP.c)
ADD_LIBRARY(receiver SHARED src/receiverUDP.c)

add_executable(udp src/udp.c)
add_executable(tcp src/tcp.c)
add_dpdk_link_include(udp)
add_dpdk_link_include(tcp)
add_dpdk_link_include(sender)
add_dpdk_link_include(receiver)
# target_link_libraries(udp PUBLIC libnuma)
target_link_libraries(udp PUBLIC pthread)
target_link_libraries(tcp PUBLIC pthread)
target_link_libraries(sender PUBLIC pthread)
target_link_libraries(receiver PUBLIC pthread)

# sudo cmake -S . -B /build