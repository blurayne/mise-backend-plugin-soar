--- Lists available versions for a tool from the soar package registry.
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendlistversions
--- @param ctx BackendListVersionsCtx Context (tool = the tool name requested)
--- @return BackendListVersionsResult Table containing list of available versions
function PLUGIN:BackendListVersions(ctx)
    if RUNTIME.osType ~= "linux" then
        error("soar backend only supports Linux (current OS: " .. RUNTIME.osType .. ")")
    end

    local tool = ctx.tool
    if not tool or tool == "" then
        error("Tool name cannot be empty")
    end

    local cmd = require("cmd")
    local json = require("json")
    local log = require("log")

    -- Verify soar is available before proceeding.
    local ok_which, which_out = pcall(cmd.exec, "which soar")
    if not ok_which or (which_out and which_out:match("^%s*$")) then
        error(
            "soar is not installed or not on PATH.\n\n"
                .. "Install soar with one of:\n"
                .. "  mise use -g github:pkgforge/soar\n"
                .. "  curl -fsSL \"https://raw.githubusercontent.com/pkgforge/soar/main/install.sh\" | sh"
        )
    end

    -- Sync registry metadata before searching.
    log.debug("Syncing soar registry")
    pcall(cmd.exec, "soar sync")

    -- soar --json search outputs NDJSON: one JSON object per line.
    -- Each package result line contains pkg_name, version, etc.
    -- The final line is a summary object without pkg_name.
    log.debug("Searching soar registry for: " .. tool)
    local ok, raw = pcall(cmd.exec, "soar --json search " .. tool)
    if not ok then
        error(
            "Failed to run soar: "
                .. tostring(raw)
                .. "\n\nEnsure soar is installed: https://soar.qaidvoid.dev/"
        )
    end

    -- Parse NDJSON: collect entries that have pkg_name (skip summary lines).
    local entries = {}
    if raw and raw ~= "" then
        for line in raw:gmatch("[^\n]+") do
            local line_trimmed = line:match("^%s*(.-)%s*$")
            if line_trimmed ~= "" then
                local ok2, obj = pcall(json.decode, line_trimmed)
                if ok2 and type(obj) == "table" and obj.pkg_name then
                    table.insert(entries, obj)
                end
            end
        end
    end

    -- Helper: extract the package name from a result entry.
    local function pkg_name(entry)
        return (entry.pkg_name or entry.pkg or entry.name or ""):lower()
    end

    -- Collect unique versions from entries that match the requested tool name.
    local version_set = {}
    local versions = {}

    local function add_version(v)
        if v and v ~= "" and not version_set[v] then
            version_set[v] = true
            table.insert(versions, v)
        end
    end

    -- First pass: exact name match (case-insensitive)
    for _, entry in ipairs(entries) do
        if pkg_name(entry) == tool:lower() then
            add_version(entry.version)
        end
    end

    -- Second pass: if no exact match found, accept any result.
    if #versions == 0 and #entries > 0 then
        log.debug("No exact match for '" .. tool .. "'; falling back to all results")
        for _, entry in ipairs(entries) do
            add_version(entry.version)
        end
    end

    if #versions == 0 then
        error(
            "No packages found for '"
                .. tool
                .. "' in the soar registry.\n\n"
                .. "Search for available packages:\n"
                .. "  https://pkgs.pkgforge.dev/?search="
                .. tool
                .. "\n  soar search "
                .. tool
        )
    end

    -- Sort versions in ascending (oldest → newest) order.
    local semver = require("semver")
    local ok3, sorted = pcall(semver.sort, versions)
    if ok3 and #sorted > 0 then
        versions = sorted
    end

    log.debug("Found " .. #versions .. " version(s) for " .. tool)
    return { versions = versions }
end
