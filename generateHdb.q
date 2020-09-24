// builds a historical trade/quote database
/ q generateHdb.q -hdbDir hdb -numberOfDays 31 -tradesPerDay 1000 -quoteTradeRatio 15:1 -priceMovement 0.001 

// Define default values and use .Q.def to enforce type
default:`hdbDir`numberOfDays`tradesPerDay`quoteTradeRatio`priceMovement!(`hdb;31;1000;`15:1;0.02f);
args:.Q.def[default;.Q.opt .z.x];

// Define start and end dates 
`start`end set'.z.D-default[`numberOfDays],1;
syms:`${x cross x}.Q.a[],.Q.A[],string[til 10];
prices:syms!count[syms]?"f"$1_til 300;
ratio:"j"$(%) . "J"$":" vs string args`quoteTradeRatio;
quotesPerDay:ratio*tradesPerDay:args[`tradesPerDay];

// Generate list of weekdays
getDates:{[start;end]
        dates:start + til 1 + end-start;
        dates where 5> dates-`week$dates}

// Write partitioned table to disk
write:{[dir;date;table]
	columnOrder:cols table;
	.Q.dpft[dir;date;`sym;table];
	(` sv dir,(`$string date),table,`.d) set columnOrder
	};

generatePartition:{[date]
	symbols:neg[tradesPerDay]?syms;
	prices[symbols]*:raze 1+1?'(1 -1)*/:tradesPerDay?args`priceMovement;
	ask:raze flip (+)\[prices[symbols];ratio#tradesPerDay?args`priceMovement];
	bid:raze flip (-)\[prices[symbols];ratio#tradesPerDay?args`priceMovement];
	quoteTimes:"p"$(ratio-1) {x+("j"$"p"$"d"$1)%ratio+1}\ "p"$date;
	quote::([] time:raze flip tradesPerDay#/:quoteTimes;sym:raze ratio#/:symbols;bid;ask;bidSize:quotesPerDay?10*1+til 1000;askSize:quotesPerDay?10*1+til 1000);
	trade::([] time:tradesPerDay?quoteTimes;sym:symbols;price:prices[symbols];size:tradesPerDay?10*1+til 1000);
	write[hsym args`hdbDir;date;] each `trade`quote
	}	

generatePartition each getDates[start;end];

0N!"HDB Created under following directory: ",string[args`hdbDir];

exit 0
