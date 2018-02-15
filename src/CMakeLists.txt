cmake_minimum_required(VERSION 3.0)
set(CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})

#file (READ "${CMAKE_SOURCE_DIR}/../configure" stream)
#string(REGEX REPLACE ".*PACKAGE_VERSION='([0-9]+)\\.([0-9]+)\\.([0-9]+).*" 
#                     "\\1.\\2.\\3" PROJECT_VERSION ${stream})
                     
set(PACKAGE_NAME "breakpad")
set(PACKAGE_TARNAME "breakpad")
set(PACKAGE_VERSION 0.1)
set(PACKAGE_STRING "breakpad 0.1")
set(PACKAGE_BUGREPORT "google-breakpad-dev@googlegroups.com")
set(PACKAGE_URL "")

IF(POLICY CMP0048)
    CMAKE_POLICY(SET CMP0048 NEW)
ENDIF()

#SET(CMAKE_DEBUG_POSTFIX "d" CACHE STRING "Name suffix for debug builds")
#MARK_AS_ADVANCED(CMAKE_IMPORT_LIBRARY_SUFFIX CMAKE_DEBUG_POSTFIX)

project(breakpad VERSION ${PACKAGE_VERSION} LANGUAGES C CXX)
string(REGEX MATCH "Clang"  IS_CLANG "${CMAKE_CXX_COMPILER_ID}")
string(REGEX MATCH "GNU"    IS_GNUXX "${CMAKE_CXX_COMPILER_ID}")

# breakpad compile options, modules, ...
option(BUILD_SHARED_LIBS          "build breakpad/breakpad_client as a unix shared (so/dylib) library" ON)
option(BUILD_ENABLE_M32           "Compile/build with -m32 (default is no)" OFF)
option(BUILD_DISABLE_PROCESSOR    "Don't build processor library (default is no)" OFF)
option(BUILD_DISABLE_TOOLS        "Don't build tool binaries, (default is no)" OFF)
option(BUILD_ENABLE_SYS_TEST_LIBS "Use gtest/gmock/etc... from the system instead of the local copies (default is local)" OFF)
option(BUILD_ENABLE_SELF_TEST     "Run extra tests with 'make check' (may conflict with optimizations) (default is no)" OFF)
set(BUILD_WITH_RUST_DEMANGLE "" CACHE STRING "/path/to/rust-demangle-capi, Link against the rust-demangle library to demangle \
                                              Rust language symbols during symbol dumping (default is no) Pass the path to \
                                              the crate root.")

# validate build options
if(LINUX AND BUILD_DISABLE_PROCESSOR AND BUILD_DISABLE_TOOLS)
    message(FATAL_ERROR "BUILD_DISABLE_PROCESSOR and BUILD_DISABLE_TOOLS were set, and not building for Linux. Nothing to build!")
endif()


# compiler settings
if(IS_CLANG OR IS_GNUXX)

    add_definitions(-fPIC -Werror)
    
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} \
        -Wmissing-braces -Wnon-virtual-dtor -Woverloaded-virtual -Wreorder \
        -Wsign-compare -Wunused-local-typedefs -Wunused-variable -Wvla \
        -std=c++11"
    )
    
endif()

if(BUILD_ENABLE_M32)
    add_definitions(-m32)
endif()

#create config file here...
add_definitions(-DHAVE_CONFIG_H)

if(UNIX)
    if(ANDROID)
        set(DEP_LIBS dl log)
        add_definitions(-D__STDC_LIMIT_MACROS)
    elseif(APPLE)
        message("@warning: rpath is skipped by default under OS X")
        set(CMAKE_SKIP_RPATH TRUE)
#        add_definitions(-DHAVE_MACH_O_NLIST_H)
        include_directories(src/third_party/mac_headers)
    else()
#        add_definitions(-DHAVE_A_OUT_H)
        set(DEP_LIBS pthread dl)
    endif()
endif()


include_directories(src)

set(src_client_linux_libbreakpad_client_a_SOURCES
    src/client/linux/crash_generation/crash_generation_client.cc
    src/client/linux/crash_generation/crash_generation_server.cc
    src/client/linux/dump_writer_common/thread_info.cc
    src/client/linux/dump_writer_common/ucontext_reader.cc
    src/client/linux/handler/exception_handler.cc
    src/client/linux/handler/exception_handler.h
    src/client/linux/handler/minidump_descriptor.cc
    src/client/linux/handler/minidump_descriptor.h
    src/client/linux/log/log.cc
    src/client/linux/log/log.h
    src/client/linux/microdump_writer/microdump_writer.cc
    src/client/linux/microdump_writer/microdump_writer.h
    src/client/linux/minidump_writer/linux_core_dumper.cc
    src/client/linux/minidump_writer/linux_dumper.cc
    src/client/linux/minidump_writer/linux_ptrace_dumper.cc
    src/client/linux/minidump_writer/minidump_writer.cc
    src/client/minidump_file_writer-inl.h
    src/client/minidump_file_writer.cc
    src/client/minidump_file_writer.h
    src/common/convert_UTF.c
    src/common/convert_UTF.h
    src/common/md5.cc
    src/common/md5.h
    src/common/string_conversion.cc
    src/common/string_conversion.h
    src/common/linux/elf_core_dump.cc
    src/common/linux/elfutils.cc
    src/common/linux/elfutils.h
    src/common/linux/file_id.cc
    src/common/linux/file_id.h
    src/common/linux/guid_creator.cc
    src/common/linux/guid_creator.h
    src/common/linux/linux_libc_support.cc
    src/common/linux/memory_mapped_file.cc
    src/common/linux/safe_readlink.cc
)

if(LINUX AND ANDROID)
        list(APPEND src_client_linux_libbreakpad_client_a_SOURCES 
            src/common/android/breakpad_getcontext.S
        )
endif()

if(NOT BUILD_DISABLE_PROCESSOR)
set(src_libbreakpad_a_SOURCES
	src/google_breakpad/common/breakpad_types.h
	src/google_breakpad/common/minidump_format.h
	src/google_breakpad/common/minidump_size.h
	src/google_breakpad/processor/basic_source_line_resolver.h
	src/google_breakpad/processor/call_stack.h
	src/google_breakpad/processor/code_module.h
	src/google_breakpad/processor/code_modules.h
	src/google_breakpad/processor/dump_context.h
	src/google_breakpad/processor/dump_object.h
	src/google_breakpad/processor/exploitability.h
	src/google_breakpad/processor/fast_source_line_resolver.h
	src/google_breakpad/processor/memory_region.h
	src/google_breakpad/processor/microdump.h
	src/google_breakpad/processor/microdump_processor.h
	src/google_breakpad/processor/minidump.h
	src/google_breakpad/processor/minidump_processor.h
	src/google_breakpad/processor/process_result.h
	src/google_breakpad/processor/process_state.h
	src/google_breakpad/processor/proc_maps_linux.h
	src/google_breakpad/processor/source_line_resolver_base.h
	src/google_breakpad/processor/source_line_resolver_interface.h
	src/google_breakpad/processor/stack_frame.h
	src/google_breakpad/processor/stack_frame_cpu.h
	src/google_breakpad/processor/stack_frame_symbolizer.h
	src/google_breakpad/processor/stackwalker.h
	src/google_breakpad/processor/symbol_supplier.h
	src/google_breakpad/processor/system_info.h
	src/processor/address_map-inl.h
	src/processor/address_map.h
	src/processor/basic_code_module.h
	src/processor/basic_code_modules.cc
	src/processor/basic_code_modules.h
	src/processor/basic_source_line_resolver_types.h
	src/processor/basic_source_line_resolver.cc
	src/processor/call_stack.cc
	src/processor/cfi_frame_info.cc
	src/processor/cfi_frame_info.h
	src/processor/contained_range_map-inl.h
	src/processor/contained_range_map.h
	src/processor/disassembler_x86.h
	src/processor/disassembler_x86.cc
	src/processor/dump_context.cc
	src/processor/dump_object.cc
	src/processor/exploitability.cc
	src/processor/exploitability_linux.h
	src/processor/exploitability_linux.cc
	src/processor/exploitability_win.h
	src/processor/exploitability_win.cc
	src/processor/fast_source_line_resolver_types.h
	src/processor/fast_source_line_resolver.cc
	src/processor/linked_ptr.h
	src/processor/logging.h
	src/processor/logging.cc
	src/processor/map_serializers-inl.h
	src/processor/map_serializers.h
	src/processor/microdump.cc
	src/processor/microdump_processor.cc
	src/processor/minidump.cc
	src/processor/minidump_processor.cc
	src/processor/module_comparer.cc
	src/processor/module_comparer.h
	src/processor/module_factory.h
	src/processor/module_serializer.cc
	src/processor/module_serializer.h
	src/processor/pathname_stripper.cc
	src/processor/pathname_stripper.h
	src/processor/postfix_evaluator-inl.h
	src/processor/postfix_evaluator.h
	src/processor/process_state.cc
	src/processor/proc_maps_linux.cc
	src/processor/range_map-inl.h
	src/processor/range_map.h
	src/processor/simple_serializer-inl.h
	src/processor/simple_serializer.h
	src/processor/simple_symbol_supplier.cc
	src/processor/simple_symbol_supplier.h
	src/processor/windows_frame_info.h
	src/processor/source_line_resolver_base_types.h
	src/processor/source_line_resolver_base.cc
	src/processor/stack_frame_cpu.cc
	src/processor/stack_frame_symbolizer.cc
	src/processor/stackwalker.cc
	src/processor/stackwalker_amd64.cc
	src/processor/stackwalker_amd64.h
	src/processor/stackwalker_arm.cc
	src/processor/stackwalker_arm.h
	src/processor/stackwalker_arm64.cc
	src/processor/stackwalker_arm64.h
	src/processor/stackwalker_address_list.cc
	src/processor/stackwalker_address_list.h
	src/processor/stackwalker_mips.cc
	src/processor/stackwalker_mips.h
	src/processor/stackwalker_ppc.cc
	src/processor/stackwalker_ppc.h
	src/processor/stackwalker_ppc64.cc
	src/processor/stackwalker_ppc64.h
	src/processor/stackwalker_sparc.cc
	src/processor/stackwalker_sparc.h
	src/processor/stackwalker_x86.cc
	src/processor/stackwalker_x86.h
	src/processor/static_address_map-inl.h
	src/processor/static_address_map.h
	src/processor/static_contained_range_map-inl.h
	src/processor/static_contained_range_map.h
	src/processor/static_map_iterator-inl.h
	src/processor/static_map_iterator.h
	src/processor/static_map-inl.h
	src/processor/static_map.h
	src/processor/static_range_map-inl.h
	src/processor/static_range_map.h
	src/processor/symbolic_constants_win.cc
	src/processor/symbolic_constants_win.h
	src/processor/tokenize.cc
	src/processor/tokenize.h
)
endif()

set(src_third_party_libdisasm_libdisasm_a_SOURCES
	src/third_party/libdisasm/ia32_implicit.c
	src/third_party/libdisasm/ia32_implicit.h
	src/third_party/libdisasm/ia32_insn.c
	src/third_party/libdisasm/ia32_insn.h
	src/third_party/libdisasm/ia32_invariant.c
	src/third_party/libdisasm/ia32_invariant.h
	src/third_party/libdisasm/ia32_modrm.c
	src/third_party/libdisasm/ia32_modrm.h
	src/third_party/libdisasm/ia32_opcode_tables.c
	src/third_party/libdisasm/ia32_opcode_tables.h
	src/third_party/libdisasm/ia32_operand.c
	src/third_party/libdisasm/ia32_operand.h
	src/third_party/libdisasm/ia32_reg.c
	src/third_party/libdisasm/ia32_reg.h
	src/third_party/libdisasm/ia32_settings.c
	src/third_party/libdisasm/ia32_settings.h
	src/third_party/libdisasm/libdis.h
	src/third_party/libdisasm/qword.h
	src/third_party/libdisasm/x86_disasm.c
	src/third_party/libdisasm/x86_format.c
	src/third_party/libdisasm/x86_imm.c
	src/third_party/libdisasm/x86_imm.h
	src/third_party/libdisasm/x86_insn.c
	src/third_party/libdisasm/x86_misc.c
	src/third_party/libdisasm/x86_operand_list.c
	src/third_party/libdisasm/x86_operand_list.h
)

add_library(disasm STATIC ${src_third_party_libdisasm_libdisasm_a_SOURCES})
install(TARGETS disasm
        DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)


# breakpad client as library
add_library(breakpad_client_static STATIC ${src_client_linux_libbreakpad_client_a_SOURCES} ${src_libbreakpad_a_SOURCES})
set_target_properties(breakpad_client_static PROPERTIES OUTPUT_NAME "breakpad_client")
install(TARGETS breakpad_client_static
        DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)


if(BUILD_SHARED_LIBS)
    add_library(breakpad_client SHARED ${src_client_linux_libbreakpad_client_a_SOURCES} ${src_libbreakpad_a_SOURCES})
    target_link_libraries(breakpad_client disasm)
    install(TARGETS breakpad_client
            DESTINATION ${CMAKE_INSTALL_PREFIX}/lib
            PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
    add_dependencies(breakpad_client disasm)
endif()


if(NOT BUILD_DISABLE_TOOLS)

    if(UNIX)
    
        if(ANDROID)
        
        elseif(APPLE)
        
            add_executable(dump_syms_mac
	            src/common/dwarf_cfi_to_module.cc
	            src/common/dwarf_cu_to_module.cc
	            src/common/dwarf_line_to_module.cc src/common/language.cc
	            src/common/md5.cc src/common/module.cc
	            src/common/path_helper.cc src/common/stabs_reader.cc
	            src/common/stabs_to_module.cc src/common/dwarf/bytereader.cc
	            src/common/dwarf/dwarf2diehandler.cc
	            src/common/dwarf/dwarf2reader.cc
	            src/common/dwarf/elf_reader.cc
	            src/common/mac/arch_utilities.cc src/common/mac/dump_syms.cc
	            src/common/mac/dump_syms.h src/common/mac/file_id.cc
	            src/common/mac/file_id.h src/common/mac/macho_id.cc
	            src/common/mac/macho_id.h src/common/mac/macho_reader.cc
	            src/common/mac/macho_reader.h
	            src/common/mac/macho_utilities.cc
	            src/common/mac/macho_utilities.h
	            src/common/mac/macho_walker.cc src/common/mac/macho_walker.h
	            src/tools/mac/dump_syms/dump_syms_tool.cc
	        )
            set_target_properties(dump_syms_mac PROPERTIES COMPILE_FLAGS -DHAVE_MACH_O_NLIST_H)
            target_include_directories(dump_syms_mac PRIVATE src/third_party/mac_headers)
            install(FILES ${CMAKE_BINARY_DIR}/dump_syms_mac
                    DESTINATION ${CMAKE_INSTALL_PREFIX}/bin
                    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
	    else ()
	    
            add_executable(core2md src/tools/linux/core2md/core2md.cc)
            target_link_libraries(core2md breakpad_client pthread)
            install(FILES ${CMAKE_BINARY_DIR}/core2md
                    DESTINATION ${CMAKE_INSTALL_PREFIX}/bin
                    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

            set(src_tools_linux_dump_syms_dump_syms_SOURCES
                src/common/dwarf_cfi_to_module.cc
                src/common/dwarf_cu_to_module.cc
                src/common/dwarf_line_to_module.cc src/common/language.cc
                src/common/module.cc src/common/path_helper.cc
                src/common/stabs_reader.cc src/common/stabs_to_module.cc
                src/common/dwarf/bytereader.cc
                src/common/dwarf/dwarf2diehandler.cc
                src/common/dwarf/dwarf2reader.cc
                src/common/dwarf/elf_reader.cc src/common/linux/crc32.cc
                src/common/linux/dump_symbols.cc
                src/common/linux/dump_symbols.h
                src/common/linux/elf_symbols_to_module.cc
                src/common/linux/elf_symbols_to_module.h
                src/common/linux/elfutils.cc src/common/linux/file_id.cc
                src/common/linux/linux_libc_support.cc
                src/common/linux/memory_mapped_file.cc
                src/common/linux/safe_readlink.cc
                src/tools/linux/dump_syms/dump_syms.cc
            )
            add_executable(dump_syms ${src_tools_linux_dump_syms_dump_syms_SOURCES})
            install(FILES ${CMAKE_BINARY_DIR}/dump_syms
                    DESTINATION ${CMAKE_INSTALL_PREFIX}/bin
                    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
            
            add_executable(minidump-2-core
	            src/common/linux/memory_mapped_file.cc
	            src/common/path_helper.cc
	            src/tools/linux/md2core/minidump-2-core.cc
	            src/tools/linux/md2core/minidump_memory_range.h
            )
            install(FILES ${CMAKE_BINARY_DIR}/minidump-2-core
                    DESTINATION ${CMAKE_INSTALL_PREFIX}/bin
                    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
            
            add_executable(minidump_upload
            	src/common/linux/http_upload.cc
                src/tools/linux/symupload/minidump_upload.cc
            )
            target_link_libraries(minidump_upload ${DEP_LIBS})
            install(FILES ${CMAKE_BINARY_DIR}/minidump_upload
                    DESTINATION ${CMAKE_INSTALL_PREFIX}/bin
                    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
            
            add_executable(sym_upload
	            src/common/linux/http_upload.cc
	            src/common/linux/http_upload.h
	            src/common/linux/symbol_upload.cc
	            src/common/linux/symbol_upload.h
	            src/tools/linux/symupload/sym_upload.cc
            )
            target_link_libraries(sym_upload ${DEP_LIBS})
            install(FILES ${CMAKE_BINARY_DIR}/sym_upload
                    DESTINATION ${CMAKE_INSTALL_PREFIX}/bin
                    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
            
            if(NOT BUILD_DISABLE_PROCESSOR)
                set(src_processor_microdump_stackwalk_SOURCES
	                src/processor/microdump_stackwalk.cc
	                src/common/path_helper.cc
	                src/processor/basic_code_modules.cc
	                src/processor/basic_source_line_resolver.cc
	                src/processor/call_stack.cc
	                src/processor/cfi_frame_info.cc
	                src/processor/disassembler_x86.cc
	                src/processor/dump_context.cc
	                src/processor/dump_object.cc
	                src/processor/logging.cc
	                src/processor/microdump.cc
	                src/processor/microdump_processor.cc
	                src/processor/pathname_stripper.cc
	                src/processor/process_state.cc
	                src/processor/simple_symbol_supplier.cc
	                src/processor/source_line_resolver_base.cc
	                src/processor/stack_frame_cpu.cc
	                src/processor/stack_frame_symbolizer.cc
	                src/processor/stackwalk_common.cc
	                src/processor/stackwalker.cc
	                src/processor/stackwalker_address_list.cc
	                src/processor/stackwalker_amd64.cc
	                src/processor/stackwalker_arm.cc
	                src/processor/stackwalker_arm64.cc
	                src/processor/stackwalker_mips.cc
	                src/processor/stackwalker_ppc.cc
	                src/processor/stackwalker_ppc64.cc
	                src/processor/stackwalker_sparc.cc
	                src/processor/stackwalker_x86.cc
	                src/processor/tokenize.cc
                )
                add_executable(microdump_stackwalk ${src_processor_microdump_stackwalk_SOURCES})
                target_link_libraries(microdump_stackwalk disasm ${DEP_LIBS})
                install(FILES ${CMAKE_BINARY_DIR}/microdump_stackwalk
                        DESTINATION ${CMAKE_INSTALL_PREFIX}/bin
                        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
                        
                set(src_processor_minidump_dump_SOURCES
                    src/processor/minidump_dump.cc
	                src/processor/basic_code_modules.cc
	                src/processor/dump_context.cc
	                src/processor/dump_object.cc
	                src/processor/logging.cc
	                src/processor/minidump.cc
	                src/processor/pathname_stripper.cc
	                src/processor/proc_maps_linux.cc
                )
                add_executable(minidump_dump ${src_processor_minidump_dump_SOURCES})
                target_link_libraries(minidump_dump ${DEP_LIBS})
                install(FILES ${CMAKE_BINARY_DIR}/minidump_dump
                        DESTINATION ${CMAKE_INSTALL_PREFIX}/bin
                        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)                        


                set(src_processor_minidump_stackwalk_SOURCES
                    src/processor/minidump_stackwalk.cc
                    src/common/path_helper.cc
                    src/processor/basic_code_modules.cc
                    src/processor/basic_source_line_resolver.cc
                    src/processor/call_stack.cc
                    src/processor/cfi_frame_info.cc
                    src/processor/disassembler_x86.cc
                    src/processor/dump_context.cc
                    src/processor/dump_object.cc
                    src/processor/exploitability.cc
                    src/processor/exploitability_linux.cc
                    src/processor/exploitability_win.cc
                    src/processor/logging.cc
                    src/processor/minidump.cc
                    src/processor/minidump_processor.cc
                    src/processor/pathname_stripper.cc
                    src/processor/process_state.cc
                    src/processor/proc_maps_linux.cc
                    src/processor/simple_symbol_supplier.cc
                    src/processor/source_line_resolver_base.cc
                    src/processor/stack_frame_cpu.cc
                    src/processor/stack_frame_symbolizer.cc
                    src/processor/stackwalk_common.cc
                    src/processor/stackwalker.cc
                    src/processor/stackwalker_address_list.cc
                    src/processor/stackwalker_amd64.cc
                    src/processor/stackwalker_arm.cc
                    src/processor/stackwalker_arm64.cc
                    src/processor/stackwalker_mips.cc
                    src/processor/stackwalker_ppc.cc
                    src/processor/stackwalker_ppc64.cc
                    src/processor/stackwalker_sparc.cc
                    src/processor/stackwalker_x86.cc
                    src/processor/symbolic_constants_win.cc
                    src/processor/tokenize.cc
                )
                add_executable(minidump_stackwalk ${src_processor_minidump_stackwalk_SOURCES})
                target_link_libraries(minidump_stackwalk disasm ${DEP_LIBS})
                install(FILES ${CMAKE_BINARY_DIR}/minidump_stackwalk
                        DESTINATION ${CMAKE_INSTALL_PREFIX}/bin
                        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)                        
                        
            endif()
            
        endif()
    endif()        
endif()

#install(FILES sqlite3.h sqlite3ext.h DESTINATION ${CMAKE_INSTALL_PREFIX}/include)

# Package Config
set(prefix ${CMAKE_INSTALL_PREFIX})
set(exec_prefix \${prefix})
set(libdir \${exec_prefix}/lib)
set(includedir \${prefix}/include)
set(LIBS "")
configure_file(breakpad-client.pc.in ${CMAKE_BINARY_DIR}/breakpad-client.pc @ONLY)
install(FILES ${CMAKE_BINARY_DIR}/breakpad-client.pc
        DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/pkgconfig
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
        
if(NOT BUILD_DISABLE_TOOLS AND NOT BUILD_DISABLE_PROCESSOR)
configure_file(breakpad.pc.in ${CMAKE_BINARY_DIR}/breakpad.pc @ONLY)
install(FILES ${CMAKE_BINARY_DIR}/breakpad.pc
        DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/pkgconfig
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
endif()        


if(BUILD_ENABLE_SELF_TEST)

message(STATUS "CMAKE_C_LIBRARY_ARCHITECTURE=${CMAKE_C_LIBRARY_ARCHITECTURE}")
message(STATUS "CMAKE_CXX_LIBRARY_ARCHITECTURE=${CMAKE_CXX_LIBRARY_ARCHITECTURE}")

if(BUILD_ENABLE_SYS_TEST_LIBS)
    set(TEST_LIBS "-lgtest -lgtest_main -lgmock")
    set(TEST_DEPS "")
else()

    include_directories(
        src/testing/include
        src/testing/googletest/include
        src/testing/googletest
        src/testing/googlemock/include
        src/testing/googlemock
        src/testing
    )
    
    include(ExternalProject)
    ExternalProject_Add(gtest
        SOURCE_DIR ${CMAKE_SOURCE_DIR}/src/testing
        DOWNLOAD_COMMAND ""
        BUILD_IN_SOURCE 0
        CMAKE_ARGS
          -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE}
          -DCMAKE_INSTALL_PREFIX:PATH=${CMAKE_INSTALL_PREFIX}
        INSTALL_COMMAND ""
    )

    set(TEST_LIBS
        ${CMAKE_BINARY_DIR}/gtest-prefix/src/gtest-build/googlemock/libgmock.a
        ${CMAKE_BINARY_DIR}/gtest-prefix/src/gtest-build/googlemock/gtest/libgtest.a
        ${CMAKE_BINARY_DIR}/gtest-prefix/src/gtest-build/googlemock/gtest/libgtest_main.a
    )
    set(TEST_DEPS gtest)
    
endif()

set(src_client_linux_linux_client_unittest_SOURCES
    src/client/linux/handler/exception_handler_unittest.cc
    src/client/linux/minidump_writer/directory_reader_unittest.cc
    src/client/linux/minidump_writer/cpu_set_unittest.cc
    src/client/linux/minidump_writer/line_reader_unittest.cc
    src/client/linux/minidump_writer/linux_core_dumper.cc
    src/client/linux/minidump_writer/linux_core_dumper_unittest.cc
    src/client/linux/minidump_writer/linux_ptrace_dumper_unittest.cc
    src/client/linux/minidump_writer/minidump_writer_unittest.cc
    src/client/linux/minidump_writer/minidump_writer_unittest_utils.cc
    src/client/linux/minidump_writer/proc_cpuinfo_reader_unittest.cc
    src/common/linux/elf_core_dump.cc
    src/common/linux/linux_libc_support_unittest.cc
    src/common/linux/tests/auto_testfile.h
    src/common/linux/tests/crash_generator.cc
    src/common/memory_allocator_unittest.cc
    src/common/tests/auto_tempdir.h src/common/tests/file_utils.cc
    src/common/tests/file_utils.h
    src/processor/basic_code_modules.cc
    src/processor/dump_context.cc src/processor/dump_object.cc
    src/processor/logging.cc src/processor/minidump.cc
    src/processor/pathname_stripper.cc
    src/processor/proc_maps_linux.cc
    src/client/linux/microdump_writer/microdump_writer_unittest.cc
)
if(ANDROID)
    list(APPEND src_client_linux_linux_client_unittest_SOURCES 
        src/common/android/breakpad_getcontext_unittest.cc
        src/common/android/breakpad_getcontext.S
    )
endif()
set(src_common_dumper_unittest_SOURCES
	src/common/byte_cursor_unittest.cc
	src/common/dwarf_cfi_to_module.cc
	src/common/dwarf_cfi_to_module_unittest.cc
	src/common/dwarf_cu_to_module.cc
	src/common/dwarf_cu_to_module_unittest.cc
	src/common/dwarf_line_to_module.cc
	src/common/dwarf_line_to_module_unittest.cc
	src/common/language.cc src/common/memory_range_unittest.cc
	src/common/module.cc src/common/module_unittest.cc
	src/common/path_helper.cc src/common/stabs_reader.cc
	src/common/stabs_reader_unittest.cc
	src/common/stabs_to_module.cc
	src/common/stabs_to_module_unittest.cc
	src/common/test_assembler.cc src/common/dwarf/bytereader.cc
	src/common/dwarf/bytereader.h
	src/common/dwarf/bytereader-inl.h
	src/common/dwarf/bytereader_unittest.cc
	src/common/dwarf/cfi_assembler.cc
	src/common/dwarf/cfi_assembler.h
	src/common/dwarf/dwarf2diehandler.cc
	src/common/dwarf/dwarf2diehandler_unittest.cc
	src/common/dwarf/dwarf2reader.cc
	src/common/dwarf/dwarf2reader.h src/common/dwarf/elf_reader.cc
	src/common/dwarf/elf_reader.h
	src/common/dwarf/dwarf2reader_cfi_unittest.cc
	src/common/dwarf/dwarf2reader_die_unittest.cc
	src/common/dwarf/dwarf2reader_test_common.h
	src/common/linux/crc32.cc src/common/linux/dump_symbols.cc
	src/common/linux/dump_symbols_unittest.cc
	src/common/linux/elf_core_dump.cc
	src/common/linux/elf_core_dump_unittest.cc
	src/common/linux/elf_symbols_to_module.cc
	src/common/linux/elf_symbols_to_module_unittest.cc
	src/common/linux/elfutils.cc src/common/linux/file_id.cc
	src/common/linux/file_id_unittest.cc
	src/common/linux/linux_libc_support.cc
	src/common/linux/memory_mapped_file.cc
	src/common/linux/memory_mapped_file_unittest.cc
	src/common/linux/safe_readlink.cc
	src/common/linux/safe_readlink_unittest.cc
	src/common/linux/synth_elf.cc
	src/common/linux/synth_elf_unittest.cc
	src/common/linux/tests/crash_generator.cc
	src/common/linux/tests/crash_generator.h
	src/common/testdata/func-line-pairing.h
	src/common/tests/file_utils.cc
)
set(src_common_linux_google_crashdump_uploader_test_SOURCES
	src/common/linux/google_crashdump_uploader_test.cc
	src/common/linux/google_crashdump_uploader.cc
	src/common/linux/libcurl_wrapper.cc
)
set(src_common_test_assembler_unittest_SOURCES
	src/common/test_assembler_unittest.cc
	src/common/test_assembler.cc
)
set(src_tools_linux_md2core_minidump_2_core_unittest_SOURCES
	src/tools/linux/md2core/minidump_memory_range_unittest.cc
)
set(src_common_mac_macho_reader_unittest_SOURCES
    src/common/mac/macho_reader_unittest.cc
    src/common/mac/macho_id.cc src/common/mac/macho_reader.cc
    src/common/mac/macho_utilities.cc
    src/common/mac/macho_walker.cc src/common/tests/file_utils.cc
    src/common/dwarf_cfi_to_module.cc
    src/common/dwarf_cu_to_module.cc
    src/common/dwarf_line_to_module.cc src/common/language.cc
    src/common/md5.cc src/common/module.cc
    src/common/path_helper.cc src/common/stabs_reader.cc
    src/common/stabs_to_module.cc src/common/test_assembler.cc
    src/common/dwarf/bytereader.cc
    src/common/dwarf/cfi_assembler.cc
    src/common/dwarf/dwarf2diehandler.cc
    src/common/dwarf/dwarf2reader.cc
    src/common/dwarf/elf_reader.cc
    src/common/mac/arch_utilities.cc src/common/mac/file_id.cc
)
set(src_processor_address_map_unittest_SOURCES
    src/processor/logging.cc
    src/processor/pathname_stripper.cc
    src/processor/address_map_unittest.cc
)
set(src_processor_basic_source_line_resolver_unittest_SOURCES
    src/processor/basic_source_line_resolver_unittest.cc
    src/processor/basic_source_line_resolver.cc
    src/processor/cfi_frame_info.cc
    src/processor/pathname_stripper.cc
    src/processor/logging.cc
    src/processor/source_line_resolver_base.cc
    src/processor/tokenize.cc
)
set(src_processor_cfi_frame_info_unittest_SOURCES
    src/processor/cfi_frame_info_unittest.cc    
    src/processor/cfi_frame_info.cc
    src/processor/pathname_stripper.cc
    src/processor/logging.cc
)
set(src_processor_disassembler_x86_unittest_SOURCES
    src/processor/disassembler_x86_unittest.cc
)	
set(src_processor_map_serializers_unittest_SOURCES
    src/processor/map_serializers_unittest.cc
    src/processor/pathname_stripper.cc
    src/processor/logging.cc
)
set(src_processor_microdump_processor_unittest_SOURCES
    src/processor/microdump_processor_unittest.cc
    src/processor/basic_code_modules.cc
    src/processor/basic_source_line_resolver.cc
    src/processor/call_stack.cc
    src/processor/cfi_frame_info.cc
    src/processor/dump_context.cc
    src/processor/dump_object.cc
    src/processor/logging.cc
    src/processor/microdump.cc
    src/processor/microdump_processor.cc
    src/processor/pathname_stripper.cc
    src/processor/process_state.cc
    src/processor/simple_symbol_supplier.cc
    src/processor/source_line_resolver_base.cc
    src/processor/stack_frame_symbolizer.cc
    src/processor/stackwalker.cc
    src/processor/stackwalker_address_list.cc
    src/processor/stackwalker_amd64.cc
    src/processor/stackwalker_arm.cc
    src/processor/stackwalker_arm64.cc
    src/processor/stackwalker_mips.cc
    src/processor/stackwalker_ppc.cc
    src/processor/stackwalker_ppc64.cc
    src/processor/stackwalker_sparc.cc
    src/processor/stackwalker_x86.cc
    src/processor/tokenize.cc
)
set(src_processor_minidump_unittest_SOURCES
    src/processor/minidump_unittest.cc
    src/common/test_assembler.cc
    src/processor/synth_minidump.cc
    src/processor/basic_code_modules.cc
    src/processor/dump_context.cc
    src/processor/dump_object.cc
    src/processor/logging.cc
    src/processor/minidump.cc
    src/processor/pathname_stripper.cc
    src/processor/proc_maps_linux.cc
)
set(src_processor_pathname_stripper_unittest_SOURCES
    src/processor/pathname_stripper_unittest.cc
    src/processor/pathname_stripper.cc
)
set(src_processor_postfix_evaluator_unittest_SOURCES
    src/processor/postfix_evaluator_unittest.cc
    src/processor/logging.cc
    src/processor/pathname_stripper.cc
)
set(src_processor_range_map_shrink_down_unittest_SOURCES
    src/processor/range_map_shrink_down_unittest.cc
    src/processor/logging.cc
    src/processor/pathname_stripper.cc
)	
set(src_processor_range_map_unittest_SOURCES
    src_processor_range_map_unittest.cc
    src/processor/logging.cc
    src/processor/pathname_stripper.cc
)
set(src_processor_synth_minidump_unittest_SOURCES
    src/processor/synth_minidump_unittest.cc
    src/common/test_assembler.cc src/common/test_assembler.h
    src/processor/synth_minidump.cc src/processor/synth_minidump.h
)
set(src_processor_exploitability_unittest_SOURCES
    src/processor/exploitability_unittest.cc
)
set(src_processor_fast_source_line_resolver_unittest_SOURCES
    src/processor/fast_source_line_resolver_unittest.cc
    src/processor/basic_source_line_resolver.cc
    src/processor/cfi_frame_info.cc
    src/processor/module_comparer.cc
    src/processor/module_serializer.cc    
    src/processor/pathname_stripper.cc
    src/processor/logging.cc
    src/processor/source_line_resolver_base.cc
    src/processor/tokenize.cc    
)
set(src_processor_minidump_processor_unittest_SOURCES
    src/processor/minidump_processor_unittest.cc
 	src/processor/basic_code_modules.cc
    src/processor/basic_source_line_resolver.cc
    src/processor/call_stack.cc
    src/processor/cfi_frame_info.cc
    src/processor/disassembler_x86.cc
    src/processor/dump_context.cc
    src/processor/dump_object.cc
    src/processor/exploitability.cc
    src/processor/exploitability_linux.cc
    src/processor/exploitability_win.cc
    src/processor/logging.cc
    src/processor/minidump_processor.cc
    src/processor/minidump.cc
    src/processor/pathname_stripper.cc
    src/processor/process_state.cc
    src/processor/proc_maps_linux.cc
    src/processor/source_line_resolver_base.cc
    src/processor/stack_frame_cpu.cc
    src/processor/stack_frame_symbolizer.cc
    src/processor/stackwalker.cc
    src/processor/stackwalker_address_list.cc
    src/processor/stackwalker_amd64.cc
    src/processor/stackwalker_arm.cc
    src/processor/stackwalker_arm64.cc
    src/processor/stackwalker_mips.cc
    src/processor/stackwalker_ppc.cc
    src/processor/stackwalker_ppc64.cc
    src/processor/stackwalker_sparc.cc
    src/processor/stackwalker_x86.cc
    src/processor/symbolic_constants_win.cc
    src/processor/tokenize.cc
)
set(src_processor_proc_maps_linux_unittest_SOURCES
    src/processor/proc_maps_linux_unittest.cc
    src/processor/proc_maps_linux.cc
    src/processor/logging.cc
    src/processor/pathname_stripper.cc
)
set(src_processor_stackwalker_address_list_unittest_SOURCES
    src/processor/stackwalker_address_list_unittest.cc
    src/common/test_assembler.cc
)	
set(src_processor_stackwalker_amd64_unittest_SOURCES
    src/processor/stackwalker_amd64_unittest.cc
    src/common/test_assembler.cc
)
set(src_processor_stackwalker_arm64_unittest_SOURCES
    src/processor/stackwalker_arm64_unittest.cc
    src/common/test_assembler.cc
)	
set(src_processor_stackwalker_arm_unittest_SOURCES
    src/processor/stackwalker_arm_unittest.cc
    src/common/test_assembler.cc
)	
set(src_processor_stackwalker_mips64_unittest_SOURCES
    src/processor/stackwalker_mips64_unittest.cc
    src/common/test_assembler.cc
)
set(src_processor_stackwalker_mips_unittest_SOURCES
    src/processor/stackwalker_mips_unittest.cc
    src/common/test_assembler.cc
)	
set(src_processor_stackwalker_x86_unittest_SOURCES
    src/processor/stackwalker_x86_unittest.cc
    src/common/test_assembler.cc
)
set(src_processor_static_address_map_unittest_SOURCES
    src/processor/static_address_map_unittest.cc
)
set(src_processor_static_contained_range_map_unittest_SOURCES
    src/processor/static_contained_range_map_unittest.cc
)
set(src_processor_static_map_unittest_SOURCES
    src/processor/static_map_unittest.cc
)
set(src_processor_static_range_map_unittest_SOURCES
    src/processor/static_range_map_unittest.cc
)
set(src_processor_contained_range_map_unittest_SOURCES
    src/processor/contained_range_map_unittest.cc
)
set(src_processor_range_map_unittest_SOURCES
    src/processor/range_map_unittest.cc
)

function(UnitTest subdir name libs)

  set(varLabel          src/${subdir}/${name})
  string(REGEX REPLACE "/" "_" subdir ${subdir})
  set(varName               ${subdir}_${name})
  set(varSrc          ${src_${subdir}_${name}_SOURCES})

  add_executable(${varName} EXCLUDE_FROM_ALL ${varSrc})
  target_link_libraries(${varName} ${libs} ${TEST_LIBS} ${DEP_LIBS})
  add_dependencies(${varName} ${TEST_DEPS})
  add_test(${varLabel} ${varName})
  list(APPEND check_deps ${varName})
  set(check_deps ${check_deps} PARENT_SCOPE)

endfunction(UnitTest)

UnitTest(client/linux linux_client_unittest "breakpad_client \
         -Wl,--build-id=0x000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f")
UnitTest(common dumper_unittest "")
UnitTest(common/linux google_crashdump_uploader_test "")
UnitTest(common test_assembler_unittest "")
UnitTest(tools/linux/md2core minidump_2_core_unittest "")
UnitTest(common/mac macho_reader_unittest "")
set_target_properties(common_mac_macho_reader_unittest PROPERTIES COMPILE_FLAGS -DHAVE_MACH_O_NLIST_H)
target_include_directories(common_mac_macho_reader_unittest PRIVATE src/third_party/mac_headers)

if(NOT BUILD_DISABLE_PROCESSOR)
    UnitTest(processor address_map_unittest "")
    UnitTest(processor basic_source_line_resolver_unittest "")
    UnitTest(processor cfi_frame_info_unittest "")
    UnitTest(processor disassembler_x86_unittest breakpad_client)
    UnitTest(processor map_serializers_unittest "")
    UnitTest(processor microdump_processor_unittest "")
    UnitTest(processor minidump_unittest "")
    UnitTest(processor pathname_stripper_unittest "")
    UnitTest(processor postfix_evaluator_unittest "")
    UnitTest(processor range_map_shrink_down_unittest "")
    UnitTest(processor range_map_unittest breakpad)
    UnitTest(processor synth_minidump_unittest "")
    UnitTest(processor exploitability_unittest breakpad_client)
    UnitTest(processor fast_source_line_resolver_unittest breakpad_client)
    UnitTest(processor minidump_processor_unittest disasm)
    UnitTest(processor proc_maps_linux_unittest disasm)
    UnitTest(processor stackwalker_address_list_unittest breakpad)
    UnitTest(processor stackwalker_amd64_unittest breakpad)
    UnitTest(processor stackwalker_arm64_unittest breakpad)
    UnitTest(processor stackwalker_arm_unittest breakpad)
    UnitTest(processor stackwalker_mips64_unittest breakpad)
    UnitTest(processor stackwalker_mips_unittest breakpad)
    UnitTest(processor stackwalker_x86_unittest breakpad)
    UnitTest(processor static_address_map_unittest breakpad)
    UnitTest(processor static_contained_range_map_unittest breakpad)
    UnitTest(processor static_map_unittest breakpad)
    UnitTest(processor static_range_map_unittest breakpad)
    UnitTest(processor contained_range_map_unittest breakpad_client)
    target_compile_definitions(processor_contained_range_map_unittest PRIVATE -DGENERATE_TEST_DATA)


    add_executable(processor_stackwalker_selftest EXCLUDE_FROM_ALL src/processor/stackwalker_selftest.cc)
    target_link_libraries(processor_stackwalker_selftest breakpad ${DEP_LIBS})
#    add_test(src/processor/stackwalker_selftest processor_stackwalker_selftest)
    list(APPEND processor_check_deps processor_stackwalker_selftest)


    find_program (BASH_PROGRAM bash)
    if (BASH_PROGRAM)

        # shell script test cases expect an executable in the source tree
        add_custom_command(TARGET minidump_dump POST_BUILD 
                            COMMAND ${CMAKE_COMMAND} -E copy 
                            ${CMAKE_BINARY_DIR}/minidump_dump  
                            ${CMAKE_SOURCE_DIR}/src/processor)
        add_custom_command(TARGET minidump_stackwalk POST_BUILD 
                            COMMAND ${CMAKE_COMMAND} -E copy 
                            ${CMAKE_BINARY_DIR}/minidump_stackwalk 
                            ${CMAKE_SOURCE_DIR}/src/processor)
        add_custom_command(TARGET microdump_stackwalk POST_BUILD 
                            COMMAND ${CMAKE_COMMAND} -E copy 
                            ${CMAKE_BINARY_DIR}/microdump_stackwalk 
                            ${CMAKE_SOURCE_DIR}/src/processor)

        add_test (NAME src/processor/minidump_dump_test
                  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                  COMMAND ${BASH_PROGRAM} ./src/processor/minidump_dump_test)

        add_test (NAME src/processor/minidump_stackwalk_machine_readable_test
                  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                  COMMAND ${BASH_PROGRAM} ./src/processor/minidump_stackwalk_machine_readable_test)

        add_test (NAME src/processor/minidump_stackwalk_test
                  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                  COMMAND ${BASH_PROGRAM} ./src/processor/minidump_stackwalk_test)

        add_test (NAME src/processor/microdump_stackwalk_test
                  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                  COMMAND ${BASH_PROGRAM} ./src/processor/microdump_stackwalk_test)

        add_test (NAME src/processor/microdump_stackwalk_machine_readable_test
                  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                  COMMAND ${BASH_PROGRAM} ./src/processor/microdump_stackwalk_machine_readable_test)

    endif (BASH_PROGRAM)

endif()

add_executable(linux_dumper_unittest_helper EXCLUDE_FROM_ALL src/client/linux/minidump_writer/linux_dumper_unittest_helper.cc)
target_link_libraries(linux_dumper_unittest_helper PRIVATE ${DEP_LIBS})
list(APPEND check_deps linux_dumper_unittest_helper)


enable_testing()
set(CMAKE_CTEST_COMMAND srcdir=${CMAKE_SOURCE_DIR} ctest)
add_custom_target(check COMMAND ${CMAKE_CTEST_COMMAND})
add_dependencies(check ${TEST_DEPS} ${check_deps})

if (BASH_PROGRAM)
    add_dependencies(check
        minidump_dump
        minidump_stackwalk
        microdump_stackwalk
    )
endif (BASH_PROGRAM)

endif()

