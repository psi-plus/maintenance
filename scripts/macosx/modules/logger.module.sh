# Logger help functions.
die() { echo; echo -e " \033[1;41m!!!\033[0m ERROR: \033[1;31m$@\033[0m"; \
exit 1; }
error() { echo; echo -e " \033[1;41m!!!\033[0m ERROR: \033[1;31m$@\033[0m"; }
warning() { echo; echo -e " \033[1;43m!\033[0m WARNING: \033[1;33m$@\033[0m"; }
log() { echo -e "\033[1;32m *\033[0m $@"; }
