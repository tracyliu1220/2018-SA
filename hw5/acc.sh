#!/bin/sh

group_name=$1
account_file=$2

get_acc_info() {
	cat ${account_file} | sed -n "$1,$1p"
}

add_account() {
	account_cnt=$(cat ${account_file} | wc -l)
	
	sudo pw groupadd ${group_name}
	
	i=1
	while [ $i -le ${account_cnt} ]; do
		account_info=$(get_acc_info $i)
	
		user_name=$(echo ${account_info} | awk 'BEGIN {FS=", "} {print $1}')
		full_name=$(echo ${account_info} | awk 'BEGIN {FS=", "} {print $2}')
	
		sudo pw useradd ${user_name} -w random -d /net/home -c "${full_name}"
	
		i=$(($i + 1))
	done
	
	i=1
	while [ $i -le ${account_cnt} ]; do
		account_info=$(get_acc_info $i)
		user_name=$(echo ${account_info} | awk 'BEGIN {FS=", "} {print $1}')
		
		echo $(sudo cat /etc/master.passwd | grep ${user_name}) >> /var/yp/src/master.passwd
	
		sudo pw userdel ${user_name}
		i=$(($i + 1))
	done
	
	echo $(sudo cat /etc/group | grep ${group_name}) >> /var/yp/src/group
	sudo pw groupdel ${group_name}
	
	cd /var/yp
	make
	sudo yppush -h storage passwd.byname
	sudo yppush -h storage passwd.byuid
	
	sudo yppush -h storage group.byname
	sudo yppush -h storage group.bygid
	
	sudo yppush -h storage master.passwd.byname
	sudo yppush -h storage master.passwd.byuid
}

if [ `hostname` == "account" ]; then
	add_account $1 $2
fi
