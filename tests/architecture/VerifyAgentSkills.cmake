cmake_minimum_required(VERSION 3.28)

if(NOT DEFINED AENGINE_SOURCE_DIR)
    message(FATAL_ERROR "AENGINE_SOURCE_DIR is required")
endif()

set(required_skills
    software-architecture
    cpp-api-contracts
    validation-evidence
    third-party-governance
    vulkan-backend
    ui-architecture
    apaint-migration
)

set(max_skill_lines 100)

foreach(skill_name IN LISTS required_skills)
    set(skill_file "${AENGINE_SOURCE_DIR}/.agent/skills/${skill_name}/SKILL.md")
    if(NOT EXISTS "${skill_file}")
        message(FATAL_ERROR "required agent skill is missing: ${skill_name}")
    endif()

    file(READ "${skill_file}" skill_content)
    string(FIND "${skill_content}" "---" front_matter_start)
    string(FIND "${skill_content}" "name: ${skill_name}" skill_name_marker)
    string(FIND "${skill_content}" "description:" description_marker)

    if(NOT front_matter_start EQUAL 0 OR skill_name_marker EQUAL -1 OR description_marker EQUAL -1)
        message(FATAL_ERROR
            "invalid agent skill front matter: ${skill_file}; expected leading --- plus matching name and description")
    endif()

    file(STRINGS "${skill_file}" skill_lines)
    list(LENGTH skill_lines skill_line_count)
    if(skill_line_count GREATER max_skill_lines)
        message(FATAL_ERROR
            "agent skill exceeds focused context budget: ${skill_file} has ${skill_line_count} lines; max is ${max_skill_lines}")
    endif()
endforeach()
