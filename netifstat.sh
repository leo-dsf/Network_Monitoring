#!/bin/bash

	# Functions
	function parser () {
	    iface=$2;   # interface
	    t=$1        # time
	    if [ $# -eq 1 ];then
	        # read -a -> create array  
			# read -r -> Backslash does not act as an escape character
			# netstat -ie -> displays network statistics
	        # egrep -v ---> filter and invert selection (egrep = grep -E) -> it will remove the whole line
	        # cut -f1 -d":" -> Removing the rest of the line when ":" is found 
			# sed 's/^ *//g' -> Removing white space to the left and right from all lines with regex expression
			# sed 's/.*bytes//g' -> Remove everything from left to right until find word "bytes" -> Also removes bytes
			# awk '{print $1, $4}' -> print 1st and 4th columns 
			read -r -a array <<< $(netstat -ie | egrep -v "Kernel|inet|ether|RX error|TX errors|device|loop|1d" | cut -f1 -d":" | sed 's/.*bytes//g' | sed 's/^ *//g' | awk '{print $1, $4}')
	        # This array has 3 * n elements -> n = number of interfaces; 3 = number of elements for "line"; Increment by 3 = nextLine
			for ((i=0;i<=${#array[@]}-1;i+=3));do
	            netif=${array[i]}		# Interface
	            ti=${array[i+1]}		# inicial TX
	            ri=${array[i+2]}		# inicial RX
	            sleep $t
	            read -r -a final_array <<< $(netstat -ie | egrep -v "Kernel|inet|ether|RX error|TX errors|device|loop|1d" | cut -f1 -d":" | sed 's/.*bytes//g' | sed 's/^ *//g' | grep -w 'lo' | awk '{print $1, $4}')
	            tf=${final_array[i+1]}	# final TX  
	            rf=${final_array[i+2]}	# final RX
	            tx=$((tf - ti))			# TX = TXf - TXi 
	            rx=$((rf - ri))			# RX = RXf - RXi
				# Using awk -> This is needed if we want to print decimal values 
				# awk -va=$tx creates a new variable with $tx as value
	            trate=$(echo |awk -va=$tx -vb=$t '{ print a/b}') 
	            rrate=$(echo |awk -va=$rx -vb=$t '{ print a/b}')
	        	if [ $i -eq "0" ];then
	        		printf "%7s %5s %5s %5s %5s\n" NETIF TX RX TRATE RRATE
	        	fi
	        	printf "%7s %5s %5s %5s %5s\n" $netif $tx $rx $trate $rrate
	        done
	    elif [[ "$iface" != "" ]];then
            read -r -a array <<< $(netstat -ie | egrep -v "Kernel|inet|ether|RX error|TX errors|device|loop|1d" | cut -f1 -d":" | sed 's/.*bytes//g' | sed 's/^ *//g' | awk '{print $1, $4}')
	        # This array has 3 * n elements -> n = number of interfaces; 3 = number of elements for "line"; Increment by 3 = nextLine
			for ((i=0;i<=${#array[@]}-1;i+=3));do
	            netif=${array[i]}
	            ti=${array[i+1]}
	            ri=${array[i+2]}
	            sleep $t
	            read -r -a final_array <<< $(netstat -ie | egrep -v "Kernel|inet|ether|RX error|TX errors|device|loop|1d" | cut -f1 -d":" | sed 's/.*bytes//g' | sed 's/^ *//g' | awk '{print $1, $4}')
	            tf=${final_array[i+1]}  
	            rf=${final_array[i+2]}
	            tx=$((tf - ti))
	            rx=$((rf - ri))
	            trate=$(echo |awk -va=$tx -vb=$t '{ print a/b}') 
	            rrate=$(echo |awk -va=$rx -vb=$t '{ print a/b}')
	        	if [ $i -eq "0" ];then
	        		printf "%7s %5s %5s %5s %5s\n" NETIF TX RX TRATE RRATE
	        	fi
	        	if [[ "$netif" = "$iface" ]];then
	        		printf "%7s %5s %5s %5s %5s\n" $netif $tx $rx $trate $rrate
            	fi
	        done   
	    fi
	}
	# End functions
	
# Validating Arguments
if [ $# -eq 1 ] || [ "$1" = "-p" ] || [[ "$1" = "-t" ]] || [[ "$1" = "-r" ]] || [[ "$1" = "-T" ]] || [[ "$1" = "-R" ]] || [[ "$1" = "-v" ]] || [[ "$1" = "-c" ]] || [[ "$1" = "-l" ]] || [[ "$1" = "-b" ]] || [[ "$1" = "-k" ]] || [[ "$1" = "-m" ]];then
	echo "please wait ..."
	# Método tempo (sem parametros além de um int)
	if [ $# -eq 1 ];then
	    if ! [[ "$1" =~ ^[0-9]+$ ]]   # Se $1 for um número chama a função parser como parametro de entrada $1
	    then
	    	echo "Invalid argument -> netifstat.sh [time] time is an int"     
	    else
	    	parser $1
	    fi
	fi
	
	# Métodp -p n --> Número de interfaces --> Array composta por multiplos de 3 por isso é só fazer multiplos de 3 consoante o p de entrada
	#$1 = -p ; $2 = n ; $3 = t
	if [ $1 == "-p" ]; then
	    if [ $# -eq 3 ]; then 
	    	t=$3        #time
	    	read -r -a array <<< $(netstat -ie | egrep -v "Kernel|inet|ether|RX error|TX errors|device|loop|1d" | cut -f1 -d":" | sed 's/.*bytes//g' | sed 's/^ *//g' | awk '{print $1, $4}')
	    	if [[ $2 -le $((${#array[@]} / 3)) ]];then # if n_interfaces <= n_interfaces da array: length(array)/3 = n interfaces
	    		for ((i=0;i<=($2*3)-1;i+=3));do # this cicle ends when $2 interfaces has been printed
	    			netif=${array[i]}
	    			ti=${array[i+1]}
	    			ri=${array[i+2]}
	    			sleep $t
	    			read -r -a final_array <<< $(netstat -ie | egrep -v "Kernel|inet|ether|RX error|TX errors|device|loop|1d" | cut -f1 -d":" | sed 's/.*bytes//g' | sed 's/^ *//g' | awk '{print $1, $4}')
	    			tf=${final_array[i+1]}
	    			rf=${final_array[i+2]}
	    			tx=$((tf - ti))
	    			rx=$((rf - ri))
	    			trate=$(echo |awk -va=$tx -vb=$t '{ print a/b}') #Using awk to calculate the rates; -va declares variable a etc
	    			rrate=$(echo |awk -va=$rx -vb=$t '{ print a/b}')
	    			if [ $i -eq "0" ];then
	    				printf "%7s %5s %5s %5s %5s\n" NETIF TX RX TRATE RRATE
	    			fi
	    			printf "%7s %5s %5s %5s %5s\n" $netif $tx $rx $trate $rrate
	    		done
	    	else
	    		echo "Invalid number of interfaces"
	    	fi
	    else
	    	echo "Invalid number of arguments -> netifstat.sh -p [n interface] [time]"
	    fi
	fi
	
	# Método -t sort TX || -r sort RX || -T sort trate || -R sort rrate || -v reverse order
	if [[ "$1" = "-t" ]] || [[ "$1" = "-r" ]] || [[ "$1" = "-T" ]] || [[ "$1" = "-R" ]] || [[ "$1" = "-v" ]];then
	    if [[ "$2" =~ ^[0-9]+$ ]];then # if $2 is a number -> This is a regex expression
	    	declare -A map 	# Declare associative array map to store keys and respective info
	    	t=$2        	#time
	    	read -r -a array <<< $(netstat -ie | egrep -v "Kernel|inet|ether|RX error|TX errors|device|loop|1d" | cut -f1 -d":" | sed 's/.*bytes//g' | sed 's/^ *//g' | awk '{print $1, $4}')
	    	for ((i=0;i<=${#array[@]}-1;i+=3));do
	    		netif=${array[i]}
	    		ti=${array[i+1]}
	    		ri=${array[i+2]}
	    		sleep $t
	    		read -r -a final_array <<< $(netstat -ie | egrep -v "Kernel|inet|ether|RX error|TX errors|device|loop|1d" | cut -f1 -d":" | sed 's/.*bytes//g' | sed 's/^ *//g' | awk '{print $1, $4}')
	    		tf=${final_array[i+1]}
	    		rf=${final_array[i+2]}
	    		tx=$((tf - ti))
	    		rx=$((rf - ri))
	    		trate=$(echo |awk -va=$tx -vb=$t '{ print a/b}') 
	    		rrate=$(echo |awk -va=$rx -vb=$t '{ print a/b}')
	    		c=$(echo | awk -va=$i -vc=100 '{ print a/c}') # Creating increment -> This will allow to add new values to array even if keys are equal
	    		# Creating map with tx||rx||trate||rrate || iface as keys
				# [key] = "string" -> [iface] = "netif tx rx trate rrate"
	    		case $1 in
	    	    -t)
	    	        if [[ " ${map[@]} " =~ " ${tx} " ]];then #--> checking if value exists in array; if values exists increment it 
	    	        	key=$(echo | awk -va=$tx -vc=$c '{ print a+c}')
	    	        	map[$key]="$netif $tx $rx $trate $rrate"
	    	        else
	    	        	map[$tx]="$netif $tx $rx $trate $rrate"
	    	        fi
	    	        ;;
	    	    -r)
	    	        if [[ " ${map[@]} " =~ " ${rx} " ]];then
	    	        	key=$(echo | awk -va=$rx -vc=$c '{ print a+c}')
	    	        	map[$key]="$netif $tx $rx $trate $rrate"
	    	        else
	    	        	map[$tx]="$netif $tx $rx $trate $rrate"
	    	        fi
	    	        ;;
	    	    -T)
	    	        if [[ " ${map[@]} " =~ " ${trate} " ]];then
	    	        	key=$(echo | awk -va=$trate -vc=$c '{ print a+c}')
	    	        	map[$key]="$netif $tx $rx $trate $rrate"
	    	        else
	    	        	map[$trate]="$netif $tx $rx $trate $rrate"
	    	        fi
	    	        ;;
	    	    -R)
	    	        if [[ " ${map[@]} " =~ " ${rrate} " ]];then
	    	        	key=$(echo | awk -va=$rrate -vc=$c '{ print a+c}')
	    	        	map[$key]="$netif $tx $rx $trate $rrate"
	    	        else
	    	        	map[$rrate]="$netif $tx $rx $trate $rrate"
	    	        fi
	    	        ;;
	    	    -v)
	    	        map[$i]="$netif $tx $rx $trate $rrate"
	    	        ;;
	    		esac
	    		if [ $i -eq "0" ];then
	    			printf "%7s %5s %5s %5s %5s\n" NETIF TX RX TRATE RRATE 
	    		fi
	    	done
	    	# Isto cria um array com as sorted keys e depois dá print da array normal a partir da ordem da array das sorted keys
	    	declare -a keys #->Declaring array 
	    	for key in ${!map[@]};do
	    	    keys+=("$key")
	    	done
	    	IFS=$'\n' #--> Delilimter = \n -> Importante porque o sort faz sort por linha
	    	sorted=($(sort -r<<<"${keys[*]}")) #--> criar sorted com keys -> sort em reverse order (-r)
	    	for key in "${sorted[@]}"; do
	    	    IFS=' ' #new delimiter = ' '
	    	    read -a line_arr <<< ${tst[$key]} #Creating array in sorted order
	    	    printf "%7s %5s %5s %5s %5s\n" ${line_arr[0]} ${line_arr[1]} ${line_arr[2]} ${line_arr[3]} ${line_arr[4]}

	    	done
	    else
	    	echo "Invalid arguments netifstat.sh [-t/-r/-T/-R/-v] [time]"
	    fi
	    
	fi
	
	#Metodo -c "string" "time"
	if [[ "$1" = "-c" ]];then
	    if [ "$2" != "" ];then
	        read -d -r -a interfaces <<<  $(netstat -i | egrep -v "Iface|Kernel" | awk '{print $1}')
	        for element in ${interfaces[@]}
	        do  
	            if [[ $element =~ ^$2 ]]; then
	                parser $3 $element
	            fi
	        done
	    else
	    printf "%s " Invalid Argument: $2
	    fi
	fi
	
	# Método -l time --> Repete de t em t --> falta adicioonar colunas extra
	# Implementing a storing array, this enables the cumulative sum to be printed
	if [[ "$1" = "-l" ]]; then
	    if ! [[ "$2" =~ ^[0-9]+$ ]]
	    then
	        echo "Invalid Argument"
	    else
	        c=0 #->Counter
	        t=$2 #->Time
	        while :
	        do
	            read -r -a array <<< $(netstat -ie | egrep -v "Kernel|inet|ether|RX error|TX errors|device|loop|1d" | cut -f1 -d":" | sed 's/.*bytes//g' | sed 's/^ *//g' | awk '{print $1, $4}')
	            for ((i=0;i<=${#array[@]}-1;i+=3));do
	                netif=${array[i]}
	                ti=${array[i+1]}
	                ri=${array[i+2]}
	                sleep $t
	                read -r -a final_array <<< $(netstat -ie | egrep -v "Kernel|inet|ether|RX error|TX errors|device|loop|1d" | cut -f1 -d":" | sed 's/.*bytes//g' | sed 's/^ *//g' | awk '{print $1, $4}')
	                tf=${final_array[i+1]}  
	                rf=${final_array[i+2]}
	                tx=$((tf - ti))
	                rx=$((rf - ri))
	                trate=$(echo |awk -va=$tx -vb=$t '{ print a/b}') 
	                rrate=$(echo |awk -va=$rx -vb=$t '{ print a/b}')
	                #Creating array to get new values
	                declare -A old_array
	                old_array[$netif]="$tx, $rx, $trate, $rrate, $txtot, $rxtot"
	            done
	            sleep $t
	            echo 
	            #Creating array to store old values
	            declare -A store_array
	            if [[ $c -eq "0" ]];then	#If it is the first time it prints values
	                printf "%7s %5s %5s %5s %5s %5s %5s\n" NETIF TX RX TRATE RRATE TXTOT RXTOT
	                for key in ${!old_array[@]}
	                do
	                	IFS=', '
	                	read -r -a  info <<< ${old_array[$key]}
	                	txtot=$((${info[4]} + ${info[0]}))
	                	rxtot=$((${info[5]} + ${info[1]}))
	                	#Print new values 
	                	printf "%7s %5s %5s %5s %5s %5s %5s\n" $key ${info[0]} ${info[1]} ${info[2]} ${info[3]} $txtot $rxtot
	                	#Store new values
	                	store_array[$key]="${info[0]},${info[1]},${info[2]},${info[3]},$txtot,$rxtot"
	                done
	                unset IFS
	            else
	                printf "%7s %5s %5s %5s %5s %5s %5s\n" NETIF TX RX TRATE RRATE TXTOT RXTOT
	                #Accessing stored values to add new values -> ! is used to access the keys
	                for key in ${!store_array[@]}
	                do
						# Spliting string stored in key from store_array and create new array with info
	                	IFS=', '
	                	read -r -a  info <<< ${store_array[$key]}
	                	txtot=$((${info[4]} + ${info[0]}))
	                	rxtot=$((${info[5]} + ${info[1]}))
	                	#Print new values
	                	printf "%7s %5s %5s %5s %5s %5s %5s\n" $key ${info[0]} ${info[1]} ${info[2]} ${info[3]} $txtot $rxtot
	                	#Store new values
	                	store_array[$key]="${info[0]},${info[1]},${info[2]},${info[3]},$txtot,$rxtot"
	                done
	                unset IFS
	            fi
	            let c++ 
	        done
	    fi
	fi
	
	#Método -b || -k || -m --> Transforma em bytes em vez de packets
	if [[ "$1" = "-b" ]] || [[ "$1" = "-k" ]] || [[ "$1" = "-m" ]];then
        read -r -a array <<< $(netstat -ie | egrep -v "Kernel|inet|ether|RX error|TX errors|device|loop|1d" | cut -f1 -d":" | sed 's/.*bytes//g' | sed 's/^ *//g' | awk '{print $1, $4}')
		t=$2
		for ((i=0;i<=${#array[@]}-1;i+=3));do
			netif=${array[i]}
		    ri=${array[i+1]}
		    ti=${array[i+2]}
			sleep $t
    	    read -r -a new_array <<< $(netstat -ie | egrep -v "Kernel|inet|ether|RX error|TX errors|device|loop|1d" | cut -f1 -d":" | sed 's/.*bytes//g' | sed 's/^ *//g' | awk '{print $1, $4}')
		    rf=${new_array[i+1]}
		    tf=${new_array[i+2]}
		    rx=$((rf - ri))
		    tx=$((tf - ti))
			trate=$(echo |awk -va=$tx -vb=$t '{ print a/b}') 
		    rrate=$(echo |awk -va=$rx -vb=$t '{ print a/b}')
		    case $1 in
		        -b)
		            if [ $i -eq "0" ];then
		        		printf "%7s %6s %6s %7s %7s\n" NETIF TX/b RX/b TRATE/b RRATE/b
		            fi
		            printf "%7s %6s %6s %7s %7s\n" $netif $tx $rx $trate $rrate
		            ;;
		        -k)
		            if [ $i -eq "0" ];then
		        		printf "%7s %6s %6s %7s %7s\n" NETIF TX/kb RX/kb TRATE/kb RRATE/kb
		            fi
					# Using awk to calculate decimal values
		            tx=$(echo |awk -va=$tx '{ print a*0.001}') 
		            rx=$(echo |awk -va=$rx '{ print a*0.001}') 
		            trate=$(echo |awk -va=$trate '{ print a*0.001}')
		            rrate=$(echo |awk -va=$rrate '{ print a*0.001}')
		            printf "%7s %6s %6s %7s %8s\n" $netif $tx $rx $trate $rrate
		            ;;
		        -m)
		            if [ $i -eq "0" ];then
		        		printf "%7s %8s %8s %9s %9s\n" NETIF TX/mb RX/mb TRATE/mb RRATE/mb
		            fi
					# Using awk to calculate decimal values
		            tx=$(echo |awk -va=$tx '{ print a*0.00001}') 
		            rx=$(echo |awk -va=$rx '{ print a*0.00001}') 
		            trate=$(echo |awk -va=$trate '{ print a*0.00001}')
		            rrate=$(echo |awk -va=$rrate '{ print a*0.00001}')
		            printf "%7s %8s %8s %9s %9s\n" $netif $tx $rx $trate $rrate
		            ;;
		    	esac
		done
	fi
else
	echo "Invalid argument"
	echo "Valid arguments: [-p] [-t] [-r] [-T] [-R] [-v] [-c] [-l] [-b] [-k] [-m]"
fi
