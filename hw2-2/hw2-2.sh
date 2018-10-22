#!/bin/sh

set total
set tar

get_time() {
	cat COURSE_TIME.tmp | sed -n "$1,$1p"
}

get_location() {
	cat COURSE_LOCATION.tmp | sed -n "$1,$1p"
}

get_name() {
	cat COURSE_NAME.tmp | sed -n "$1,$1p"
}

get_info() {
	cat COURSE_INFO.tmp | sed -n "$1,$1p"
}

get_no() {
	cat CURRENT_NO.tmp | sed -n "$1,$1p"
}

get_choice() {
	cat input.tmp | awk -v awk_tar="$1" '{print $(awk_tar)}'
}

init() {
	if [ ! -f course.json ]; then
		curl 'https://timetable.nctu.edu.tw/?r=main/get_cos_list' --data 'm_acy=107&m_sem=1&m_degree=3&m_dep_id=17&m_group=**&m_grade=**&m_class=**&m_option=**&m_crsname=**&m_teaname=**&m_cos_id=**&m_cos_code=**&m_crstime=**&m_crsoutline=**&m_costype=**' > course.json
	fi

	cat course.json | awk 'BEGIN {FS="\",\""} {for(i=2; i<=NF; i++) {print $i}}' | grep "cos_ename" | cut -c13- | sed 's/ /_/g' > COURSE_NAME.tmp
	cat course.json | awk 'BEGIN {FS="\",\""} {for(i=2; i<=NF; i++) {print $i}}' | grep "cos_time" | cut -c12- | awk 'BEGIN {FS="-|,"} {for(i=1; i<=NF; i++) {if ($i ~ /^[1-7]/) {printf "%s", $i}}} {printf "\n"}' > COURSE_TIME.tmp
	cat course.json | awk 'BEGIN {FS="\",\""} {for(i=2; i<=NF; i++) {print $i}}' | grep "cos_time" | cut -c12- | awk 'BEGIN {FS="-|,"} {printf "_@" } {for(i=0; i<NF; i++) {if ($i ~ /^[A-Z]/) {printf "%s,", $i}}} {printf $NF "\n"}' > COURSE_LOCATION.tmp
	
	total=$(echo $(cat COURSE_TIME.tmp | wc -l))

	if [ ! -f COURSE_INFO.tmp ]; then
		touch COURSE_INFO.tmp
		i=1
		while [ $i -le ${total} ]; do
			COURSE_NAME=$(get_name $i)
			COURSE_TIME=$(get_time $i)
			echo "$i ${COURSE_TIME}-${COURSE_NAME}" >> COURSE_INFO.tmp
			i=$(($i+1))
		done
	fi

	if [ ! -f CURRENT_NO.tmp ]; then
	   touch CURRENT_NO.tmp
   	fi	   

	touch VIRTUAL_TABLE.tmp
	touch VIRTUAL_NO.tmp
}

init


set time

to_i() {
	if [ $1 = "M" ]; then time="0"
	elif [ $1 = "N" ]; then time="1"
	elif [ $1 = "A" ]; then time="2"
	elif [ $1 = "B" ]; then time="3"
	elif [ $1 = "C" ]; then time="4"
	elif [ $1 = "D" ]; then time="5"
	elif [ $1 = "X" ]; then time="6"
	elif [ $1 = "E" ]; then time="7"
	elif [ $1 = "F" ]; then time="8"
	elif [ $1 = "G" ]; then time="9"
	elif [ $1 = "H" ]; then time="10"
	elif [ $1 = "Y" ]; then time="11"
	elif [ $1 = "I" ]; then time="12"
	elif [ $1 = "J" ]; then time="13"
	elif [ $1 = "K" ]; then time="14"
	elif [ $1 = "L" ]; then time="15"
	fi
}

to_c() {
	if [ $1 -eq 0 ]; then time="M"
	elif [ $1 -eq 1 ]; then time="N"
	elif [ $1 -eq 2 ]; then time="A"
	elif [ $1 -eq 3 ]; then time="B"
	elif [ $1 -eq 4 ]; then time="C"
	elif [ $1 -eq 5 ]; then time="D"
	elif [ $1 -eq 6 ]; then time="X"
	elif [ $1 -eq 7 ]; then time="E"
	elif [ $1 -eq 8 ]; then time="F"
	elif [ $1 -eq 9 ]; then time="G"
	elif [ $1 -eq 10 ]; then time="H"
	elif [ $1 -eq 11 ]; then time="Y"
	elif [ $1 -eq 12 ]; then time="I"
	elif [ $1 -eq 13 ]; then time="J"
	elif [ $1 -eq 14 ]; then time="K"
	elif [ $1 -eq 15 ]; then time="L"
	fi
}

set CHECK
check() {
	CHECK="TRUE"
	COURSE_TIME=$(get_time $1)

	while [ "${COURSE_TIME}" != "" ]; do
		a=$(echo ${COURSE_TIME} | cut -c1-1)
		COURSE_TIME=$(echo ${COURSE_TIME} | cut -c2-)
		while [ "$(echo ${COURSE_TIME} | grep "^[A-Z]")" != "" ]; do
			para=$(echo ${COURSE_TIME} | cut -c1-1)
			to_i ${para}

			current=$(cat VIRTUAL_TABLE.tmp | sed -n "$(((${time}*7)+$a+1)),$(((${time}*7)+$a+1))p")
			
			if [ "${current}" != "_" ]; then
				CHECK="FALSE"
			fi	
			COURSE_TIME=$(echo ${COURSE_TIME} | cut -c2-)
		done
	done
}

collision() {
	cp TABLE.tmp VIRTUAL_TABLE.tmp
	cp CURRENT_NO.tmp VIRTUAL_NO.tmp

	dialog --title "COLLISION" --exit-label "OK" --textbox COLLISION.tmp 30 50 

	result=$?
	if [ $1 -eq 0 ]; then
		add_course
	elif [ $1 -eq 1 ]; then
		menu
	else
		free_time
	fi	
}

success() {
	cp VIRTUAL_TABLE.tmp TABLE.tmp
	cp VIRTUAL_NO.tmp CURRENT_NO.tmp

	dialog --title "SUCCESS" --ok-label "MENU" --msgbox "Add courses successfully." 10 20
	result=$?
	menu 
}

set_course() {

	choice_cnt=$(cat input.tmp | wc -w)
	SUCCESS="TRUE"

	set_loop=1

	while [ ${set_loop} -le ${choice_cnt} ]; do

		tar=$(get_choice ${set_loop})
		check ${tar}
	
		COURSE_NAME=$(get_name ${tar})
		COURSE_TIME=$(get_time ${tar})
		COURSE_LOCATION=$(get_location ${tar})

	
		if [ "${CHECK}" == "TRUE" ]; then

			echo ${tar} >> VIRTUAL_NO.tmp

			while [ "${COURSE_TIME}" != "" ]; do
				a=$(echo ${COURSE_TIME} | cut -c1-1)
				COURSE_TIME=$(echo ${COURSE_TIME} | cut -c2-)
				while [ "$(echo ${COURSE_TIME} | grep "^[A-Z]")" != "" ]; do
					to_i $(echo ${COURSE_TIME} | cut -c1-1)
					
					cat VIRTUAL_TABLE.tmp | sed -n "1,$(((${time}*7)+$a))p" > tmp.tmp
					echo "${COURSE_NAME}${COURSE_LOCATION}" >> tmp.tmp 
					cat VIRTUAL_TABLE.tmp | sed -n "$(((${time}*7)+$a+2)),150p" >> tmp.tmp
					mv tmp.tmp VIRTUAL_TABLE.tmp
					
					COURSE_TIME=$(echo ${COURSE_TIME} | cut -c2-)
				done
			done
		else
			SUCCESS="FALSE"
			break
		fi
		set_loop=$((${set_loop}+1))
	done	

	if [ ${SUCCESS} = "TRUE" ]; then
	    success
   	else
 		echo "Find a collision while trying to add:" > COLLISION.tmp
		echo "${COURSE_NAME}" >> COLLISION.tmp
	    collision $1 
	fi		
}

set EXIST

check_current() {
	EXIST="FALSE"
	
	n=$(cat CURRENT_NO.tmp | wc -l)
	i=1
	while [ $i -le $n ] || [ $i -eq $n ]; do
		check_no=$(get_no $i)
		if [ ${check_no} -eq $1 ]; then
			EXIST="TRUE"
		fi	
		i=$(($i+1))
	done 
}

add_course() {
	if [ -f COURSE_INFO_LIST.tmp ]; then
		rm COURSE_INFO_LIST.tmp	
	fi

	j=1
	while [ $j -le ${total} ]; do
		check_current $j
		if [ ${EXIST} = "TRUE" ]; then
			echo "$(get_info $j) on" >> COURSE_INFO_LIST.tmp
		else
			echo "$(get_info $j) off" >> COURSE_INFO_LIST.tmp
		fi
		#echo "$j" 
		j=$(($j+1))
	done	
		
	dialog --checklist "ADD COURSE" 15 61 130 \
		$(cat COURSE_INFO_LIST.tmp) 2>input.tmp
	
	result=$?

	
	if [ ${result} -eq 0 ]; then
		
		rm VIRTUAL_NO.tmp
		echo "first_line" > VIRTUAL_TABLE.tmp
		
		i=0
		while [ $i -le 200 ]; do
			echo "_" >> VIRTUAL_TABLE.tmp
			i=$(($i+1))
		done
		
		set_course 0
	else
		menu
	fi
} 

search_course() {

	dialog --title "SEARCH COURSES" --inputbox "Please input key words:" 16 51 2>input.tmp
	result=$?
	SEARCH="$(cat input.tmp)"

	if [ ${result} -eq 255 ]; then
		menu
	fi

	if [ -f SEARCH.tmp ]; then
		rm SEARCH.tmp
		touch SEARCH.tmp
	fi

	for search in ${SEARCH}; do
		cat COURSE_INFO.tmp | grep "${search}" >> SEARCH.tmp 
	done
	
	dialog --title "SEARCH RESULT (OK if you want to add)" --menu "" 15 61 ${total} \
	$(cat SEARCH.tmp | sort -n | uniq | less) 2>input.tmp
	result=$?

	if [ ${result} -eq 0 ]; then
		set_course 1
	fi
	menu
}

set CHECK_TIME
check_time() {
	CHECK_TIME="TRUE"
	COURSE_TIME=$(get_time $1)
	CHECK_TIME_CNT=0

	while [ "${COURSE_TIME}" != "" ]; do
		a=$(echo ${COURSE_TIME} | cut -c1-1)
		COURSE_TIME=$(echo ${COURSE_TIME} | cut -c2-)
		while [ "$(echo ${COURSE_TIME} | grep "^[A-Z]")" != "" ]; do
			para=$(echo ${COURSE_TIME} | cut -c1-1)
			to_i ${para}

			current=$(cat SEARCH_TABLE.tmp | sed -n "$(((${time}*7)+$a+1)),$(((${time}*7)+$a+1))p")
			
			if [ "${current}" = "OK" ]; then
				CHECK_TIME_CNT=$((${CHECK_TIME_CNT}+1))
			fi	
			COURSE_TIME=$(echo ${COURSE_TIME} | cut -c2-)
		done
	done

	if [ ${CHECK_TIME_CNT} -eq ${TIME_CNT} ]; then
		CHECK_TIME="TRUE"
	else
		CHECK_TIME="FALSE"
	fi
}

set TIME_CNT
set_search_time() {
	
	SEARCH_TIME=$1
	TIME_CNT=0
	echo "first_line" > SEARCH_TABLE.tmp
		
	i=0
	while [ $i -le 200 ]; do
		echo "_" >> SEARCH_TABLE.tmp
		i=$(($i+1))
	done

	while [ "${SEARCH_TIME}" != "" ]; do
		a=$(echo ${SEARCH_TIME} | cut -c1-1)
		SEARCH_TIME=$(echo ${SEARCH_TIME} | cut -c2-)
		while [ "$(echo ${SEARCH_TIME} | grep "^[A-Z]")" != "" ]; do
			to_i $(echo ${SEARCH_TIME} | cut -c1-1)
			
			TIME_CNT=$((${TIME_CNT}+1))
			cat SEARCH_TABLE.tmp | sed -n "1,$(((${time}*7)+$a))p" > tmp.tmp
			echo "OK" >> tmp.tmp 
			cat SEARCH_TABLE.tmp | sed -n "$(((${time}*7)+$a+2)),150p" >> tmp.tmp
			mv tmp.tmp SEARCH_TABLE.tmp
			
			SEARCH_TIME=$(echo ${SEARCH_TIME} | cut -c2-)
		done
	done
}

search_time() {

	dialog --title "SEARCH TIME" --inputbox "Please input time:" 16 51 2>input.tmp
	result=$?
	SEARCH="$(cat input.tmp)"

	if [ ${result} -eq 255 ]; then
		menu
	fi

	set_search_time ${SEARCH}

	if [ -f SEARCH.tmp ]; then
		rm SEARCH.tmp
		touch SEARCH.tmp
	fi

	iter=1
	while [ $iter -le ${total} ]; do
		check_time $iter
			if [ ${CHECK_TIME} = "TRUE" ]; then
				COURSE_INFO=$(cat COURSE_INFO.tmp | sed -n "${iter},${iter}p")
				echo "${COURSE_INFO}" >> SEARCH.tmp
			fi 
		iter=$(($iter+1))
	done

	dialog --title "SEARCH RESULT (OK if you want to add)" --menu "" 15 61 ${total} \
	$(cat SEARCH.tmp) 2>input.tmp
	result=$?

	if [ ${result} -eq 0 ]; then
		set_course 1
	fi
	menu

}

free_time() {

	if [ -f SEARCH.tmp ]; then
		rm SEARCH.tmp
		touch SEARCH.tmp
	fi

	i=1
	while [ $i -le ${total} ]; do
		check $i
			if [ ${CHECK} = "TRUE" ]; then
				COURSE_INFO=$(cat COURSE_INFO.tmp | sed -n "${i},${i}p")
				echo "${COURSE_INFO}" >> SEARCH.tmp
			fi 
		i=$(($i+1))
	done
	
	dialog --title "FREE TIME" --menu "" 15 61 ${total} \
	$(cat SEARCH.tmp) 2>input.tmp
	result=$?

	if [ ${result} -eq 0 ]; then
		set_course 2 
	fi
	menu

}

display() {

	SLOT="FALSE"
	WEEKEND="FALSE"	
	dialog --title "TIME SLOT" --yesno "Do you want to include MNXYL?" 10 20
	if [ $? -eq 0 ]; then
		SLOT="TRUE"
	fi 

	dialog --title "WEEKEND" --yesno "Do you want to include Saturday and Sunday?" 10 20
	if [ $? -eq 0 ]; then
		WEEKEND="TRUE"
	fi 

	printf "\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-" > DISPLAY.tmp

	if [ ${WEEKEND} = "TRUE" ]; then
		printf "\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-" >> DISPLAY.tmp
	fi
	printf "\n" >> DISPLAY.tmp 

	printf "   |   Mon   |   Tue   |   Wed   |   Thu   |   Fri   |" >> DISPLAY.tmp
	if [ ${WEEKEND} = "TRUE" ]; then
		printf "   Sat   |   Sun   |" >> DISPLAY.tmp
	fi
	printf "\n" >> DISPLAY.tmp 



	i=0
	while [ $i -le 15 ]; do

		if [ ${SLOT} = "FALSE" ]; then
			if [ $i -eq 0 ] || [ $i -eq 1 ] || [ $i -eq 6 ] || [ $i -eq 11 ] || [ $i -eq 15 ]; then
				i=$(($i+1))	
				continue
			fi
		fi 

		printf "\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-" >> DISPLAY.tmp
		if [ ${WEEKEND} = "TRUE" ]; then
			printf "\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-" >> DISPLAY.tmp
		fi
		printf "\n" >> DISPLAY.tmp 
		
		to_c $i

		j=0
		while [ $j -le 7 ]; do
			Mon=`cat TABLE.tmp | sed -n "$((($i*7)+2)),$((($i*7)+2))p" | cut -c$((($j*7)+1))-$((($j*7)+7))`
			Tue=`cat TABLE.tmp | sed -n "$((($i*7)+3)),$((($i*7)+3))p" | cut -c$((($j*7)+1))-$((($j*7)+7))`
			Wed=`cat TABLE.tmp | sed -n "$((($i*7)+4)),$((($i*7)+4))p" | cut -c$((($j*7)+1))-$((($j*7)+7))`
			Thu=`cat TABLE.tmp | sed -n "$((($i*7)+5)),$((($i*7)+5))p" | cut -c$((($j*7)+1))-$((($j*7)+7))`
			Fri=`cat TABLE.tmp | sed -n "$((($i*7)+6)),$((($i*7)+6))p" | cut -c$((($j*7)+1))-$((($j*7)+7))`
			Sat=`cat TABLE.tmp | sed -n "$((($i*7)+7)),$((($i*7)+7))p" | cut -c$((($j*7)+1))-$((($j*7)+7))`
			Sun=`cat TABLE.tmp | sed -n "$((($i*7)+8)),$((($i*7)+8))p" | cut -c$((($j*7)+1))-$((($j*7)+7))`
			
			if [ ${WEEKEND} = "TRUE" ]; then
				if [ $j -eq 3 ]; then
					printf " %-1s | %-7s | %-7s | %-7s | %-7s | %-7s | %-7s | %-7s |\n" ${time} ${Mon:="_"} ${Tue:="_"} ${Wed:="_"} ${Thu:="_"} ${Fri:="_"} ${Sat:="_"} ${Sun:="_"} >> DISPLAY.tmp
				else
					printf "   | %-7s | %-7s | %-7s | %-7s | %-7s | %-7s | %-7s |\n" ${Mon:="_"} ${Tue:="_"} ${Wed:="_"} ${Thu:="_"} ${Fri:="_"} ${Sat:="_"} ${Sun:="_"} >> DISPLAY.tmp
				fi
			else
				if [ $j -eq 3 ]; then
					printf " %-1s | %-7s | %-7s | %-7s | %-7s | %-7s |\n" ${time} ${Mon:="_"} ${Tue:="_"} ${Wed:="_"} ${Thu:="_"} ${Fri:="_"} >> DISPLAY.tmp
				else
					printf "   | %-7s | %-7s | %-7s | %-7s | %-7s |\n" ${Mon:="_"} ${Tue:="_"} ${Wed:="_"} ${Thu:="_"} ${Fri:="_"} >> DISPLAY.tmp
				fi
			fi
			j=$(($j+1))
		done
		i=$(($i+1))
	done
	
	printf "\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-" >> DISPLAY.tmp
	if [ ${WEEKEND} = "TRUE" ]; then
		printf "\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-" >> DISPLAY.tmp
	fi
	printf "\n" >> DISPLAY.tmp 

	dialog --textbox DISPLAY.tmp 50 80
	result=$?
	menu
}

menu() {
	dialog --title "MENU" --cancel-label "EXIT" --menu "" 16 51 5 \
	"1" "Display Timetable" \
	"2" "Add Course" \
	"3" "Search Courses" \
	"4" "Free Time" \
	"5" "Search Time" \
	2> input.tmp
	result=$?
	tar=$(cat input.tmp)
	
	if [ ${result} -eq 0 ]; then
		case ${tar} in
			1)
				display
			;;
			2)
				add_course
			;;
			3)
				search_course
			;;
			4)
				free_time
			;;
			5)
				search_time
			;;
		esac
	else
		exit
	fi
}

clear() {
	echo "first_line" > TABLE.tmp
		
	i=0
	while [ $i -le 200 ]; do
		echo "_" >> TABLE.tmp
		i=$(($i+1))
	done

	cp TABLE.tmp VIRTUAL_TABLE.tmp
}

welcome() {

	if [ -f TABLE.tmp ]; then
		dialog --title "WELCOME BACK" --yesno "Do you want to restore your last session?" 10 20
		result=$?
		if [ ! ${result} -eq 0 ]; then
			clear
		fi	
	else
		clear
	fi
	menu
}

welcome
