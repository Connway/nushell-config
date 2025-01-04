# Nushell Environment Config File
#
# version = "0.89.0"

def create_left_prompt [] {
    let home =  $nu.home-path

    # Perform tilde substitution on dir
    # To determine if the prefix of the path matches the home dir, we split the current path into
    # segments, and compare those with the segments of the home dir. In cases where the current dir
    # is a parent of the home dir (e.g. `/home`, homedir is `/home/user`), this comparison will
    # also evaluate to true. Inside the condition, we attempt to str replace `$home` with `~`.
    # Inside the condition, either:
    # 1. The home prefix will be replaced
    # 2. The current dir is a parent of the home dir, so it will be uneffected by the str replace
    let dir = (
        if ($env.PWD | path split | zip ($home | path split) | all { $in.0 == $in.1 }) {
            ($env.PWD | str replace $home "~")
        } else {
            $env.PWD
        }
    )

    let path_color = (if (is-admin) { ansi red_bold } else { ansi green_bold })
    let separator_color = (if (is-admin) { ansi light_red_bold } else { ansi light_green_bold })
    let path_segment = $"($path_color)($dir)"

    $path_segment | str replace --all (char path_sep) $"($separator_color)(char path_sep)($path_color)"
}

def create_right_prompt [] {
    # create a right prompt in magenta with green separators and am/pm underlined
    let time_segment = ([
        (ansi reset)
        (ansi magenta)
        (date now | format date '%x %X %p') # try to respect user's locale
    ] | str join | str replace --regex --all "([/:])" $"(ansi green)${1}(ansi magenta)" |
        str replace --regex --all "([AP]M)" $"(ansi magenta_underline)${1}")

    let last_exit_code = if ($env.LAST_EXIT_CODE != 0) {([
        (ansi rb)
        ($env.LAST_EXIT_CODE)
    ] | str join)
    } else { "" }

    ([$last_exit_code, (char space), $time_segment] | str join)
}

# Use nushell functions to define your right and left prompt
$env.PROMPT_COMMAND = {|| create_left_prompt }
# FIXME: This default is not implemented in rust code as of 2023-09-08.
$env.PROMPT_COMMAND_RIGHT = {|| create_right_prompt }

# The prompt indicators are environmental variables that represent
# the state of the prompt
$env.PROMPT_INDICATOR = {|| "> " }
$env.PROMPT_INDICATOR_VI_INSERT = {|| ": " }
$env.PROMPT_INDICATOR_VI_NORMAL = {|| "> " }
$env.PROMPT_MULTILINE_INDICATOR = {|| "::: " }

# If you want previously entered commands to have a different prompt from the usual one,
# you can uncomment one or more of the following lines.
# This can be useful if you have a 2-line prompt and it's taking up a lot of space
# because every command entered takes up 2 lines instead of 1. You can then uncomment
# the line below so that previously entered commands show with a single `🚀`.
# $env.TRANSIENT_PROMPT_COMMAND = {|| "🚀 " }
# $env.TRANSIENT_PROMPT_INDICATOR = {|| "" }
# $env.TRANSIENT_PROMPT_INDICATOR_VI_INSERT = {|| "" }
# $env.TRANSIENT_PROMPT_INDICATOR_VI_NORMAL = {|| "" }
# $env.TRANSIENT_PROMPT_MULTILINE_INDICATOR = {|| "" }
# $env.TRANSIENT_PROMPT_COMMAND_RIGHT = {|| "" }

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
# Note: The conversions happen *after* config.nu is loaded
$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
    "Path": {
        from_string: { |s| $s | split row (char esep) | path expand --no-symlink }
        to_string: { |v| $v | path expand --no-symlink | str join (char esep) }
    }
}

# Directories to search for scripts when calling source or use
# The default for this is $nu.default-config-dir/scripts
$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts') # add <nushell-config-dir>/scripts
]

# Directories to search for plugin binaries when calling register
# The default for this is $nu.default-config-dir/plugins
$env.NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins') # add <nushell-config-dir>/plugins
]

# To add entries to PATH (on Windows you might use Path), you can use the following pattern:
# $env.PATH = ($env.PATH | split row (char esep) | prepend '/some/path')

if ((sys host).name == 'Darwin') {
    $env.PATH = ($env.PATH | split row (char esep) | append '/usr/local/bin' | append '/System/Cryptexes/App/usr/bin' | append 'var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/local/bin' | append '/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/bin' | append '/var/run/com.apple.security.cryptexd/codex.system/bootstrap/usr/appleinternal/bin' | append '/Library/Apple/usr/bin' | append '/usr/local/share/dotnet' | append '~/.dotnet/tools' | append '/Library/Frameworks/Mono.framework/Versions/Current/Commands')

    # Setup Homebrew
    if ('/opt/homebrew' | path exists) {
        $env.PATH = ($env.PATH | split row (char esep) | append '/opt/homebrew/bin' | append '/opt/homebrew/sbin')

        $env.HOMEBREW_PREFIX = '/opt/homebrew'
        $env.HOMEBREW_CELLAR = '/opt/homebrew/Cellar'
        $env.HOMEBREW_REPOSITORY = '/opt/homebrew'
        $env.MANPATH = ['/opt/homebrew/share/man'] # MANPATH doesn't exist yet. Just set it.
        $env.INFOPATH = ['/opt/homebrew/share/info'] # INFOPATH doesn't exist yet. Just set it.

        if ('/opt/homebrew/opt/ruby/bin' | path exists) {
            $env.PATH = ($env.PATH | split row (char esep) | prepend '/opt/homebrew/opt/ruby/bin')
            # $TDOO: Remove the hardcoded version and dynamically determine it.
            $env.PATH = ($env.PATH | split row (char esep) | prepend '/opt/homebrew/lib/ruby/gems/3.4.0/bin')
        }

        if ('/opt/homebrew/opt/git/bin' | path exists) {
            $env.PATH = ($env.PATH | split row (char esep) | prepend '/opt/homebrew/opt/git/bin')
        }

        if ('/opt/homebrew/opt/gpatch/bin' | path exists) {
            $env.PATH = ($env.PATH | split row (char esep) | prepend '/opt/homebrew/opt/gpatch/bin')
        }

        # $TDOO: Remove the hardcoded version and dynamically determine it.
        if ('~/VulkanSDK/1.3.296.0' | path exists) {
            $env.VULKAN_SDK = ('~/VulkanSDK/1.3.296.0/macOS' | path expand)
            $env.VK_SDK_PATH = $env.VULKAN_SDK
            $env.VK_ICD_FILENAMES = ($env.VULKAN_SDK | path join 'share/vulkan/icd.d/MoltenVK_icd.json')
            $env.VK_LAYER_PATH = ($env.VULKAN_SDK | path join 'share/vulkan/explicit_layer.d')

            #$env.DYLD_LIBRARY_PATH = [($env.VULKAN_SDK | path join 'lib')]
            $env.PATH = ($env.PATH | split row (char esep) | prepend 'bin')

            if (($env | find DYLD_LIBRARY_PATH) | is-empty) {
                $env.DYLD_LIBRARY_PATH = []
            }

            $env.DYLD_LIBRARY_PATH = ($env.DYLD_LIBRARY_PATH | split row (char esep) | prepend ($env.VULKAN_SDK | path join 'lib'))
        }
    }

    if (which opam | is-not-empty) {
        # $TODO: Parse opam env.

        #let opam_env = opam env | str trim | lines
        #print $opam_env
        #print ($opam_env | each { |a| $a | split column "=" var export } | flatten | transpose -ird)

        #$opam_env | each { |a| $a | split column "=" var export } | flatten | transpose -ird | load-env
    }

# Windows
} else {
    if (which opam | is-not-empty) {
        let opam_env = opam env | str trim | str replace -a "set \"" "" | str replace -a "set " "" | str replace -a "\"" "" | lines
        $opam_env | each { |a| $a | split column "=" var export } | flatten | transpose -ird | load-env
    }
}

if ('~/Qt' | path exists) {
    # $TODO: At some point, remove the hardcoded version and dynamically determine version.
    $env.PATH = ($env.PATH | split row (char esep) | append '~/Qt/6.7.2/macos/bin')
}

if ('~/go' | path exists) {
    $env.PATH = ($env.PATH | split row (char esep) | append '~/go/bin')
    $env.GOBIN = ('~/go/bin' | path expand)
}

if (which zoxide | is-not-empty) {
    zoxide init nushell | save -f ($nu.default-config-dir | path join zoxide.nu)
}
