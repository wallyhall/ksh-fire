#!/bin/ksh
# Completely inspired by: http://fabiensanglard.net/doom_fire_psx/

WIDTH=$(tput cols)
HEIGHT=$(tput lines)
BOTTOMROW=$((HEIGHT-1))

case $1 in
    +([1-7]))
        TEMP=$1
    ;;
    *)
        TEMP=7
    ;;
esac

DRAW[0]=" "
DRAW[1]="\033[38;5;196m."
DRAW[2]="\033[38;5;202m:"
DRAW[3]="\033[38;5;208m;"
DRAW[4]="\033[38;5;214m|"
DRAW[5]="\033[38;5;220mM"
DRAW[6]="\033[38;5;226mM"
DRAW[7]="\033[38;5;15m#"

trap "reset; exit" INT

echo -e "\033[?25l"
printf "\033[2J"

# initialise
j=$((HEIGHT*WIDTH))
i=$((j-WIDTH))
while [[ $i -lt $j ]]
do
    state[$i]=$TEMP
    i=$((i+1))
done

j=$((HEIGHT-1))
y=0
while [[ $y -lt $j ]]
do
    x=0
    while [[ $x -lt $WIDTH ]]
    do
        i=$((y*WIDTH+x))
        state[$i]=0
        x=$((x+1))
    done
    y=$((y+1))
done

# draw the initial bottom line (all hottest)

x=0
printf "\033[${HEIGHT};0H"
while [[ $x -lt $WIDTH ]]
do
    printf "${DRAW[${TEMP}]}"
    x=$((x+1))
done

# run
while [[ true ]]
do
    lastFrameDrawn=$(date +%s%N)
    frame=""
    x=0
    while [[ $x -lt $WIDTH ]]
    do
        y=$((HEIGHT - 1))
        while [[ $y -ge 1 ]]
        do
            i=$((y * WIDTH + x))

            # spread fire to weighted random row above
            rand=$(((RANDOM * 5) & 3))
            j=$((i - (WIDTH * rand)))
            # boundary check
            if [[ $j -ge 0 ]]
            then
                # decay by a weighted random amount
                randDecay=$((rand & 1))
                state[j]=$((state[i] - randDecay))

                # boundary check
                if [[ $state[$j] -lt 0 ]]
                then
                    state[$j]=0
                fi
            fi

            if [[ $y -lt $BOTTOMROW ]]
            then
                if [[ $stateDoubleBuffer[$i] -ne $state[$i] ]]
                then
                    yAnsiOffset=$((y+1))
                    xAnsiOffset=$((x+1))
                    frame="${frame}\033[${yAnsiOffset};${xAnsiOffset}H"
                    frame="${frame}${DRAW[state[i]]}"
                fi
            fi

            stateDoubleBuffer[$i]=${state[i]}
            y=$((y-1))
        done

        x=$((x+1))
    done

    # draw frame line to console
    printf "$frame"

    thisFrameDrawn=$(date +%s%N)
    frameDrawTime=$(((thisFrameDrawn - lastFrameDrawn) / 1000000))
    printf "\033[1;1H\033[38;5;106m${frameDrawTime}ms  "
    sleepTime=$((100 - frameDrawTime))
    if [[ $sleepTime -gt 0 ]]
    then
        sleepTimeFloat="$(printf "0.%03d" $sleepTime)"
        sleep "$sleepTimeFloat"
    fi
done
