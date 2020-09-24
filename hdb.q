/Sample usage:
/q -hdbDir hdb.q -p 5002

// Define default values and use .Q.def to enforce type
default:`p`hdbDir!(5010j;`notDefined);
args:.Q.def[default;.Q.opt .z.x];

if[`notDefined~args`hdbDir;
	show"Supply directory of historical database with -hdbDir";
	exit 0
	];

/Mount the Historical Date Partitioned Database
@[{system"l ",x};
	string args`hdbDir;
		{
		show "Error message - ",x;
		/exit 0i
		}
	];

/ same function called for both HDB and RDB
selectFunc:{[table;startDate;endDate;ids;requestId]
	result:.[getData;
		(table;startDate;endDate;ids);
		{(1b;x)}
		];
           neg[.z.w](`callback;result;requestId)
           }

/ function to get hdb data 
getData:{[table;startDate;endDate;ids]
	result:select from table where date within (startDate;endDate),sym in ids;
        (0b;result)}

