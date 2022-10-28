//+------------------------------------------------------------------+
//|                                                MACrossExpert.mq5 |
//|                                                       ThiDiamond |
//|                                 https://github.com/ThiDiamondDev |
//+------------------------------------------------------------------+
#property copyright "ThiDiamond"
#property link      "https://github.com/ThiDiamondDev"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Include                                                          |
//+------------------------------------------------------------------+
#include <Expert\Expert.mqh>
//--- available signals
#include "SignalMACross.mqh"
//--- available trailing
#include <Expert\Trailing\TrailingNone.mqh>
//--- available money management
#include "CustomMoney.mqh"
//+------------------------------------------------------------------+
//| Inputs                                                           |
//+------------------------------------------------------------------+
//--- inputs for expert
string                   ExpertTitle              ="MACrossExpert";       // Document name
input ulong              ExpertMagicNumber        =25501;           //
bool                     ExpertEveryTick          =false;            //
//--- inputs for main signal
int                      ThresholdOpen      =10;              // Signal threshold value to open [0...100]
int                      ThresholdClose     =10;              // Signal threshold value to close [0...100]
int                      PriceLevel         =0;               // Price level to execute a deal
int                      Expiration         =4;               // Expiration of pending orders (in bars)
input int                StopLevel          =200;             // Stop Loss level (in points)
input int                TakeLevel          =600;             // Take Profit level (in points)
input int                SlowPeriod=11;              // Slow MA period
input int                FastPeriod=7;               // Fast Ma period
input ENUM_MA_METHOD     MAMethod  =MODE_EMA;        // Method of averaging
input ENUM_APPLIED_PRICE MAPrice   =PRICE_CLOSE;     // Price type
input int                Shift     =0;               // Shift
input double             Weight    =1.0;             // Weight [0...1.0]

//+------------------------------------------------------------------+
//| Global expert object                                             |
//+------------------------------------------------------------------+
CExpert ExtExpert;
CustomMoney *_money;

//+------------------------------------------------------------------+
//| Initialization function of the expert                            |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- Initializing expert
   if(!ExtExpert.Init(Symbol(),Period(),ExpertEveryTick,ExpertMagicNumber))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing expert");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Creating signal
   CExpertSignal *signal=new CExpertSignal;
   if(signal==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating signal");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//---
   ExtExpert.InitSignal(signal);
   signal.ThresholdOpen(ThresholdOpen);
   signal.ThresholdClose(ThresholdClose);
   signal.PriceLevel(PriceLevel);
   signal.StopLevel(StopLevel);
   signal.TakeLevel(TakeLevel);
   signal.Expiration(Expiration);
//--- Creating filter SignalMACross
   SignalMACross *filter0=new SignalMACross;
   if(filter0==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating filter0");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   signal.AddFilter(filter0);
//--- Set filter parameters
   filter0.SlowPeriod(SlowPeriod);
   filter0.FastPeriod(FastPeriod);
   filter0.MAMethod(MAMethod);
   filter0.MAPrice(MAPrice);
   filter0.Shift(Shift);
   filter0.Weight(Weight);
//--- Creation of trailing object
   CTrailingNone *trailing=new CTrailingNone;
   if(trailing==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Add trailing to expert (will be deleted automatically))
   if(!ExtExpert.InitTrailing(trailing))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing trailing");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Set trailing parameters
//--- Creation of money object
   _money=new CustomMoney();
   if(_money==NULL)
     {
      //--- failed
      printf(__FUNCTION__+": error creating money");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
   _money.SetMagicNumber(ExpertMagicNumber);
//--- Add money to expert (will be deleted automatically))
   if(!ExtExpert.InitMoney(_money))
     {
      //--- failed
      printf(__FUNCTION__+": error initializing money");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }

//--- Check all trading objects parameters
   if(!ExtExpert.ValidationSettings())
     {
      //--- failed
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- Tuning of all necessary indicators
   if(!ExtExpert.InitIndicators())
     {
      //--- failed
      printf(__FUNCTION__+": error initializing indicators");
      ExtExpert.Deinit();
      return(INIT_FAILED);
     }
//--- ok
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Deinitialization function of the expert                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ExtExpert.Deinit();
  }
//+------------------------------------------------------------------+
//| "Tick" event handler function                                    |
//+------------------------------------------------------------------+
void OnTick()
  {
   ExtExpert.OnTick();
  }
//+------------------------------------------------------------------+
//| "Trade" event handler function                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
   ExtExpert.OnTrade();
  }
//+------------------------------------------------------------------+
//| "Timer" event handler function                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
   ExtExpert.OnTimer();
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
//--- get transaction type as enumeration value
   ENUM_TRADE_TRANSACTION_TYPE type=trans.type;
//--- if transaction is result of addition of the transaction in history
   if(type==TRADE_TRANSACTION_DEAL_ADD)
      //--- try to get deals ticket_history_deal
      if(HistoryDealSelect(trans.deal))
        {
         long     dealTime         =HistoryDealGetInteger(trans.deal,DEAL_TIME);
         long     dealType         =HistoryDealGetInteger(trans.deal,DEAL_TYPE);
         long     dealEntry        =HistoryDealGetInteger(trans.deal,DEAL_ENTRY);
         long     dealMagic        =HistoryDealGetInteger(trans.deal,DEAL_MAGIC);
         double   dealCommission   =HistoryDealGetDouble(trans.deal,DEAL_COMMISSION);
         double   dealSwap         =HistoryDealGetDouble(trans.deal,DEAL_SWAP);
         double   dealProfit       =HistoryDealGetDouble(trans.deal,DEAL_PROFIT);
         string   dealSymbol       =HistoryDealGetString(trans.deal,DEAL_SYMBOL);
         //---
         if(::Symbol() == dealSymbol && ExpertMagicNumber == dealMagic)
            if(dealEntry==DEAL_ENTRY_OUT)
               _money.AddToProfit(dealCommission+dealSwap+dealProfit);
        }

  }
//+------------------------------------------------------------------+
