#!/usr/bin/env bash

WIDTH=$(tput cols)
HEIGHT=$(tput lines)

#((HEIGHT--))

BALL_X=3
BALL_Y=8

DELTA_X=1
DELTA_Y=1

function frame() {
	local s=''
	for (( i = 0; i < WIDTH; i++ ))
	do
		s+='#'
	done
	echo -n $s
}

# had to go i -> j
function spacing() {
	local s='#'
	for (( j = 0; j < WIDTH - 2; j++ ))
	do
		s+=' '
	done
	echo "${s}#"
}

function ball_line() {
	local s='#'
	for (( j = 0; j < BALL_X; j++ ))
	do
		s+=' '
	done
	s+='O'
	for (( j = BALL_X + 1; j < WIDTH - 2; j++ ))
	do
		s+=' '
	done
	echo "${s}#"
}

function draw() {
	# clear
        # start in upper left corner
        tput cup 0 0

	frame
        echo

	for (( i = 0; i < BALL_Y; ++i ))
	do
		spacing
	done

	ball_line

	for (( i = (BALL_Y + 1); i < (HEIGHT - 2); i++ ))
	do
		spacing
	done

	frame
}

function update_ball() {
	if (( BALL_X == WIDTH - 3 ))
	then
		DELTA_X=-1
	elif (( BALL_X == 0 ))
	then
		DELTA_X=1
	fi

	if (( BALL_Y == HEIGHT - 3 ))
	then
		DELTA_Y=-1
	elif (( BALL_Y == 0 ))
	then
		DELTA_Y=1
	fi

	(( BALL_Y += DELTA_Y ))
	(( BALL_X += DELTA_X ))
}

main_loop() {
	draw
	sleep 0.1
	update_ball
}

while echo 1 &> /dev/null
do
	main_loop
done

