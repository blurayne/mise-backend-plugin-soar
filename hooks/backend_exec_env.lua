--- Sets up environment variables for a soar-managed tool.
--- Documentation: https://mise.jdx.dev/backend-plugin-development.html#backendexecenv
--- @param ctx BackendExecEnvCtx Context (tool, version, install_path)
--- @return BackendExecEnvResult Table of environment variable definitions
function PLUGIN:BackendExecEnv(ctx)
    local install_path = ctx.install_path
    local file = require("file")

    -- The binary (or a symlink to it) is placed in <install_path>/bin/ during
    -- BackendInstall, so we only need to prepend that directory to PATH.
    local bin_path = file.join_path(install_path, "bin")

    return {
        env_vars = {
            { key = "PATH", value = bin_path },
        },
    }
end
