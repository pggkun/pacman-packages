cmake_minimum_required(VERSION 3.13)
include_guard(GLOBAL)

include(dkp-custom-target)

function(dkp_generate_binary_embed_sources outvar)
	if (NOT ${ARGC} GREATER 1)
		message(FATAL_ERROR "dkp_generate_binary_embed_sources: must provide at least one input file")
	endif()

	set(outlist "")
	foreach (inname ${ARGN})
		dkp_resolve_file(infile "${inname}")
		get_filename_component(basename "${infile}" NAME)
		string(REPLACE "." "_" basename "${basename}")

		if (TARGET "${inname}")
			set(indeps ${inname} ${infile})
		else()
			set(indeps ${infile})
		endif()

		add_custom_command(
			OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${basename}.s" "${CMAKE_CURRENT_BINARY_DIR}/${basename}.h"
			COMMAND ${DKP_BIN2S} -H "${CMAKE_CURRENT_BINARY_DIR}/${basename}.h" "${infile}" > "${CMAKE_CURRENT_BINARY_DIR}/${basename}.s"
			DEPENDS ${indeps}
			WORKING_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}
			COMMENT "Generating binary embedding source for ${inname}"
		)

		list(APPEND outlist "${CMAKE_CURRENT_BINARY_DIR}/${basename}.s" "${CMAKE_CURRENT_BINARY_DIR}/${basename}.h")
	endforeach()

	set(${outvar} "${outlist}" PARENT_SCOPE)
endfunction()

function(dkp_add_embedded_binary_library target)
	dkp_generate_binary_embed_sources(intermediates ${ARGN})
	add_library(${target} OBJECT ${intermediates})
	target_include_directories(${target} INTERFACE ${CMAKE_CURRENT_BINARY_DIR})
endfunction()

function(dkp_target_use_embedded_binary_libraries target)
	if (NOT ${ARGC} GREATER 1)
		message(FATAL_ERROR "dkp_target_use_embedded_binary_libraries: must provide at least one input library")
	endif()

	foreach (libname ${ARGN})
		target_sources(${target} PRIVATE $<TARGET_OBJECTS:${libname}>)
		target_include_directories(${target} PRIVATE $<TARGET_PROPERTY:${libname},INTERFACE_INCLUDE_DIRECTORIES>)
	endforeach()
endfunction()
