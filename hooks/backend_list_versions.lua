--- Lists available versions for a tool from the soar package registry.
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendlistversions
--- @param ctx BackendListVersionsCtx Context (tool = the tool name requested)
--- @return BackendListVersionsResult Table containing list of available versions
function PLUGIN:BackendListVersions(ctx)
    if RUNTIME.osType ~= "Linux" then
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
    if not ok_which or which_out:match("^%s*$") then
        error(
            "soar is not installed or not on PATH.\n\n"
                .. "Install soar with one of:\n"
                .. "  mise use -g github:pkgforge/soar\n"
                .. "  curl -fsSL \"https://raw.githubusercontent.com/pkgforge/soar/main/install.sh\" | sh"
        )
    end

    -- soar --json query returns a JSON array of matching packages.
    -- We filter for exact name matches and collect unique versions.
    log.debug("Querying soar registry for: " .. tool)
    local ok, raw = pcall(cmd.exec, "soar --json query " .. tool)
    if not ok then
        error(
            "Failed to run soar: "
                .. tostring(raw)
                .. "\n\nEnsure soar is installed: https://soar.qaidvoid.dev/"
        )
    end

    local raw_trimmed = raw:match("^%s*(.-)%s*$")
    if raw_trimmed == "" or raw_trimmed == "null" or raw_trimmed == "[]" then
        error("No packages found for '" .. tool .. "' in the soar registry")
    end

    local ok2, data = pcall(json.decode, raw_trimmed)
    if not ok2 then
        error("Failed to parse soar query output: " .. tostring(data) .. "\nRaw output: " .. raw_trimmed)
    end

    -- Normalise: soar may return an array or a single object
    local entries = {}
    if type(data) == "table" then
        if data[1] ~= nil then
            entries = data
        else
            entries = { data }
        end
    end

    if #entries == 0 then
        error("No packages found for '" .. tool .. "' in the soar registry")
    end

    -- Helper: extract the package name from a result entry.
    -- soar uses several field names depending on the registry format.
    local function pkg_name(entry)
        return (entry.pkg or entry.pkg_name or entry.name or ""):lower()
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
    -- (The tool might be referred to by a variant name or pkg_id.)
    if #versions == 0 then
        log.debug("No exact match for '" .. tool .. "'; falling back to all results")
        for _, entry in ipairs(entries) do
            add_version(entry.version)
        end
    end

    if #versions == 0 then
        error(
            "No version information found for '"
                .. tool
                .. "'.\n\n"
                .. "Verify the package exists: soar query "
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
