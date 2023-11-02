#!/bin/python

# fish_dir = "$HOME/.config/fish"
# curl -sSL gmankab.github.io/fish_config/config.fish -o "$fish_dir/config.fish"
# curl -sSL gmankab.github.io/fish_config/fish_prompt.fish -o "$fish_dir/functions/fish_prompt.fish"
# curl -sSL gmankab.github.io/fish_config/fish_user_key_bindings.fish -o "$fish_dir/functions/fish_user_key_bindings.fish"
from pathlib import Path
import subprocess
import shutil
import sys
import pwd
import getpass

fish_dir = Path.home() / '.config/fish'
config = fish_dir / 'config.fish'
functions_dir = fish_dir / 'functions'
prompt = functions_dir / 'fish_prompt.fish'
fish_user_key_bindings = functions_dir / 'fish_user_key_bindings.fish'

functions_dir.mkdir(
    exist_ok = True,
    parents = True,
)

config.write_text(
'''
set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_replace_one underscore
set fish_cursor_visual block
bind y fish_clipboard_copy
bind p fish_clipboard_paste
'''
)

prompt.write_text(
'''
function fish_prompt
    set -l __last_command_exit_status $status
    if not set -q -g __fish_arrow_functions_defined
        set -g __fish_arrow_functions_defined
        function _git_branch_name
            set -l branch (git symbolic-ref --quiet HEAD 2>/dev/null)
            if set -q branch[1]
                echo (string replace -r '^refs/heads/' '' $branch)
            else
                echo (git rev-parse --short HEAD 2>/dev/null)
            end
        end
        function _is_git_dirty
            not command git diff-index --cached --quiet HEAD -- &>/dev/null
            or not command git diff --no-ext-diff --quiet --exit-code &>/dev/null
        end
        function _is_git_repo
            type -q git
            or return 1
            git rev-parse --git-dir >/dev/null 2>&1
        end
        function _hg_branch_name
            echo (hg branch 2>/dev/null)
        end
        function _is_hg_dirty
            set -l stat (hg status -mard 2>/dev/null)
            test -n "$stat"
        end
        function _is_hg_repo
            fish_print_hg_root >/dev/null
        end
        function _repo_branch_name
            _$argv[1]_branch_name
        end
        function _is_repo_dirty
            _is_$argv[1]_dirty
        end
        function _repo_type
            if _is_hg_repo
                echo hg
                return 0
            else if _is_git_repo
                echo git
                return 0
            end
            return 1
        end
    end
    set -l cyan (set_color -o cyan)
    set -l yellow (set_color -o yellow)
    set -l red (set_color -o red)
    set -l green (set_color -o green)
    set -l blue (set_color -o blue)
    set -l normal (set_color normal)
    set -l arrow_color "$green"
    if test $__last_command_exit_status != 0
        set arrow_color "$red"
    end
    set -l arrow "$arrow_color➜ "
    if fish_is_root_user
        set arrow "$arrow_color# "
    end
    set -l cwd $cyan(basename (prompt_pwd))
    set -l repo_info
    if set -l repo_type (_repo_type)
        set -l repo_branch $red(_repo_branch_name $repo_type)
        set repo_info "$blue $repo_type:($repo_branch$blue)"
        if _is_repo_dirty $repo_type
            set -l dirty "$yellow ✗"
            set repo_info "$repo_info$dirty"
        end
    end
    echo -n -s $arrow ' '$cwd $repo_info $normal ' '
end
'''
)

fish_user_key_bindings.write_text(
'''
function fish_user_key_bindings
  fish_vi_key_bindings
  bind -M insert -m default jk backward-char force-repaint
end
'''
)


class PackageInstaller():
    def __init__(
        self,
        packages: list[str] = [],
    ) -> None:
        if packages:
            for package in packages.copy():
                if shutil.which(package):
                    print(green(
                        f'{package} already installed',
                    ))
                    packages.remove(package)
            if not packages:
                return
        dnf = shutil.which('dnf')
        apt = shutil.which('apt')
        pacman = shutil.which('pacman')
        self.install_command: list[str] = []
        if dnf:
            self.install_command = ['sudo', dnf, 'install', '-y']
        elif apt:
            self.install_command = ['sudo', apt, 'install']
        elif pacman:
            self.install_command = ['sudo', pacman, '-Sy', '--noconfirm']
        else:
            text = 'warn: can not find supported package manager'
            if packages:
                text += f', please manualy install these packages: {packages}'
            print(red(
                text
            ))
            sys.exit()
        self.install(packages)

    def install(
        self,
        packages: list[str],
    ) -> None:
        if not packages:
            return
        print(
            green(
                f'do you want to intstal these packages: {packages} [Y/n]: ',
            ),
            end = '',
        )
        answer = input().lower()
        if 'n' in answer:
            return
        subprocess.run(
            self.install_command + packages,
            check = True,
        )


def green(
    text: str,
):
    return '\033[1;32m' + text + '\033[0m'

def red(
    text: str,
):
    return '\033[1;31m' + text + '\033[0m'

def main():
    PackageInstaller(['fish'])
    username = getpass.getuser()
    default_shell = pwd.getpwnam(
        username
    ).pw_shell
    if 'fish' in default_shell:
        print(green(
            'fish is already the default shell'
        ))
        return
    fish_path = shutil.which('fish')
    if not fish_path:
        print(red(
            'failed to install fish'
        ))
        return
    subprocess.run(
        ['chsh', '-s', fish_path, username],
        check=True,
    )

main()

