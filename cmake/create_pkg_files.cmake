set(prefix ${CMAKE_INSTALL_PREFIX})
set(exec_prefix \${prefix})
set(libdir \${exec_prefix}/lib)
set(includedir \${prefix}/include)
set(LIBS "")

CONFIGURE_FILE(${top_srcdir}/breakpad.pc.in 
               ${CMAKE_BINARY_DIR}/breakpad.pc @ONLY)

CONFIGURE_FILE(${top_srcdir}/breakpad-client.pc.in 
               ${CMAKE_BINARY_DIR}/breakpad-client.pc @ONLY)

INSTALL(FILES
        ${CMAKE_BINARY_DIR}/breakpad.pc
        ${CMAKE_BINARY_DIR}/breakpad-client.pc
        DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/pkgconfig
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)

