export QEMACS_IDE=true
export QEMACS_SERVER_START=false
if ! {{EMACSCLIENT_BIN}} -s "${QEMACS_SERVER}" -n $* 2> /dev/null
then
    export QEMACS_SERVER_START=true
    ( {{EMACS_BIN}} ${QEMACS_OPTIONS[*]} $* & )
fi
exit 0
