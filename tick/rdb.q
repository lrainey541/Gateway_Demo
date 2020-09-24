// Real-time database process to store today's data  
/q tick/rdb.q -p 5005 -tickerplant 5000 -hdb 5002 -tables trade -symbols "MSFT.O IBM.N GS.N"

/ sleep if windows OS
if[not "w"=first string .z.o;system "sleep 1"];

// Define default values and use .Q.def to enforce type
default:`p`tickerplant`hdb`tables`symbols!(5010j;5000j;5002j;`.;`.);
args:.Q.def[default;.Q.opt .z.x];

//create list of symbols if multiple variables are given at command line 
.rdb.formatSubscription:{$[1<count s:`$" " vs string x;s;x]};
.rdb.tables:.rdb.formatSubscription[args`tables];
.rdb.symbols:.rdb.formatSubscription[args`symbols];

.rdb.upd:upd:insert;

.rdb.recoveryUpd:{[table;data]
	if[not table in tables`.;
		:()];
	if[not .rdb.symbols~`.;
		data:flip(flip data)@where data[1] in .rdb.symbols];
        table insert data
	};

/ end of day: save, clear, hdb reload
.subscriber.end:{[date]
	t:tables`.;
	t@:where `g=attr each t@\:`sym;
	.Q.hdpf[args`hdb;`:hdb;date;`sym];
	@[;`sym;`g#] each t
	};

/ init schema and sync up from log file;cd to hdb(so client save can run)
.rdb.replay:{[data;tickParams]
	data:$[0<type raze data;
		enlist data;
		data];
	(.[;();:;].)each data;
        tpLogCount:first tickParams;
        tpLogPath:first reverse tickParams;
	if[tpLogCount>0;
		upd::.rdb.recoveryUpd];
	if[null tpLogCount;
		:()];
	-11!(tpLogCount;tpLogPath);
	upd::.rdb.upd;
	};

/ same function called for both HDB and RDB
selectFunc:{[table;startDate;endDate;ids;requestId]
	result:.[getData;
		(table;startDate;endDate;ids);
		{(1b;x)}];
	neg[.z.w](`callback;result;requestId)
	};

/ function called to get RDB data
getData:{[table;startDate;endDate;ids]
        result:$[.z.D within (startDate;endDate);
			select from table where sym in ids;
			0#value table];
        result:`date xcols update date:.z.D from result;
        (0b;result)}

/ connect to ticker plant for (schema;(logcount;log))
.rdb.tickHandle:hopen args`tickerplant;
.rdb.replay . (.rdb.tickHandle(`.tick.sub;.rdb.tables;.rdb.symbols);.rdb.tickHandle"`.tick `logMsgCount`tpLogPath")
