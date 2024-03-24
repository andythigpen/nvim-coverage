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

local function is_element(name)
    return "element" == reader:node_type() and name == reader:name()
end

local function is_end_element(name)
    return "end element" == reader:node_type() and name == reader:name()
end

local function apply_path_mappings(source)
    for needle, replace in pairs(path_mappings) do
        if 1 == source:find(needle) then
            return source:gsub(needle, replace)
        end
    end

    return source
end

local function resolve_filename_from_sources(filename)
    if filename == "" then
        return ""
    end
    for _, source in pairs(sources) do
        local filepath = Path:new({source, filename})
        if filepath:exists() then
            return filepath.filename
        end
    end
    return filename
end

local function update_coverage_with_current_line(coverage)
    if coverage == nil then
        return
    end
    local linenr = tonumber(reader:get_attribute("number"), 10)
    local count = tonumber(reader:get_attribute("hits"), 10)
    local is_branch = reader:get_attribute("branch") == 'true'

    -- no data for coverage.exclude_lines
    -- no data for coverage.summary.exclude_lines

    if count == 0 then
        table.insert(coverage.missing_lines, linenr)
        coverage.summary.missing_lines = coverage.summary.missing_lines + 1
    else
        table.insert(coverage.executed_lines, linenr)
        coverage.summary.covered_lines = coverage.summary.covered_lines + 1
    end
    coverage.summary.num_statements = coverage.summary.num_statements + 1

    if is_branch then
        rc, cond_info = pcall(reader.get_attribute, reader, "condition-coverage")
        if rc then
            -- Example: "87% (7/8)"
            local br_percent, br_hits, br_total = cond_info:match("([0-9.]+)%% [(](%d+)/(%d+)[)]")
            if br_percent ~= nil then
                br_percent = tonumber(br_percent, 10)
                br_hits = tonumber(br_hits, 10)
                br_total = tonumber(br_total, 10)
                if br_hits < br_total then
                    table.insert(coverage.missing_branches, {linenr, linenr})  -- { from, to }
                end
                coverage.summary.num_branches = coverage.summary.num_branches + br_total
                coverage.summary.num_partial_branches = coverage.summary.num_partial_branches + (br_total - br_hits)
            end
        end
    end

end

local function process_coverage_packages_element(files)
    while not is_end_element("packages") do
        if is_element("package") then
            -- If a package has files (with filename), then report at the file level
            local package_has_files = false
            -- If a package has pure classes (with no filename), then report at the package level
            local package_has_classes = false

            local packages_coverage, packages_filename = nil, ""
            local rc, package_name_attr = pcall(reader.get_attribute, reader, "name")
            if rc then
                package_filename = resolve_filename_from_sources(package_name_attr)
                if package_filename ~= "" then
                    package_coverage = files[package_filename]
                    if package_coverage == nil then
                        package_coverage = util.new_file_meta()
                    end
                end
            end
            if package_coverage ~= nil then
                package_coverage.summary.percent_covered = tonumber(reader:get_attribute("line-rate")) * 100
            end

            reader:read()
            while not is_end_element("package") do
                if is_element("classes") then

                    reader:read()
                    while not is_end_element("classes") do
                        if is_element("class") then

                            local class_coverage, class_filename = nil, ""
                            local rc, class_filename_attr = pcall(reader.get_attribute, reader, "filename")
                            if rc then
                                class_filename = resolve_filename_from_sources(class_filename_attr)
                                if class_filename == package_filename then
                                    class_filename = ""
                                end
                                if class_filename ~= "" then
                                    package_has_files = true
                                    class_coverage = files[class_filename]
                                    if class_coverage == nil then
                                        class_coverage = util.new_file_meta()
                                    end
                                end
                            end
                            if class_coverage ~= nil then
                                class_coverage.summary.percent_covered = tonumber(reader:get_attribute("line-rate")) * 100
                            else
                                -- At least one class does not report its own coverage at the file level
                                package_has_classes = true
                            end

                            reader:read()
                            while not is_end_element("class") do
                                if is_element("lines") then

                                    reader:read()
                                    while not is_end_element("lines") do
                                        if is_element("line") then
                                            update_coverage_with_current_line(package_coverage)
                                            update_coverage_with_current_line(class_coverage)
                                        end
                                        if not reader:next_node() then break end
                                    end

                                end
                                if not reader:next_node() then break end
                            end

                            if class_coverage ~= nil and class_coverage.summary.num_statements > 0 then
                                files[class_filename] = class_coverage
                            end

                        end
                        if not reader:next_node() then break end
                    end

                end
                if not reader:next_node() then break end
            end

            if
                (package_coverage ~= nil and package_coverage.summary.num_statements > 0) and
                (package_has_classes or not package_has_files)
            then
                files[package_filename] = package_coverage
            end

        end
        if not reader:next_node() then break end
    end
end

local function process_coverage_sources_element()
    while not is_end_element("sources") do
        if is_element("source") then
            reader:read()
            local source = apply_path_mappings(reader:value())
            table.insert(sources, source)
        end
        if not reader:next_node() then break end
    end
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
    local found_coverage = false
    local found_packages = false

    while true do
        if is_element("coverage") then
            found_coverage = true

            reader:read()
            while not is_end_element("coverage") do
                if is_element("sources") then
                    reader:read()
                    process_coverage_sources_element()
                elseif is_element("packages") then
                    found_packages = true
                    reader:read()
                    process_coverage_packages_element(files)
                end
                if not reader:next_node() then break end
            end

        end
        if not reader:next_node() then break end
    end

    if not found_coverage then
        notify_element_missing("coverage")
        return
    end
    if not found_packages then
        notify_element_missing("packages")
        return
    end

    reader:close()
end
