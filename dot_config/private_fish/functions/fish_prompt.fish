function fish_prompt
    # 设置颜色
    set -l cyan (set_color -o cyan)
    set -l yellow (set_color -o yellow)
    set -l red (set_color -o red)
    set -l normal (set_color normal)

    set_color normal
    echo -n (date "+%H:%M:%S")" "

    # 显示当前目录 (使用缩写路径)
    echo -n -s $cyan (prompt_pwd)" "

    # 如果在 Git 仓库中，显示分支名 (Fish 内置支持)
    set -l git_info (fish_git_prompt | string trim -c '() ')
    if test -n "$git_info"
        echo -n -s $red $git_info" "
    end

    # 换行并显示符号
    # echo -e "$normal"
end
