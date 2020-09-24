/ q gw.q  -p 5555 -rdbPorts 5010 5011 5012 -hdbPorts 5002 
/ Define default ports to hdb and rdb processes
default:`rdbPorts`hdbPorts`mode!(5010 5011 5012;enlist 5002;`dev);
args:.Q.def[default;.Q.opt .z.x];

/ Build up table in order to keep track of client rerequests
.history.clientResponse:clientResponse:([clientId:"j"$()] handle:"i"$();receiveTime:"p"$());
.history.servicesData:0!servicesData:([clientId:"j"$();handle:"i"$()] query:();sent:"b"$();data:();response:"b"$();error:"b"$();updTime:"p"$());

/ list of HDB and RDB handles
conns:neg hopen each raze args`hdbPorts`rdbPorts;

/ start client request id at 0
clientRequestId:0j;

/ stored procedure in gateway
getData:{[table;startDate;endDate;ids]
	-30!(::);
	query:(`selectFunc;table;startDate;endDate;ids;clientRequestId);
	`.history.clientResponse`clientResponse upsert\:(clientRequestId;.z.w;.z.p);
	`servicesData upsert {`clientId`handle`query`sent`data`response`error`updTime!(clientRequestId;abs[x];y;0b;();0b;0b;z)}[;query;.z.p] each conns; 
        if[`dev~args`mode;
                `.history.servicesData upsert 0!servicesData];
	free:conns@where not neg[conns]in distinct exec handle from servicesData where and[sent=1b;response=0b];
	free@\:query;
	update sent:1b,updTime:.z.p from `servicesData where clientId=clientRequestId,handle in abs[free];
	if[`dev~args`mode;
		`.history.servicesData upsert 0!servicesData];
	clientRequestId+:1;
	}

// to be called from rdb and hdb async callback
callback:{[result;requestId]
	/ Check if any request is waiting for service which data was just received from
	if[count Id:first exec clientId from servicesData where handle=abs[.z.w],sent=0b;
		query:first exec query from servicesData where clientId=Id,handle=abs[.z.w];
		neg[.z.w]query;
		update sent:1b,updTime:.z.p from `servicesData where clientId=Id,handle=abs[.z.w];
		]; 
	/ End callback if the request Id has already been removed due to another service throwing error
	if[not requestId in exec distinct clientId from servicesData; 
		:()];
	query:first exec query from servicesData where clientId=requestId,handle=abs[.z.w];
	`servicesData upsert (requestId;.z.w;query;1b;data:first reverse result;1b;error:first result;.z.p);
	if[`dev~args`mode;
		`.history.servicesData upsert 0!servicesData];
	clientHandle:first exec handle from clientResponse where clientId=requestId;
	/ If error has been caught send error back to client
	if[error;
		-30!(clientHandle;1b;data);
		delete from `clientResponse where clientId=requestId;
		delete from `servicesData where clientId=requestId;
		:()];
	/ if all data has been received from services send to client 
	if[all exec response from servicesData where clientId=requestId;
		allData:raze exec data from servicesData where clientId=requestId;
		-30!(clientHandle;0b;allData); 
		delete from `clientResponse where clientId=requestId;
		delete from `servicesData where clientId=requestId
		];
        }
