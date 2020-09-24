#!/bin/bash
#kill all processes 
#for i in `ps -ef | grep luke|egrep "q.*.q " | awk '{print $2}'`;do kill -9 $i;done
cd /home/luke/kdb/Gateway_KS/Demo2 
dir=`date +%d.%m.%y`
logDir=${dir}/logs
mkdir -p $logDir

#Generate HDB
echo "Generating HDB with dummy data "
q generateHdb.q -hdbDir hdb -numberOfDays 31 -tradesPerDay 1000 -quoteTradeRatio 15:1 -priceMovement 0.001 >> /dev/null  2>&1 &
if [ $? == "0" ]
then
        echo "Generated Dummy Data successfully"
fi

sleep 1

#Start HDB
echo "Starting HDBs on port 5002"
q hdb.q -hdbDir ./hdb -p 5002 -T 5 >> ${logDir}/hdb.log 2>&1 &
if [ $? == "0" ]
then
        echo "HDBs started successfully"
fi

sleep 1

#Start tickerplant
echo "Starting tickerplant on port 5000"
q tick.q -p 5000 -schemaFile tick/schema.csv -logDir $dir >> ${logDir}/tick.log 2>&1 & 
if [ $? == "0" ]
then
	echo "Tickerplant started successfully"
fi 

sleep 1

#Start Feed handler 
echo "Starting Feedhandler"
q feed_handler.q -tickerplants 5000 -hdb 5002 -numberOfSyms 1000 -quoteTradeRatio 15:1 -priceMovement 0.001 -t 100 >> ${logDir}/feedhandler.log 2>&1 & 
if [ $? == "0" ]
then
        echo "Feedhandler started successfully"
fi

sleep 1

#Generate all 2 character combinations
allCombos=$(perl -le '@c = ("A".."Z","a".."z",0..9);
for $a (@c){for $b(@c){
print "$a$b"}}')

#Start RDBs
echo "Starting RDBs on ports.. 5010 5011 5012"
symbols=$(echo $allCombos | cut -d " " -f1-1000)
q tick/rdb.q -p 5010 -tickerplant 5000 -hdb 5002 -tables -symbols "$symbols" -T 5 >> ${logDir}/rdb1.log 2>&1 &
symbols=$(echo $allCombos | cut -d " " -f1001-2000)
q tick/rdb.q -p 5011 -tickerplant 5000 -hdb 5002 -tables -symbols "$symbols" -T 5 >> ${logDir}/rdb2.log 2>&1 &
symbols=$(echo $allCombos | cut -d " " -f2001-3000)
q tick/rdb.q -p 5012 -tickerplant 5000 -hdb 5002 -tables -symbols "$symbols" -T 5 >> ${logDir}/rdb3.log 2>&1 &
if [ $? == "0" ]
then
        echo "Symbol Subscribed RDB started successfully"
fi

sleep 1

#Start Gateway 
echo "Starting Gateway on port 5555"
q gw.q  -p 5555 -rdbPorts 5010 5011 5012 -hdbPorts 5002 >> ${logDir}/gw.log 2>&1 &
if [ $? == "0" ]
then
	echo "Gateway started successfully"
fi

sleep 1
