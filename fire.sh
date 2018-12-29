#!/bin/ksh
# Completely inspired by: http://fabiensanglard.net/doom_fire_psx/

WIDTH=$(tput cols)
HEIGHT=$(tput lines)
BOTTOMROW=$((HEIGHT-1))

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
tput clear

# initialise
j=$((HEIGHT*WIDTH))
i=$((j-WIDTH))
while [[ $i -lt $j ]]
do
    state[$i]=7
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
while [[ $x -lt $WIDTH ]]
do
    tput cup $HEIGHT $x
    printf "${DRAW[7]}"
    x=$((x+1))
done

# run
while [[ true ]]
do
    x=0
    while [[ $x -lt $WIDTH ]]
    do
        y=$((HEIGHT-1))
        while [[ $y -ge 1 ]]
        do
            i=$((y * WIDTH + x))
            
            # spread fire to weighted random row above
            rand=$(((RANDOM * 3) & 3))
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
                    tput cup $y $x
                    printf "${DRAW[state[i]]}"
                fi
            fi
        
            stateDoubleBuffer[$i]=${state[i]}
            y=$((y-1))
        done
        x=$((x+1))
    done
done
