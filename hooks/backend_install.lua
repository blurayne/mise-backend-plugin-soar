--- Installs a specific package version via soar.
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendinstall
--- @param ctx BackendInstallCtx Context (tool, version, install_path)
--- @return BackendInstallResult Empty table on success
function PLUGIN:BackendInstall(ctx)
    if RUNTIME.osType ~= "Linux" then
        error("soar backend only supports Linux (current OS: " .. RUNTIME.osType .. ")")
    end

    local tool = ctx.tool
    local version = ctx.version
    local install_path = ctx.install_path

    if not tool or tool == "" then
        error("Tool name cannot be empty")
    end
    if not version or version == "" then
        error("Version cannot be empty")
    end
    if not install_path or install_path == "" then
        error("Install path cannot be empty")
    end

    local cmd = require("cmd")
    local file = require("file")
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

    local bin_path = file.join_path(install_path, "bin")

    -- Create the bin directory so soar has a target to write into.
    cmd.exec("mkdir -p " .. bin_path)

    -- Build the package spec.  soar's registry install supports <pkg>@<version>.
    -- We always pass the version so mise version-pinning is honoured where possible.
    -- If soar does not recognise the @<version> syntax it will install its latest.
    local pkg_spec = tool .. "@" .. version

    log.info("Installing " .. pkg_spec .. " via soar → " .. bin_path)

    -- Key flags:
    --   --yes           skip interactive prompts (pick first variant)
    --   --binary-only   install only the executable (no desktop files, logs, etc.)
    -- SOAR_BIN redirects the binary into mise's install directory instead of
    -- the global soar bin dir (~/.local/share/soar/bin).
    local ok_install, result = pcall(cmd.exec, "soar install --yes --binary-only " .. pkg_spec, {
        env = { SOAR_BIN = bin_path },
    })

    if not ok_install then
        -- soar 0.x sometimes errors on @<version> for registry pkgs; retry without it.
        log.warn("Install with version spec failed, retrying without version: " .. tostring(result))
        local ok_retry, retry_result = pcall(cmd.exec, "soar install --yes --binary-only " .. tool, {
            env = { SOAR_BIN = bin_path },
        })
        if not ok_retry then
            error(
                "Failed to install '"
                    .. tool
                    .. "' via soar: "
                    .. tostring(retry_result)
                    .. "\n\nTry running manually: soar install "
                    .. tool
            )
        end
    end

    -- Sanity check: at least one executable should now exist in bin_path.
    local ok_ls, ls_out = pcall(cmd.exec, "ls " .. bin_path)
    if not ok_ls or ls_out:match("^%s*$") then
        error(
            "Installation appeared to succeed but no files were found in "
                .. bin_path
                .. ".\n\nCheck soar output above for errors."
        )
    end

    log.debug("Installed files: " .. ls_out)
    return {}
end
