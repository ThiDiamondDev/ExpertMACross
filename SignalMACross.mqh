//+------------------------------------------------------------------+
//|                                                SignalMACross.mqh |
//|                                                       ThiDiamond |
//|                                 https://github.com/ThiDiamondDev |
//+------------------------------------------------------------------+
#include <Expert\ExpertSignal.mqh>

// wizard description start
//+------------------------------------------------------------------+
//| Description of the class                                         |
//| Title=SignalMACross                                              |
//| Type=SignalAdvanced                                              |
//| Name=MACross                                                     |
//| ShortName=MACross                                                |
//| Class=SignalMACross                                              |
//| Page=                                                            |
//| Parameter=SlowPeriod,int,11,Slow MA period                       |
//| Parameter=FastPeriod,int,7,Fast Ma period                        |
//| Parameter=MAMethod,ENUM_MA_METHOD,MODE_EMA,Method of averaging   |
//| Parameter=MAPrice,ENUM_APPLIED_PRICE,PRICE_CLOSE,Price type      |
//| Parameter=Shift,int,0,Shift                                      |
//+------------------------------------------------------------------+
// wizard description end

//+------------------------------------------------------------------+
//| Class SignalMACross.                                             |
//| Purpose: Generator of trade signals based on 2 MAs crosses.      |
//+------------------------------------------------------------------+
class SignalMACross : public CExpertSignal
  {
protected:
   CiMA              maSlow;         // object-indicator
   CiMA              maFast;         // object-indicator

   // adjustable parameters
   int               slowPeriod;
   int               fastPeriod;
   ENUM_MA_METHOD    method;
   ENUM_APPLIED_PRICE type;
   int               shift;

   // "weights" of market models (0-100)
   int               m_pattern_0;      // model 0 "fast MA crosses slow MA"

public:
                     SignalMACross(void);
                    ~SignalMACross(void);

   // parameters setters
   void              SlowPeriod(int value) { slowPeriod = value; }
   void              FastPeriod(int value) { fastPeriod = value; }
   void              MAMethod(ENUM_MA_METHOD value) { method = value; }
   void              MAPrice(ENUM_APPLIED_PRICE value) { type = value; }
   void              Shift(int value) { shift = value; }

   // adjusting "weights" of market models
   void              Pattern_0(int value) { m_pattern_0 = value; }

   // verification of settings
   virtual bool      ValidationSettings(void);

   // creating the indicator and timeseries
   virtual bool      InitIndicators(CIndicators *indicators);

   // checking if the market models are formed
   virtual int       LongCondition(void);
   virtual int       ShortCondition(void);

protected:
   // initialization of the indicators
   bool              InitMAs(CIndicators *indicators);

   // helper functions to read indicators' data
   double            FastMA(int ind) { return(maFast.Main(ind)); }
   double            SlowMA(int ind) { return(maSlow.Main(ind)); }
  };

//+------------------------------------------------------------------+
//| Constructor                                                      |
//+------------------------------------------------------------------+
SignalMACross::SignalMACross(void)
   : slowPeriod(11),
     fastPeriod(7),
     method(MODE_EMA),
     type(PRICE_CLOSE),
     shift(0),
     m_pattern_0(100)
  {
  }

//+------------------------------------------------------------------+
//| Destructor                                                       |
//+------------------------------------------------------------------+
SignalMACross::~SignalMACross(void)
  {
  }

//+------------------------------------------------------------------+
//| Validation settings protected data                               |
//+------------------------------------------------------------------+
bool SignalMACross::ValidationSettings(void)
  {
   if(!CExpertSignal::ValidationSettings())
      return(false);
   return(true);
  }

//+------------------------------------------------------------------+
//| Create indicators                                                |
//+------------------------------------------------------------------+
bool SignalMACross::InitIndicators(CIndicators *indicators)
  {
   if(indicators == NULL)
      return(false);
   if(!CExpertSignal::InitIndicators(indicators))
      return(false);
   if(!InitMAs(indicators))
      return(false);
   return(true);
  }

//+------------------------------------------------------------------+
//| Create MA indicators                                             |
//+------------------------------------------------------------------+
bool SignalMACross::InitMAs(CIndicators *indicators)
  {
   if(indicators == NULL)
      return(false);

// initialize object
   if(!maFast.Create(m_symbol.Name(), m_period, fastPeriod, shift, method, type)
      || !maSlow.Create(m_symbol.Name(), m_period, slowPeriod, shift, method, type))
     {
      printf(__FUNCTION__ + ": error initializing object");
      return(false);
     }

// add object to collection
   if(!indicators.Add(GetPointer(maFast))
      || !indicators.Add(GetPointer(maSlow)))
     {
      printf(__FUNCTION__ + ": error adding object");
      return(false);
     }

   return(true);
  }

//+------------------------------------------------------------------+
//| "Voting" that price will grow                                    |
//+------------------------------------------------------------------+
int SignalMACross::LongCondition(void)
  {
   int result = 0;
   int idx = StartIndex();

   if(FastMA(idx + 1) < SlowMA(idx) && FastMA(idx) > SlowMA(idx))
      result = m_pattern_0;

   return(result);
  }

//+------------------------------------------------------------------+
//| "Voting" that price will fall                                    |
//+------------------------------------------------------------------+
int SignalMACross::ShortCondition(void)
  {
   int result = 0;
   int idx = StartIndex();

   if(FastMA(idx + 1) > SlowMA(idx) && FastMA(idx) < SlowMA(idx))
      result = m_pattern_0;

   return(result);
  }
//+------------------------------------------------------------------+
