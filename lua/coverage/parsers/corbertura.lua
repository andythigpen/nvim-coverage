local Path = require("plenary.path")
local util = require("coverage.util")
local xmlreader = require("xmlreader")
local reader, path_mappings, sources = nil, {}, {}

--- @param name string
local function notify_element_missing(name)
    vim.notify(string.format("Invalid cobertura format, no '%s' element found", name), vim.log.levels.ERROR)
end

--- @param path Path
local function read_path(path)
    return assert(xmlreader.from_string(path:read()))
end

--- Position the reader on the next element `name` found before the closing element for `parent`
---
--- @param name string
--- @param parent string|nil
local function next_element_in(name, parent)
    while nil ~= reader and reader:next_node() do
        if "element" == reader:node_type() and name == reader:name() then
            return true
        end
        if "end element" == reader:node_type() and parent == reader:name() then
            return false
        end
    end

    return false
end

local function enter_current_element()
    reader:read()
end

--- Enter in the next element `name` found before the closing element for `parent`
---
--- @param name string
--- @param parent string|nil
local function enter_next_element_in(name, parent)
    if false == next_element_in(name, parent) then
        return false
    end

    enter_current_element()

    return true
end

--- Enter in the next element `name`, will jump over any other element
---
--- @param name string
local function enter_next_element(name)
    return enter_next_element_in(name, nil)
end

local function apply_path_mappings(source)
    for needle, replace in pairs(path_mappings) do
        if 1 == source:find(needle) then
            return source:gsub(needle, replace)
        end
    end

    return source
end

local function load_sources()
    if enter_next_element_in("sources", "coverage") then
        while enter_next_element_in("source", "sources") do
            local source = apply_path_mappings(reader:value())
            table.insert(sources, source)
        end
    end
end

local function create_coverage_for_current_package()
    local coverage = util.new_file_meta()
    coverage.summary.percent_covered = tonumber(reader:get_attribute("line-rate")) * 100

    return coverage
end

local function update_coverage_with_current_line(coverage)
    local number = tonumber(reader:get_attribute("number"), 10)
    local hits = tonumber(reader:get_attribute("hits"), 10)

    if 0 == hits then
        table.insert(coverage.missing_lines, number)
        coverage.summary.missing_lines = coverage.summary.missing_lines + 1
    else
        table.insert(coverage.executed_lines, number)
        coverage.summary.covered_lines = coverage.summary.covered_lines + 1
    end

    coverage.summary.num_statements = coverage.summary.num_statements + 1
end

local function resolve_filename_from_sources(filename)
    for _, source in pairs(sources) do
        local filepath = Path:new({source, filename})
        if filepath:exists() then
            return filepath.filename
        end
    end

    return filename
end

local function generate_coverages()
    local coverages = {}
    while next_element_in("package", "packages") do
        local coverage = create_coverage_for_current_package()
        local filename = resolve_filename_from_sources(reader:get_attribute("name"))

        enter_current_element()
        if enter_next_element_in("classes", "package") then
            -- In case of <classes /> we must stop on </package> at the latest
            -- Only one "classes" per "package" anyway
            while enter_next_element_in("class", "package") do
                while enter_next_element_in("lines", "class") do
                    while next_element_in("line", "lines") do
                        update_coverage_with_current_line(coverage)
                    end
                end
            end
        end

        local is_not_interface = 0 < coverage.summary.num_statements
        if is_not_interface then
            coverages[filename] = coverage
        end
    end

    return coverages
end

--- Parses a cobertura report from path into files.
---
--- @param path Path
--- @param files table<string, FileCoverage>
--- @param a_path_mappings table<string, string>
return function (path, files, a_path_mappings)
    reader = read_path(path)
    path_mappings = a_path_mappings
    sources = {}

    if false == enter_next_element("coverage") then
        notify_element_missing("coverage")
        return
    end

    load_sources()

    if false == enter_next_element_in("packages", "coverage") then
        notify_element_missing("packages")
        return
    end

    for filename, coverage in pairs(generate_coverages()) do
        files[filename] = coverage
    end

    reader:close()
end
