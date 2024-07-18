#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: vesecky@proton.me
# GitHub: veseckytomas
# GitLab: vesecky.tomas

if status is-interactive
    # Commands to run in interactive sessions can go here
    alias pentaho 'export ORACLE_SID=DS.CVUT.CZ && export TNS_ADMIN=~/oracle-instantclient/network/admin/ && export ORACLE_HOME=~/oracle-instantclient/ && ~/pentaho/spoon.sh'
    alias pip '~/python_venv/bin/pip3.12'
    alias python '~/python_venv/bin/python3.11'
    alias root@ebie 'ssh -A -L 5431:dv1:5432 -L 2221:dv1:22 -L 2222:dv2:22 -L 2223:dv3:22 -L 2224:dv4:22  -L 8088:dv2:8080 -L 8008:dv2:8008 root@ebie.is.cvut.cz'
    alias u 'yay -Syu && fisher update && flatpak update'
    alias fzf 'fzf --multi --preview "bat --color=always --style=header,grid --line-range :500 {}"'
    alias nvimf 'nvim $(fzf)'
    alias latex 'xelatex -interaction=batchmode'
    alias cp 'cp -r'
    zoxide init fish | source
end
