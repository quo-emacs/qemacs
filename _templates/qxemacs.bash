export QEMACS_SERVER_START=0
if ! {{EMACSCLIENT_BIN}} -s "${QEMACS_SERVER}" -n $* 2> /dev/null
then
    export QEMACS_SERVER_START=1
    ( {{EMACS_BIN}} ${QEMACS_OPTIONS[*]} $* & )
fi
exit 0
