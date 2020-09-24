// tickerplant process for routing subscription and data recovery
/ q tick.q -p 5010 -schemaFile tick/schema.csv -logDir logs   

// Define default values and use .Q.def to enforce type
default:`p`schemaFile`logDir!(5010j;`$"tick/schema.csv";`.);
args:.Q.def[default;.Q.opt .z.x];

// Initialize tables defined in csv 
//function to load schema 
.tick.loadSchema:{
	.tick.schemaMeta:("SSCS";enlist csv) 0: hsym args`schemaFile; 
	.tick.tables:exec distinct table from .tick.schemaMeta;	
	{x set flip exec column!attribute#'types$\:() from ?[.tick.schemaMeta;enlist(=;`table;enlist x);0b;()]} each .tick.tables;
        };

\l tick/u.q

.tick.tplogInit:{[date] 
	if[not type key .tick.tpLogPath:`$(-10_string .tick.tpLogPath),string date;
		.[.tick.tpLogPath;();:;()]];
	.tick.logMsgCount:.tick.totalMsgCount:-11!(-2;.tick.tpLogPath);
	if[0<=type .tick.logMsgCount;
		-2 (string .tick.tpLogPath)," is a corrupt log. Truncate to length ",(string last .tick.logMsgCount)," and restart";
		exit 1];
	hopen .tick.tpLogPath};

.tick.tick:{[tplogName;tplogDir]
	.tick.init[];
	if[not min(`time`sym~2#key flip value@)each .tick.tables;
		'`timesym];
	@[;`sym;`g#]each .tick.tables;
	.tick.date:.z.D;
	if[.tick.tplogHandle:count tplogDir;
		.tick.tpLogPath:`$":",tplogDir,"/",tplogName,10#".";
		.tick.tplogHandle:.tick.tplogInit .tick.date]
	};

.tick.endofday:{
	.tick.end .tick.date;
	.tick.date+:1;
	if[.tick.tplogHandle;
		hclose .tick.tplogHandle;
		.tick.tplogHandle:0(`.tick.tplogInit;.tick.date)]
	};

.tick.timer:{[date]
	if[.tick.date<date;
		if[.tick.date<date-1;
			system"t 0";
			'"more than one day?"];
		.tick.endofday[]]
	};

/batch mode
if[system"t";
	.z.ts:{.tick.pub'[.tick.tables;value each .tick.tables];
		@[`.;.tick.tables;@[;`sym;`g#]0#];
		.tick.logMsgCount:.tick.totalMsgCount;
		.tick.timer .z.D};

	 upd:{[table;data]
		if[not -16=type first first data;
			if[.tick.date<"d"$localTime:.z.P;
				.z.ts[]];
			localTime:"p"$localTime;
			data:$[0>type first data;
				localTime,data;
				(enlist(count first data)#localTime),data]];
		 table insert data;
		if[.tick.tplogHandle;
			.tick.tplogHandle enlist (`upd;table;data);.tick.totalMsgCount+:1];
		}

	];

/zero latency
if[not system"t";
	system"t 1000";
	.z.ts:{.tick.timer .z.D};

	upd:{[table;data]
		.tick.timer"d"$localTime:.z.P;
		if[not -16=type first first data;
			localTime:"p"$localTime;
			data:$[0>type first data;
				localTime,data;
				(enlist(count first data)#localTime),data]];
		tableCols:key flip value table;
		.tick.pub[table;$[0>type first data;
					enlist tableCols!data;
					flip tableCols!data]];
		if[.tick.tplogHandle;
			.tick.tplogHandle enlist (`upd;table;data);.tick.totalMsgCount:.tick.logMsgCount+:1];
		}
	];


main:{
	.tick.loadSchema[];
	.tick.tick["tickerplant_log_";string args`logDir];
	};

main[]
