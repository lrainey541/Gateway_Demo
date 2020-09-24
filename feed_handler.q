// script to generate dummy feed
/ q feed_handler.q -tickerplants localhost:5000 -numberOfSyms 1000 -quoteTradeRatio 15:1 -priceMovement 0.001 -t 100           
 
// Define default values and use .Q.def to enforce type 
default:`tickerplants`hdb`numberOfSyms`quoteTradeRatio`priceMovement`t!(enlist 5000j;0j;3000j;`15:1;0.001f;100i);
args:.Q.def[default;.Q.opt .z.x]; 

// Open async handles to tickerplants
h:neg hopen each args`tickerplants;
syms:neg[args[`numberOfSyms]]?`${x cross x}.Q.a[],.Q.A[],string[til 10];
ratio:(%) . "J"$":" vs string args`quoteTradeRatio;
prices:$[hdb:@[hopen;args`hdb;0b];
	hdb"(!) . value flip 0!select last price by sym from trade";
	syms!args[`numberOfSyms]?"f"$1_til 300
	];

updateCount:0;

/timer function
.z.ts:{
	numberOfUpdates:first 1?10;
	symbols:numberOfUpdates?syms;
	prices[symbols]*:raze 1+1?'(1 -1)*/:numberOfUpdates?args`priceMovement;
	ask:prices[symbols]+numberOfUpdates?args`priceMovement;
	bid:prices[symbols]-numberOfUpdates?args`priceMovement;
	$[0<updateCount mod ratio; 
		h@\:("upd";`quote;(symbols;bid;ask;numberOfUpdates?10*1+til 1000;numberOfUpdates?10*1+til 1000));
		h@\:("upd";`trade;(symbols;prices[symbols];numberOfUpdates?10*1+til 1000))
	];
	updateCount+:1;
	};

/stop sending data if connection to all tickerplant is lost 
.z.pc:{if[not count h::h except neg[x]; system"t 0"];}
