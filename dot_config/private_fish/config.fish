if status is-interactive
# Commands to run in interactive sessions can go here
end

alias ls="ls -AG"

set -gx HOMEBREW_API_DOMAIN "https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
set -gx HOMEBREW_BREW_GIT_REMOTE "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
set -gx HOMEBREW_CORE_GIT_REMOTE "https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
