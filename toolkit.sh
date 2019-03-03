#!/bin/bash

####################################################
#                      MISC                        #
####################################################

function CHECKVERSION
{
    local EXPECTED="$1"
    [ "$EXPECTED" != "$VERSION" ] && ECHO "⚠ Error: Toolkit version $EXPECTED expected (but version $VERSION found)!" && exit 0
}

function CHECK
{
    for FILE in "$@" ; do
        [ ! -f $FILE ] && ECHO "⚠ File \"$FILE\" is missing!" && exit 0
    done
}

function CHECKINPUTS
{
    [ -z "$INPUTS" ] && echo "⚠ INPUTS variable is not defined!" && exit 0
    CHECK $INPUTS
}

function COPYINPUTS
{
    [ -z "$INPUTS" ] && echo "⚠ INPUTS variable is not defined!" && exit 0
    [ -z "$RUNDIR" ] && echo "⚠ RUNDIR variable is not defined!" && exit 0
    cp -f $INPUTS $RUNDIR/
}

####################################################
#                  RUN MODE                        #
####################################################

# echo in blue (RUN mode only)
function ECHOBLUE
{
    echo -n -e "\033[34m" && echo -n "$@" && echo -e "\033[0m"
}

# echo in green (RUN mode only)
function ECHOGREEN
{
    echo -n -e "\033[32m" && echo -n "$@" && echo -e "\033[0m"
}

# echo in red (RUN mode only)
function ECHORED
{
    echo -n -e "\033[31m"  && echo -n "$@" && echo -e "\033[0m"
}

# echo a command (in green) and execute it (RUN mode only)
function RTRACE
{
    [ "$MODE" != "RUN" ] && "Error: function RTRACE only available in RUN mode!" && exit 0
    ECHOBLUE "$ $@"
    bash -c "setsid -w $@"
    RET=$?
    if [ $RET -eq 0 ] ; then
        ECHOGREEN "✓ Success."
    else
        ECHORED "⚠ Failure!"
    fi
    return $RET
}

# inputs: MSG [MSGOK] [CMDOK]
# return 0
function RBONUS
{
    [ "$MODE" != "RUN" ] && echo "Error: function RBONUS only available in RUN mode!" && exit 0
    local MSG="$1"
    local MSGOK="success."
    local CMDOK=""
    if [ $# -eq 2 ] ; then
        MSGOK="$2"
        elif [ $# -eq 3 ] ; then
        MSGOK="$2"
        CMDOK="$3"
    fi
    ECHOGREEN "✓ $MSG: $MSGOK"
    eval "$CMDOK"
    return 0
}

# inputs: MSG [MSGKO] [CMDKO]
# return 0
function RMALUS
{
    [ "$MODE" != "RUN" ] && echo "Error: function RMALUS only available in RUN mode!" && exit 0
    local MSG="$1"
    local MSGKO="failure!"
    local CMDKO=""
    if [ $# -eq 2 ] ; then
        MSGKO="$2"
        elif [ $# -eq 3 ] ; then
        MSGKO="$2"
        CMDKO="$3"
    fi
    ECHORED "⚠ $MSG: $MSGKO"
    eval "$CMDKO"
    return 0
}

# inputs: MSG [MSGOK MSGKO] [CMDOK CMDKO]
# return: $?
function REVAL
{
    local RET=$?
    [ "$MODE" != "RUN" ] && echo "Error: function REVAL only available in RUN mode!" && exit 0
    local MSG=""
    local MSGOK="success."
    local MSGKO="failure!"
    local CMDOK=""
    local CMDKO=""
    if [ $# -eq 1 ] ; then
        MSG="$1"
        elif [ $# -eq 3 ] ; then
        MSG="$1"
        MSGOK="$2"
        MSGKO="$3"
        elif [ $# -eq 5 ] ; then
        MSG="$1"
        MSGOK="$2"
        MSGKO="$3"
        CMDOK="$4"
        CMDKO="$5"
    else
        echo "Usage: REVAL MSG [MSGOK MSGKO] [CMDOK CMDKO]" && exit 0
    fi
    if [ $RET -eq 0 ] ; then
        RBONUS "$MSG" "$MSGOK" "$CMDOK"
    else
        RMALUS "$MSG" "$MSGKO" "$CMDKO"
    fi
    return $RET
}

####################################################
#                  EVAL MODE                       #
####################################################

# echo in comment window (EVAL mode only)
function COMMENT
{
    echo "Comment :=>>$@"
}

# title in comment window (EVAL mode only)
function TITLE
{
    echo "Comment :=>>-$@"
}

# pre-formatted echo in comment window (EVAL mode only)
function PRE
{
    echo "Comment :=>>>$@"
}

# echo a command in execution window and execute it (EVAL mode only)
function TRACE
{
    [ "$MODE" != "EVAL" ] && "Error: function TRACE only available in EVAL mode!" && exit 0
    echo "Trace :=>>$ $@"
    # bash -c "$@" |& sed -e 's/^/Output :=>>/;'
    bash -c "setsid -w $@" |& sed -e 's/^/Output :=>>/;' # setsid is used for safe exec (setpgid(0,0))
    RET=${PIPESTATUS[0]}  # return status of first piped command!
    echo "Status :=>> $RET"
    return $RET
}

# echo a command in comment window and execute it (EVAL mode only)
function CTRACE
{
    [ "$MODE" != "EVAL" ] && "Error: function CTRACE only available in EVAL mode!" && exit 0
    COMMENT "$ $@"
    echo "<|--"
    bash -c "setsid -w $@" |& sed -e 's/^/>/;' # preformated output
    RET=${PIPESTATUS[0]}  # return status of first piped command!
    echo "--|>"
    echo "Status :=>> $RET"
    return $RET
}

# inputs: MSG VALUE [MSGOK] [CMDOK]
# return 0
function BONUS
{
    local MSG="$1"
    local VALUE="$2"
    local MSGOK="success."
    local CMDOK=""
    local RVALUE=$(python3 -c "print(\"%.2f\" % ($VALUE))")
    if [ $# -eq 3 ] ; then
        MSGOK="$3"
    elif [ $# -eq 4 ] ; then
        MSGOK="$3"
        CMDOK="$4"
    fi
    if [ "$VALUE" = "X" ] ; then
        COMMENT "✓ $MSG: $MSGOK [+∞]" && EXIT 100
        elif [ "$VALUE" = "0" ] ; then
        COMMENT "✓ $MSG: $MSGOK"
    else
        COMMENT "✓ $MSG: $MSGOK [+$RVALUE%]"
    fi
    GRADE=$(python3 -c "print($GRADE+$RVALUE)")
    eval $CMDOK
    return 0
}

# inputs: MSG VALUE [MSGOK] [CMDKO]
# return 0
function MALUS
{
    local MSG="$1"
    local VALUE="$2"
    local MSGKO="failure!"
    local CMDKO=""
    local RVALUE=$(python3 -c "print(\"%.2f\" % ($VALUE))")
    if [ $# -eq 3 ] ; then
        MSGKO="$3"
    elif [ $# -eq 4 ] ; then
        MSGKO="$3"
        CMDKO="$4"
    fi
    if [ "$VALUE" = "X" ] ; then
        COMMENT "⚠ $MSG: $MSGKO [-∞]" && EXIT 0
    elif [ "$VALUE" = "0" ] ; then
        COMMENT "⚠ $MSG: $MSGKO"
    else
        COMMENT "⚠ $MSG: $MSGKO [-$RVALUE%]"
    fi
    GRADE=$(python3 -c "print($GRADE-$RVALUE)")
    eval $CMDKO
    return 0
}

# inputs: MSG VALUEBONUS VALUEMALUS [MSGOK MSGKO] [CMDOK CMDKO] and $?
# return: $?
function EVAL
{
    local RET=$?
    [ "$MODE" != "EVAL" ] && echo "Error: function EVAL only available in EVAL mode!" && exit 0
    echo "Debug :=>> EVAL $@"
    local MSG="$1"
    local VALUEBONUS="$2"
    local VALUEMALUS="$3"
    local MSGOK="success."
    local MSGKO="failure!"
    local CMDOK=""
    local CMDKO=""
    if [ $# -eq 5 ] ; then
        MSGOK="$4"
        MSGKO="$5"
    elif [ $# -eq 7 ] ; then
        MSGOK="$4"
        MSGKO="$5"
        CMDOK="$6"
        CMDKO="$7"
    fi
    if [ $RET -eq 0 ] ; then
        BONUS "$MSG" "$VALUEBONUS" "$MSGOK" "$CMDOK"
    else
        MALUS "$MSG" "$VALUEMALUS" "$MSGKO" "$CMDKO"
    fi
    return $RET
}

# inputs: [GRADE]
function EXIT
{
    [ -z "$GRADE" ] && GRADE=0
    [ $# -eq 1 ] && GRADE=$1
    GRADE=$(python3 -c "print(0 if $GRADE < 0 else round($GRADE))")
    GRADE=$(python3 -c "print(100 if $GRADE > 100 else round($GRADE))")
    ECHO "-GRADE" && ECHO "$GRADE%"
    if [ "$MODE" = "EVAL" ] ; then echo "Grade :=>> $GRADE" ; fi
    # if [ "$MODE" = "RUN" ] ; then echo "👉 Use Ctrl+Shift+⇧ / Ctrl+Shift+⇩ to scroll up / down..." ; fi
    exit 0
}

####################################################
#                RUN & EVAL MODE                   #
####################################################

# echo both in RUN & EVAL modes
function ECHO
{
    if [ "$MODE" = "RUN" ] ; then
        echo "$@"
    else
        echo "Comment :=>>$@"
    fi
}

# echo in verbose mode only
function ECHOV
{
    if [ "$VERBOSE" = "1" ] ; then ECHO "$@" ; fi
}


####################################################
#                RUN & EVAL MODE                   #
####################################################

function XECHOBLUE
{
    if [ "$MODE" = "RUN" ] ; then
        echo -n -e "\033[34m" && echo -n "$@" && echo -e "\033[0m"
    else
        echo "Comment :=>>$@"
    fi
}

function XECHOGREEN
{
    if [ "$MODE" = "RUN" ] ; then
        echo -n -e "\033[32m" && echo -n "$@" && echo -e "\033[0m"
    else
        echo "Comment :=>>$@"
    fi
}

function XECHORED
{
    if [ "$MODE" = "RUN" ] ; then
        echo -n -e "\033[31m"  && echo -n "$@" && echo -e "\033[0m"
    else
        echo "Comment :=>>$@"
    fi
}

function XECHO
{
    if [ "$MODE" = "RUN" ] ; then
        echo "$@"
    else
        echo "Comment :=>>$@"
    fi
}

function XTITLE
{
    if [ "$MODE" = "EVAL" ] ; then
        echo "Comment :=>>-$@"
    else
        ECHOBLUE "######### $@ ##########"
    fi
}

function XCAT
{
    if [ "$MODE" = "EVAL" ] ; then
        # cat $@ |& sed -e 's/^/Comment :=>>/;'    
        echo "<|--"
        cat $@ |& sed -e 's/^/>/;' # preformated output
        RET=$?
        echo "--|>"
    else
        cat $@
        RET=$?
    fi
    return $RET
}

function XTRACE
{
    if [ "$MODE" = "EVAL" ] ; then    
        echo "<|--"
        bash -c "setsid -w $@" |& sed -e 's/^/>/;' # preformated output
        RET=${PIPESTATUS[0]}  # return status of first piped command!
        echo "--|>"
    else
        bash -c "setsid -w $@"
        RET=$?
    fi

    return $RET
}

function XCAT_TEACHER
{
    RET=0
    if [ "$MODE" = "EVAL" ] ; then
        echo "Trace :=>>$ cat $@"
        bash -c "cat $@" |& sed -e 's/^/Output :=>>/;' # setsid is used for safe exec (setpgid(0,0))
        RET=${PIPESTATUS[0]}  # return status of first piped command!
    fi
    return $RET
}

function XTRACE_TEACHER
{
    if [ "$MODE" = "EVAL" ] ; then    
        echo "Trace :=>>$ $@"
        bash -c "setsid -w $@" |& sed -e 's/^/Output :=>>/;' # setsid is used for safe exec (setpgid(0,0))
        RET=${PIPESTATUS[0]}  # return status of first piped command!
        echo "Status :=>> $RET"
    else
        bash -c "setsid -w $@" &> /dev/null
        RET=$?
    fi

    return $RET
}

# inputs: MSG [MSGOK]
# return 0
function XPRINTOK
{
    local MSG="$1"
    local MSGOK="success"
    if [ $# -eq 2 ] ; then
        MSGOK="$2"
    fi
    XECHOGREEN "✔️ $MSG: $MSGOK"
    return 0
}

# inputs: MSG [MSGKO]
# return 0
function XPRINTKO
{
    local MSG="$1"
    local MSGKO="failure"
    if [ $# -eq 2 ] ; then
        MSGKO="$2"
    fi
    XECHORED "⚠️ $MSG: $MSGKO"
    return 0
}

# inputs: MSG SCORE [MSGOK]
# return 0
function XPRINTOK_GRADE
{
    local MSG=""
    local SCORE=0
    local MSGOK="success"
    if [ $# -eq 2 ] ; then
        MSG="$1"
        SCORE="$2" # TODO: check score is >= 0
    elif [ $# -eq 3 ] ; then
        MSG="$1"
        SCORE="$2"
        MSGOK="$3"
    else
        XECHO "Usage: $0 MSG SCORE [MSGOK]" && exit 0
    fi
    local MSGSCORE=""
    if [ $SCORE -ne 0 ] ; then
        local LGRADE=$(python3 -c "print(\"%+.2f\" % ($SCORE))") # it must be positive
        GRADE=$(python3 -c "print($GRADE+$LGRADE)")
        MSGSCORE="[$LGRADE%]"
    fi
    XPRINTOK "$MSG" "$MSGOK $MSGSCORE"
    return 0
}

# inputs: MSG SCORE [MSGKO]
# return 0
function XPRINTKO_GRADE
{
    local MSG=""
    local SCORE=0
    local MSGKO="failure"
    if [ $# -eq 2 ] ; then
        MSG="$1"
        SCORE="$2" # TODO: check score is <= 0
    elif [ $# -eq 3 ] ; then
        MSG="$1"
        SCORE="$2"
        MSGKO="$3"
    else
        XECHO "Usage: $0 MSG SCORE [MSGKO]" && exit 0
    fi
    local MSGSCORE=""
    if [ $SCORE -ne 0 ] ; then
        local LGRADE=$(python3 -c "print(\"%+.2f\" % ($SCORE))") # it must be negative
        GRADE=$(python3 -c "print($GRADE+$LGRADE)")
        MSGSCORE="[$LGRADE%]"
    fi
    XPRINTKO "$MSG" "$MSGOK $MSGSCORE"
    return 0
}

# inputs: MSG SCORE [MSGOK MSGKO]
# global inputs: $GRADE $?
# return: $?
function XEVAL
{
    local RET=$?
    local MSG=""
    local SCORE=0
    local MSGOK="success"
    local MSGKO="failure"
    if [ $# -eq 2 ] ; then
        MSG="$1"
        SCORE="$2"
    elif [ $# -eq 4 ] ; then
        MSG="$1"
        SCORE="$2"
        MSGOK="$3"
        MSGKO="$4"
    else
        XECHO "Usage: XEVAL MSG SCORE [MSGOK MSGKO]" && exit 0
    fi
    local LGRADE=$(python3 -c "print(\"%+.2f\" % ($SCORE))")
    local MSGSCORE=""
    if [ $SCORE -ne 0 ] ; then
        MSGSCORE="[$LGRADE%]"
    fi
    if [ $RET -eq 0 ] ; then
        XPRINTOK_GRADE "$MSG" "$SCORE" "$MSGOK"
    else
        XPRINTKO_GRADE "$MSG" "$SCORE" "$MSGKO"
    fi
    return $RET
}


# # inputs: MSG VALUE [MSGOK] [CMDOK]
# # return 0
# function BONUS
# {
#     local MSG="$1"
#     local VALUE="$2"
#     local MSGOK="success."
#     local CMDOK=""
#     local RVALUE=$(python3 -c "print(\"%.2f\" % ($VALUE))")
#     if [ $# -eq 3 ] ; then
#         MSGOK="$3"
#     elif [ $# -eq 4 ] ; then
#         MSGOK="$3"
#         CMDOK="$4"
#     fi
#     if [ "$VALUE" = "X" ] ; then
#         COMMENT "✓ $MSG: $MSGOK [+∞]" && EXIT 100
#         elif [ "$VALUE" = "0" ] ; then
#         COMMENT "✓ $MSG: $MSGOK"
#     else
#         COMMENT "✓ $MSG: $MSGOK [+$RVALUE%]"
#     fi
#     GRADE=$(python3 -c "print($GRADE+$RVALUE)")
#     eval $CMDOK
#     return 0
# }

# # inputs: MSG VALUE [MSGOK] [CMDKO]
# # return 0
# function MALUS
# {
#     local MSG="$1"
#     local VALUE="$2"
#     local MSGKO="failure!"
#     local CMDKO=""
#     local RVALUE=$(python3 -c "print(\"%.2f\" % ($VALUE))")
#     if [ $# -eq 3 ] ; then
#         MSGKO="$3"
#     elif [ $# -eq 4 ] ; then
#         MSGKO="$3"
#         CMDKO="$4"
#     fi
#     if [ "$VALUE" = "X" ] ; then
#         COMMENT "⚠ $MSG: $MSGKO [-∞]" && EXIT 0
#     elif [ "$VALUE" = "0" ] ; then
#         COMMENT "⚠ $MSG: $MSGKO"
#     else
#         COMMENT "⚠ $MSG: $MSGKO [-$RVALUE%]"
#     fi
#     GRADE=$(python3 -c "print($GRADE-$RVALUE)")
#     eval $CMDKO
#     return 0
# }

# inputs: [GRADE]
function XEXIT
{
    [ -z "$GRADE" ] && GRADE=0
    [ $# -eq 1 ] && GRADE=$1
    GRADE=$(python3 -c "print(0 if $GRADE < 0 else round($GRADE))")
    GRADE=$(python3 -c "print(100 if $GRADE > 100 else round($GRADE))")
    ECHO "-GRADE" && ECHO "$GRADE%"
    if [ "$MODE" = "EVAL" ] ; then echo "Grade :=>> $GRADE" ; fi
    # if [ "$MODE" = "RUN" ] ; then echo "👉 Use Ctrl+Shift+⇧ / Ctrl+Shift+⇩ to scroll up / down..." ; fi
    exit 0
}

# EOF
