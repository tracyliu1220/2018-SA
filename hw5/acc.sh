#!/bin/sh

group_name=$1
account_file=$2

get_acc_info() {
	cat ${account_file} | sed -n "$1,$1p"
}

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

#sudo echo $(sudo cat /etc/master.passwd | tail -n ${account_cnt}) >> /var/yp/src/master.passwd

i=1
while [ $i -le ${account_cnt} ]; do
	account_info=$(get_acc_info $i)
	user_name=$(echo ${account_info} | awk 'BEGIN {FS=", "} {print $1}')

	sudo pw userdel ${user_name}
	i=$(($i + 1))
done
