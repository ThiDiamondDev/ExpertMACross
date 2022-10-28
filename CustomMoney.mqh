//+------------------------------------------------------------------+
//|                                                  CustomMoney.mqh |
//|                                                       ThiDiamond |
//|                                 https://github.com/ThiDiamondDev |
//+------------------------------------------------------------------+
#property copyright "ThiDiamond"
#property link      "https://github.com/ThiDiamondDev"
//+------------------------------------------------------------------+
// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=Trading with minimal allowed trade volume                  |
//| Type=Money                                                       |
//| Name=MinLot                                                      |
//| Class=CustomMoney                                                |
//| Page=                                                            |
//+------------------------------------------------------------------+
// wizard description end
//+------------------------------------------------------------------+
//| Class CustomMoney.                                               |
//| Appointment: Class custom money managment.                       |
//|              Derives from class CExpertMoney.                    |
//+------------------------------------------------------------------+
#include <Expert\ExpertMoney.mqh>
input int SessionStartHour = 10;
input int SessionStartMinute = 0;
input int SessionEndHour = 14;
input int SessionEndMinute = 30;
input int DailyLimitProfit = 50;
input int DailyLimitLoss = 50;

const int ZERO_LOTS = 0;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int NormalizeToSeconds(int hours, int minutes)
  {
   return(hours * 3600 + minutes * 60);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int SessionStart = NormalizeToSeconds(SessionStartHour, SessionStartMinute);
int SessionEnd   = NormalizeToSeconds(SessionEndHour, SessionEndMinute);

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class CustomMoney : public CExpertMoney
  {

private:
   ulong                magicNumber;
   MqlDateTime          today;
   double               todayProfit;

public:
                     CustomMoney(void);
                    ~CustomMoney(void);
   //---
   bool              IsTimeToTrade(void);
   uint              GetTodayTotalDeals(void);
   double            GetTodayProfit(void);
   double            CheckOpen(void);
   bool              IsDailyGoalReached(void);
   void              SetMagicNumber(ulong magic);
   void              UpdateTime(void);
   void              AddToProfit(double profit);

   virtual bool      ValidationSettings(void);
   //---
   virtual double    CheckOpenLong(double price,double sl);
   virtual double    CheckOpenShort(double price,double sl);
  };
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
void CustomMoney::CustomMoney(void)
  {
   MqlDateTime time;
   TimeCurrent(time);
   todayProfit = GetTodayProfit();
   today = time;
  }
//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
void CustomMoney::SetMagicNumber(ulong magic)
  {
   magicNumber = magic;
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
void CustomMoney::~CustomMoney(void)
  {
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CustomMoney::IsTimeToTrade(void)
  {
   MqlDateTime time;
   TimeCurrent(time);
   int time_seconds = NormalizeToSeconds(time.hour, time.min);
   return(time_seconds >= SessionStart && time_seconds <= SessionEnd);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
uint CustomMoney::GetTodayTotalDeals()
  {
   MqlDateTime fromDate, toDate;
   TimeCurrent(fromDate);
   TimeCurrent(toDate);
   fromDate.hour = 0;
   fromDate.min = 0;
   fromDate.sec = 0;

   HistorySelect(StructToTime(fromDate),StructToTime(toDate));
   return(HistoryDealsTotal());
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CustomMoney::GetTodayProfit(void)
  {
   double profit = 0;
   ulong ticketHistoryDeal=0;
   uint totalDeals = GetTodayTotalDeals();
//--- for all deals
   for(uint i=0; i < totalDeals; i++)
     {
      //--- try to get deals ticketHistoryDeal
      if((ticketHistoryDeal=HistoryDealGetTicket(i))>0)
        {
         long     dealTicket       =HistoryDealGetInteger(ticketHistoryDeal,DEAL_TICKET);
         long     dealTime         =HistoryDealGetInteger(ticketHistoryDeal,DEAL_TIME);
         long     dealType         =HistoryDealGetInteger(ticketHistoryDeal,DEAL_TYPE);
         long     dealEntry        =HistoryDealGetInteger(ticketHistoryDeal,DEAL_ENTRY);
         long     dealMagic        =HistoryDealGetInteger(ticketHistoryDeal,DEAL_MAGIC);
         double   dealCommission   =HistoryDealGetDouble(ticketHistoryDeal,DEAL_COMMISSION);
         double   dealSwap         =HistoryDealGetDouble(ticketHistoryDeal,DEAL_SWAP);
         double   dealProfit       =HistoryDealGetDouble(ticketHistoryDeal,DEAL_PROFIT);
         string   dealSymbol       =HistoryDealGetString(ticketHistoryDeal,DEAL_SYMBOL);
         //---
         if(::Symbol() == dealSymbol &&  magicNumber == dealMagic)
            if(dealEntry==DEAL_ENTRY_OUT)
               profit += dealCommission+dealSwap+dealProfit;
        }
     }

   return(profit);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CustomMoney::IsDailyGoalReached()
  {
   return(todayProfit >= DailyLimitProfit  && todayProfit >= -DailyLimitLoss);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CustomMoney::CheckOpen()
  {
   if(!IsTimeToTrade() || IsDailyGoalReached())
      return(ZERO_LOTS);
   return(m_symbol.LotsMin());
  }
//+------------------------------------------------------------------+
//| Validation settings protected data.                              |
//+------------------------------------------------------------------+
bool CustomMoney::ValidationSettings(void)
  {
   Percent(60);
//--- initial data checks
   if(!CExpertMoney::ValidationSettings())
      return(false);
//--- ok
   return(true);
  }
//+------------------------------------------------------------------+
//| Getting lot size for open long position.                         |
//+------------------------------------------------------------------+
double CustomMoney::CheckOpenLong(double price,double sl)
  {
   return(CheckOpen());
  }
//+------------------------------------------------------------------+
//| Getting lot size for open short position.                        |
//+------------------------------------------------------------------+
double CustomMoney::CheckOpenShort(double price,double sl)
  {
   return(CheckOpen());
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CustomMoney::UpdateTime(void)
  {
   MqlDateTime time;
   TimeCurrent(time);
   if(time.day != today.day || time.mon != today.mon || time.year != today.year)
     {
      today = time;
      todayProfit = GetTodayProfit();
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CustomMoney::AddToProfit(double profit)
  {
   todayProfit += profit;
  }
//+------------------------------------------------------------------+
