# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/.local/share/kiro-cli/shell/bashrc.pre.bash" ]] && builtin source "${HOME}/.local/share/kiro-cli/shell/bashrc.pre.bash"
# ~/.bashrc: executed by bash(1) for non-login shells.

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=9999999
HISTFILESIZE=999999
export HISTCONTROL=ignoreboth

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

if [ -f "$HOME/.bash-git-prompt/gitprompt.sh" ]; then
    GIT_PROMPT_ONLY_IN_REPO=1
    source "$HOME/.bash-git-prompt/gitprompt.sh"
fi

export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
###-begin-gitlab-ci-local-completions-###
#
# yargs command completion script
#
# Installation: /usr/local/bin/gitlab-ci-local completion >> ~/.bashrc
#    or /usr/local/bin/gitlab-ci-local completion >> ~/.bash_profile on OSX.
#
_gitlab-ci-local_yargs_completions()
{
    local cur_word args type_list

    cur_word="${COMP_WORDS[COMP_CWORD]}"
    args=("${COMP_WORDS[@]}")

    # ask yargs to generate completions.
    type_list=$(/usr/local/bin/gitlab-ci-local --get-yargs-completions "${args[@]}")

    COMPREPLY=( $(compgen -W "${type_list}" -- ${cur_word}) )

    # if no match was found, fall back to filename completion
    if [ ${#COMPREPLY[@]} -eq 0 ]; then
      COMPREPLY=()
    fi

    return 0
}
#complete -o bashdefault -o default -F _gitlab-ci-local_yargs_completions gitlab-ci-local
###-end-gitlab-ci-local-completions-###

echo -e '\e[?5l'  # Disable visual bell
printf '\e[?1000l'  # Disable bell completely


alias orig='cd /projects/saved-deltavacations-rags-14Jul/original_repos/kmgenai-cicd'
alias g="git add .; git commit -m 'Generic Commit'; git push"
alias gs='git status'
alias gd='git diff'
alias gl='git log --pretty=oneline'
alias gc='git add .; git status; read junk; git commit'
export EDITOR=vim
alias genai='cd /projects/genai-agent-code'
alias unirepo='cd /projects/repos-private-gitlab/original-refactored-for-private-gitlab/unirepo'
alias runner='cd /projects/gitlab-runner/builds/sbNjH-nP8/0/km/km-rags-bk-code'
alias downl='cd /mnt/c/Users/u86069/Downloads'
alias deploy="clear; npx cdk deploy --require-approval never --all"
alias synth="clear; npx cdk synth --all"
alias mycred="cp ~/.aws/credentials.mine ~/.aws/credentials; aws sts get-caller-identity"
alias cody="code-insiders ."
alias tagy='gc; git tag $tag; git push --set-upstream origin $tag'
alias gall='git log --all --oneline --format="%C(yellow)%h%C(reset) %C(green)%ad%C(reset) %C(blue)%an%C(reset) %C(red)%d%C(reset) %s" --date=format:"%Y-%m-%d %H:%M" --graph'
alias glaby="glab auth login --token glpat-9J4paA0aauPTx1jKRIRPGG86MQp1OmFxYQk.01.0z1gtmqq2  --hostname git.delta.com"
alias kiro='/mnt/c/Program\ Files/Kiro/bin/kiro'
alias hrgpt="cd /projects/all_repos/dgpeai/hrgpt"
alias service="cd /projects/all_repos/dgpeai/service-catalog"
alias dlv="cd /projects/all_repos/dlv/km/rag/dlv-rag-app/"
alias itdapp="cd /projects/all_repos/dgpeai/ITD/traveldocs-app-pipeline"
alias itdinfra="cd /projects/all_repos/dgpeai/ITD/traveldocs-infra-pipeline/"
alias q="kiro-cli"
alias cnc="cd /projects/all_repos/dgpeai/customercleans/customer-cleanse-gitlab"
alias itd="cd /projects/all_repos/dgpeai/ITD/ITD"
alias glab-scan="docker run --rm   -v $(pwd):/code   registry.gitlab.com/security-products/gemnasium:latest   /analyzer run --target-dir /code"
alias clear="~/bin/clear"
alias pass="cd /projects/all_repos/dgpeai/pass-travel-ai"
alias docred="vi ~/.aws/credentials"
alias showcred="cat ~/.aws/credentials"
alias kchat="kiro-cli chat --trust-tools glob,read,write,shell,web_search,web_fetch,search_documentation"
alias godown="cd /mnt/c/Users/u86069/Downloads/"
alias delay="cd /projects/all_repos/dgpeai/delaycontext/"


# docker setting for rag app
#docker run --rm --privileged multiarch/qemu-user-static --reset -p yes



export GITLAB_HOST=git.delta.com
export PATH="/projects/sonar-scanner/bin:$PATH"


cd /home/ppatram

glab auth login --token glpat-vc0GqPxexSKqgdPK2xgP-W86MQp1OmFxYQk.01.0z1f30xca --hostname git.delta.com

function chm (){ chmod +x $@; }

function acclookup(){
 acc=$1
 grep $acc /projects/devspaces/all_accounts.txt
}

function cpfromdownloads(){ cp /mnt/c/Users/u86069/Downloads/${1}* /tmp/; }
function cptodownloads(){
 file=$1
 cp $file /mnt/c/Users/u86069/Downloads/
}

function cloneme(){
  url=$(git remote -v | awk '{print $2}' | head -1)
  echo "Cloning $url"
  git clone $url
}

tfchanges() {
  terraform show -json tfplan | jq -r '
    .resource_changes[]
    | select(.change.actions | any(. == "create" or . == "update"))
    | "\(.change.actions | map(ascii_upcase) | join(",")): \(.address)"
  '
}

function sts(){ profile=$1; aws sts get-caller-identity --profile $profile; }
function debug-codebuild() {  cat $1 | jq -Rs .; }



export PATH="~/.local/bin:~/bin:$PATH"
echo "complete -C '/usr/local/bin/aws_completer' aws"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/.local/share/kiro-cli/shell/bashrc.post.bash" ]] && builtin source "${HOME}/.local/share/kiro-cli/shell/bashrc.post.bash"

alias terrashow='terraform show -json tfplan | jq -r '\''\.resource_changes[] | select(.change.actions | any(. == "create" or . == "update")) | "\(.change.actions | map(ascii_upcase) | join(",")):
  \(.address)"'\'''
