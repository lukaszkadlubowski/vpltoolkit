#!/bin/bash

### BASIC ECHO ROUTINES ###

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

### BASIC TRACE ROUTINES ###

# echo a command (in green) and execute it (RUN mode only)
function RTRACE
{
    [ "$MODE" != "RUN" ] && "Error: function RTRACE only available in RUN mode!" && exit 0
    ECHOGREEN "$ $@"
    bash -c "$@"
    RET=$?
    # if [ $ONLINE -eq 0 ] ; then
    if [ $RET -eq 0 ] ; then
        ECHOBLUE "✓ Success."
    else
        ECHORED "⚠ Failure!"
    fi
    # fi
    return $RET
}

# echo a command in execution window and execute it (EVAL mode only)
function TRACE
{
    [ "$MODE" != "EVAL" ] && "Error: function TRACE only available in EVAL mode!" && exit 0
    echo "Trace :=>>$ $@"
    bash -c "$@" |& sed -e 's/^/Output :=>>/;'
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
    bash -c "$@" |& sed -e 's/^/>/;' # preformated output
    RET=${PIPESTATUS[0]}  # return status of first piped command!
    echo "--|>"
    return $RET
}

### MISC ###

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

### GRADE ###

# inputs: [GRADE]
function EXIT
{
    [ -z "$GRADE" ] && GRADE=0
    [ $# -eq 1 ] && GRADE=$1
    (( GRADE < 0 )) && GRADE=0
    (( GRADE > 100 )) && GRADE=100
    ECHO && ECHO "-GRADE" && ECHO "$GRADE / 100"
    if [ "$MODE" = "EVAL" ] ; then echo "Grade :=>> $GRADE" ; fi
    # if [ "$MODE" = "RUN" ] ; then echo "Use Ctrl+Shift+⇧ / Ctrl+Shift+⇩ to scroll up / down..." ; fi
    exit 0
}

# inputs: MSG VALUE [MSGOK] [CMDOK]
# return 0
function BONUS
{
    local MSG="$1"
    local VALUE="$2"
    local MSGOK="success."
    local CMDOK=""
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
        COMMENT "✓ $MSG: $MSGOK [+$VALUE]"
    fi
    GRADE=$((GRADE+VALUE))
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
        COMMENT "⚠ $MSG: $MSGKO [-$VALUE]"
    fi
    GRADE=$((GRADE-VALUE))
    eval $CMDKO
    return 0
}

# inputs: MSG VALUEBONUS VALUEMALUS [MSGOK MSGKO] [CMDOK CMDKO] and $?
# return: $?
function EVAL
{
    local RET=$?
    [ "$MODE" != "EVAL" ] && "Error: function EVAL only available in EVAL mode!" && exit 0
    local MSG="$1"
    local VALUEBONUS="$2"
    local VALUEMALUS="$3"
    local MSGOK="success."
    local MSGKO="failure!"
    local CMDOK=""
    local CMDKO=""
    if [ $# -eq 5 ] ; then
        MSGOK=$4
        MSGKO=$5
        elif [ $# -eq 7 ] ; then
        MSGOK=$4
        MSGKO=$5
        CMDOK=$6
        CMDKO=$7
    fi
    if [ $RET -eq 0 ] ; then
        BONUS "$MSG" $VALUEBONUS "$MSGOK" "$CMDOK"
    else
        MALUS "$MSG" $VALUEMALUS "$MSGKO" "$CMDKO"
    fi
    return $RET
}


# inputs: MSG [MSGOK] [CMDOK]
# return 0
function RBONUS
{
    [ "$MODE" != "RUN" ] && "Error: function REVAL only available in RUN mode!" && exit 0
    local MSG="$1"
    local MSGOK="success."
    local CMDOK=""
    if [ $# -eq 2 ] ; then
        MSGOK="$2"
        elif [ $# -eq 3 ] ; then
        MSGOK="$2"
        CMDOK="$3"
    fi
    ECHOBLUE "✓ $MSG: $MSGOK"
    eval "$CMDOK"
    return 0
}

# inputs: MSG [MSGOK] [CMDKO]
# return 0
function RMALUS
{
    [ "$MODE" != "RUN" ] && "Error: function REVAL only available in RUN mode!" && exit 0
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
    [ "$MODE" != "RUN" ] && "Error: function REVAL only available in RUN mode!" && exit 0
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

# EOF
