-- metadata.lua
-- Backend plugin metadata and configuration
-- Documentation: https://mise.jdx.dev/backend-plugin-development.html

PLUGIN = { -- luacheck: ignore
    name = "soar",
    version = "1.0.0",
    description = "A mise backend plugin for soar (pkgforge) — install static binaries and AppImages on Linux",
    author = "Markus Geiger",
    homepage = "https://github.com/blurayne/mise-backend-plugin-soar",
    license = "MIT",
    notes = {
        "Requires soar to be installed on your system: https://soar.qaidvoid.dev/",
        "Only supports Linux — soar is a Linux-only package manager",
        "Packages are sourced from the soarpkgs repository: https://github.com/pkgforge/soarpkgs",
    },
}
