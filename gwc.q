// This is process started in order to query the gateway 
/ q gwc.q  -gatewayPort 5555 -table trade -startDate 2020.08.30 -endDate 2020.09.04 -syms "hq 01" 
default:`gatewayPort`table`startDate`endDate`syms!(5555;`trade;.z.D-31;.z.D;`VOD.L);
args:.Q.def[default;.Q.opt .z.x];
formatSyms:{$[1<count s:`$" " vs string x;s;x]};
symbols:formatSyms[args`syms];

/if 3.6 only use sync calls as deferred sync now uses .z.pg on gateway 
gatewayHandle:hopen args`gatewayPort;

/ client request
data:gatewayHandle(`getData;args`table;args`startDate;args`endDate;symbols);
