bin := env("HOME") / ".local/bin"

# list recipes
default:
    @just --list

# install script to ~/.local/bin
install:
    install -Dm755 usage-bars.sh {{bin}}/usage-bars

# remove installed script
uninstall:
    rm -f {{bin}}/usage-bars

# lint and format-check
lint:
    shellcheck usage-bars.sh
    shfmt -d usage-bars.sh

# run once and print output
run:
    ./usage-bars.sh
