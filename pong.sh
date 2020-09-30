#!/usr/bin/env bash
#
# very simple pong thing
#
# input-fetching inspired by
# https://github.com/codedust/bong/blob/master/bong.sh
# (other bits were written before discovering that one)

WIDTH=$(tput cols)
HEIGHT=$(tput lines)

MARGIN_LEFT=1
MARGIN_RIGHT=$((WIDTH - 1 - MARGIN_LEFT))
MARGIN_TOP=1
MARGIN_BOTTOM=$((HEIGHT - 1 - MARGIN_TOP))

# margin illustration:
# 
#     0  1  2  --- -3 -2 -1
#  0 ██████████████████████
#  1 ██████████████████████
#  2 █████            █████
#  | █████            █████
#  3 █████            █████
# -2 ██████████████████████
# -1 ██████████████████████
#
# and so, the margins are coordinate-adjusted.

BALL_X=$((WIDTH / 2))
BALL_Y=$((HEIGHT / 2))

DELTA_X=1
DELTA_Y=1

BAT_Y=$BALL_Y
PREV_BAT_Y=$BAT_Y
BAT_SIZE=$((HEIGHT / 5 + 1))

CLEAR_POINTS=()

SCORE=0

init() {
    clear
    # dump of relevant terminfo strs:
    # cup <row> <col> -> move cursor to row,col
    # not cvvis but cnorm, that's good.
    # invisible cursor
    tput civis

    # set input time and minimum chars read to 0
    # (need icanon for that)
    # -> this lets us handle single-key inputs fine
    # while keeping user's input hidden with -echo
    stty -echo -icanon time 0 min 0
}

quit() {
    tput clear
    tput cvvis # Show cursor again!
    stty sane # Reset temporary effects
    # all done in reset but that's too heavy
    exit
}

centered_text() {
    length=${#1}
    tput cup $((HEIGHT / 2)) $((WIDTH / 2 - length / 2))
    echo -n "$1"
}

welcome() {
    tput clear
    centered_text "this is PONG"
    sleep .7
    centered_text "Your bat is $BAT_SIZE chars high"
    sleep .7
    tput clear
}

game_over() {
    tput clear
    centered_text "game over pal"
    sleep .7
    centered_text "You got $((SCORE / 2)) points!"
    sleep .7
    quit
}

draw_at() {
    tput cup "$1" "$2"
    echo -n "$3"
}

clear_screen() {
    # checks to prevent flickering
    if [[ "$PREV_BAT_Y" -eq "$BAT_Y" ]]
    then # same as last time, don't bother
        # shellcheck disable=2086
        draw_at ${CLEAR_POINTS[0]} ' ' # only draw ball
        return
    elif [[ "$PREV_BAT_Y" -lt "$BAT_Y" ]]
    then # moving down
        unset CLEAR_POINTS[2]
        unset CLEAR_POINTS[4]
    else # moving up
        unset CLEAR_POINTS[1]
        unset CLEAR_POINTS[3]
    fi

    for point in "${CLEAR_POINTS[@]}"
    do
        # shellcheck disable=2086
        draw_at $point ' '
    done
}

remember_points() {
    # remember what coords to clear next time
    # if [[ "$PREV_BAT_Y" -eq "$BAT_Y" ]]
    # then
    #     CLEAR_POINTS=("$BALL_Y $BALL_X")
    # else
        CLEAR_POINTS=(
            "$BALL_Y $BALL_X"
            "$BAT_START $MARGIN_LEFT"
            "$BAT_END $MARGIN_LEFT"
            "$BAT_START $MARGIN_RIGHT"
            "$BAT_END $MARGIN_RIGHT"
        )
    # fi
}

draw() {
    clear_screen

    # draw ball
    draw_at $BALL_Y $BALL_X 'O'

    # 4 <- bat_y - bat_size / 2 = 4
    # 5
    # 6 <- bat_y = e.g. 13 / 2
    # 7
    # 8 <- bat_start + bat_size = 8
    BAT_START=$((BAT_Y - BAT_SIZE / 2))
    BAT_END=$((BAT_START + BAT_SIZE))
    for i in $(seq $BAT_START $BAT_END)
    do
        draw_at "$i" $MARGIN_LEFT '┃'
        draw_at "$i" $MARGIN_RIGHT '┃'
    done

    remember_points
}

handle_input() {
    PREV_BAT_Y="$BAT_Y" # remember old y

    case "$(cat --show-nonprinting)" in
        '^[[A'|k) # up
            (( BAT_START > MARGIN_TOP && BAT_Y-- ))
            ;;
        '^[[B'|j) # down
            (( BAT_END < MARGIN_BOTTOM && BAT_Y++ ))
            ;;
        q)
            quit
            ;;
        *)
            ;;
    esac
}

caught_by_bat() {
    (( BALL_Y > BAT_START - 1 && BALL_Y < BAT_END + 1 ))
}

update_ball() {
    # game over on _actual_ outball
    (( BALL_X < MARGIN_LEFT - 1 || BALL_X > MARGIN_RIGHT + 1 )) && game_over
    # Check if ball is outside horizontal bounds
    # - then, is it caught by any bat?
    if (( BALL_X >= MARGIN_RIGHT - 1 ))
    then
        if caught_by_bat
        then
            DELTA_X=-1
            SCORE=$((SCORE+1))
        else
            DELTA_X=1
        fi
    elif (( BALL_X <= MARGIN_LEFT + 1 ))
    then
        if caught_by_bat
        then
            DELTA_X=1
            SCORE=$((SCORE+1))
        else
            DELTA_X=-1
        fi
    fi

    # Bounce back when hitting top/bottom
    if (( BALL_Y >= MARGIN_BOTTOM ))
    then
        DELTA_Y=-1
    elif (( BALL_Y <= MARGIN_TOP ))
    then
        DELTA_Y=1
    fi

    # Apply deltas
    (( BALL_Y += DELTA_Y ))
    (( BALL_X += DELTA_X ))
}

main_loop() {
    handle_input
    update_ball
    draw
    sleep 0.06
}

init
welcome

while :
do
    main_loop
done

quit # just in case?
