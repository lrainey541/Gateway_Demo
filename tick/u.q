//Utilities 
.tick.init:{.tick.subscriptions:.tick.tables!(count .tick.tables:tables`.)#()}

.tick.del:{[table;subscriber] 
	.tick.subscriptions[table]_:.tick.subscriptions[table;;0]?subscriber
	};

.tick.sel:{[table;listOfSymbols] 
	$[listOfSymbols~`.;
		table;
		select from table where sym in listOfSymbols]};

.tick.pub:{[table;data]
	{[table;data;subscriber]
		if[count data:.tick.sel[data]subscriber 1;
			(neg first subscriber)(`upd;table;data)]}[table;data]
				each .tick.subscriptions[table]
	};

.tick.add:{[table;symbols]
	$[(count .tick.subscriptions table)>.tick.totalMsgCount:.tick.subscriptions[table;;0]?.z.w;
		.[`.tick.subscriptions;(table;i;1);union;symbols];
		.tick.subscriptions[table],:enlist(.z.w;symbols)];
	(table;$[99=type data:value table;.tick.sel[data]symbols;@[0#value table;`sym;`g#]])
	};

.tick.sub:{[table;symbols]
	if[table~`;
		:.tick.sub[;symbols]each .tick.tables];
	if[not table in .tick.tables;
		'table];
	.tick.del[table].z.w;
	.tick.add[table;symbols]
	};

.tick.end:{[date]
	(neg union/[.tick.subscriptions[;;0]])@\:(`.subscriber.end;date)
	};

//Event handlers
.z.pc:{[handle]
	.tick.del[;handle]each .tick.tables
	};
