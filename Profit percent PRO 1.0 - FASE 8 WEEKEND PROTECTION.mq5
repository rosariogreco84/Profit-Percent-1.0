//+------------------------------------------------------------------+
//| Profit Percent PRO — MT5 — FULL (v11.81 - Fase 7 Dashboard Diagnostica ITA) |
//| Dashboard Day/Week + Signal Engine + Execution + Trade Manager |
//| + Trading Schedule + Overnight Policy + Profit Tracking Modes |
//| + Telegram (Deals + OrderUpdate + Detailed Events + anti-spam) |
//| + NEWS FILTER (Low/Med/High impact + minutes before/after) |
//+------------------------------------------------------------------+
#property strict
#property version "11.70"
#include <Trade/Trade.mqh>
//====================================================================
// NOTE MT5 EMAIL
// - In MT5 NON puoi impostare i destinatari via codice.
// - Devi configurare email in: Terminale -> Strumenti -> Opzioni -> Email
// - SendMail() invia all’account configurato nel terminale.
//====================================================================
//======================== ╔═ TARGET PROFIT ═╗ ========================
input group "01 — TARGET PROFIT";
input double DailyTargetPercent = 1;
input bool EnableWeeklyTarget = true;
// Settimana: base lunedì ore: WeekStartHour:WeekStartMinute
input group "01 — TARGET — INIZIO SETTIMANA";
input int WeekStartHour = 0;
input int WeekStartMinute = 0;
//======================== ╔═ PROFIT TRACKING ═╗ ========================
input group "01 — TARGET — COSA CONTEGGIARE";
input bool TrackWholeAccount = true; // true = tutto l'account (manuale incluso)
input bool TrackOnlyThisSymbol = false; // attivo solo se TrackWholeAccount=false
input bool TrackOnlyThisMagic = false;  // attivo solo se TrackWholeAccount=false
input bool TrackOnlyThisEA = true;      // attivo solo se TrackWholeAccount=false; ignora manuali/altri EA
//======================== ╔═ PANEL UI ═╗ ========================
input group "02 — PANNELLO — POSIZIONE";
input int PanelCorner = 1; // 0=TopLeft | 1=BottomLeft | 2=BottomRight | 3=TopRight
input int OffsetX = 20;
input int OffsetY = 55;
input group "02 — PANNELLO — FONT";
input string FontName = "Consolas";
input int FontSize = 9;
input int LineGap = 16;
input group "02 — PANNELLO — COLORI";
input color TitleColor = clrWhite;
input color TextColor = clrLightGray;
input color PositiveColor = clrLime;
input color NegativeColor = clrRed;
input color StatusColor = clrAqua;
input group "02 — PANNELLO — SEPARATORI";
input bool  UseSeparators   = true;
input string SepStyleText   = "────────────────────────"; // cambia qui lo stile
input color SepColor        = clrDimGray;                 // colore separatore
//======================== ╔═ EMAIL ALERT ═╗ ========================
input group "03 — NOTIFICHE — EMAIL TARGET";
input bool SendEmailOnTarget = false;
input string EmailToHint = "destinatario@azienda.it"; // solo “hint” (MT5 invia a quello configurato in terminale)
input string EmailSubjectDay = "TARGET GIORNALIERO RAGGIUNTO";
input string EmailSubjectWeek = "TARGET SETTIMANALE RAGGIUNTO";
//======================== ╔═ TELEGRAM ALERT ═╗ ========================
input group "03 — NOTIFICHE — TELEGRAM";
input bool EnableTelegramNotifications = true;
input string TelegramBotToken = "<INCOLLA_IL_TUO_TOKEN>";
input string TelegramChatID = "2129956854";
// Se vuoi inviare anche a un gruppo, metti l'ID qui sotto (es: -100xxxx)
input bool TelegramUseSecondChat = true;
input string TelegramChatID_2 = "-1002451706062";
input int TelegramRetryCount = 3; // NEW: tentativi retry su fallimento WebRequest
//======================== ╔═ TELEGRAM DETAILED EVENTS ═╗ ========================
input group "03 — TELEGRAM — EVENTI TRADE";
input bool TelegramDetailedEvents = true; // eventi puntuali via OnTradeTransaction
input bool TelegramOnlyThisMagic = false; // filtra per MagicNumber
input bool TelegramOnlyThisSymbol = false; // filtra per _Symbol
input int TelegramEventDedupeMs = 800; // anti doppioni
input bool TelegramIncludeAccountSnap = false; // aggiunge BAL/EQ/FLT agli eventi
//======================== ╔═ TELEGRAM ACCOUNT SUMMARY (ANTI-SPAM) ═╗ ========================
input group "03 — TELEGRAM — RIEPILOGO ACCOUNT";
input bool TelegramSendAccountSummary = true;
input int TelegramSummaryCooldownSec = 900; // 15 minuti tra un riepilogo e l'altro
input bool TelegramSummaryOnSLTPChange = true; // invia se cambia SL/TP su pos/pendenti
input bool TelegramSummaryOnCountChange = true; // invia se cambia count pos/pendenti
//======================== ╔═ NEWS FILTER ═╗ =========================
enum NewsImpactLevel
{
   NEWS_IMPACT_LOW = 0,
   NEWS_IMPACT_MEDIUM = 1,
   NEWS_IMPACT_HIGH = 2
};
enum NewsCurrencyMode
{
   NEWS_CCY_SYMBOL = 0, // usa valute del simbolo (forex: base/quote; altrimenti parsing)
   NEWS_CCY_CUSTOM = 1 // usa lista personalizzata
};
input group "04 — FILTRO NEWS";
input bool EnableNewsFilter = true;
input NewsImpactLevel MinNewsImpactToBlock = NEWS_IMPACT_HIGH;
input int NoTradeMinutesBefore = 15;
input int NoTradeMinutesAfter = 15;
input NewsCurrencyMode NewsCurrenciesMode = NEWS_CCY_SYMBOL;
input string NewsCurrenciesCustomCSV = "USD,EUR,GBP"; // usato se NEWS_CCY_CUSTOM
input int NewsLookAheadMinutes = 180; // cerca eventi avanti di X minuti
input bool ShowNearestNewsOnPanel = true;
//======================== ╔═ DEBUG ═╗ ========================
input group "99 — AVANZATE — DEBUG";
input bool EnableDebugLog = true;
input bool EnableLogFile = false; // NEW: log su file per debug/test
//======================== ╔═ SCHEDULE — GIORNI ═╗ ========================
input group "05 — ORARI — GIORNI OPERATIVI";
input bool TradeMon = true;
input bool TradeTue = true;
input bool TradeWed = true;
input bool TradeThu = true;
input bool TradeFri = true;
input bool TradeSat = false;
input bool TradeSun = false;
input bool BlockFirstDayOfMonth = false;
input bool BlockLastDayOfMonth = false;

//======================== ╔═ WEEKEND PROTECTION ═╗ ========================
// Tutti gli orari di questa sezione sono ORA SERVER MT5 (TimeCurrent).
// La protezione weekend riguarda solo le posizioni di QUESTO EA (MagicNumber) sul simbolo corrente.
input group "05 — ORARI — PROTEZIONE WEEKEND";
input bool UseWeekendProtection = true;
input int FridayStopNewTradesHour = 22;
input int FridayStopNewTradesMinute = 0;
input bool ClosePositionsBeforeWeekend = true;
input int FridayClosePositionsHour = 23;
input int FridayClosePositionsMinute = 30;
input bool MondayResumeFilter = false;
input int MondayResumeHour = 1;
input int MondayResumeMinute = 0;
//======================== ╔═ SCHEDULE — ORARI ═╗ ========================
input group "05 — ORARI — FASCIA OPERATIVA";
input bool Trading24H = true;                 // true = nessun limite orario
input bool UseTradingHours = false;           // usato solo se Trading24H=false
input int TradingStartHour = 0;
input int TradingStartMinute = 0;
input int TradingEndHour = 23;
input int TradingEndMinute = 59;
//======================== ╔═ OVERNIGHT POLICY ═╗ ========================
enum OvernightPolicy
{
   OVERNIGHT_DO_NOTHING = 0,
   OVERNIGHT_CLOSE_ALL_BEFORE_TIME = 1,
   OVERNIGHT_KEEP_PROFIT_CLOSE_LOSS = 2,
   OVERNIGHT_KEEP_LOSS_CLOSE_PROFIT = 3
};
input group "05 — ORARI — GESTIONE NOTTURNA";
input OvernightPolicy OvernightMode = OVERNIGHT_DO_NOTHING;
input int OvernightCloseHour = 23;
input int OvernightCloseMinute = 0;
//======================== ╔═ EXECUTION ENGINE ═╗ ========================
input group "06 — ESECUZIONE";
input bool EnableAutoTrading = false;
input long MagicNumber = 777001;
input string TradeComment = "SignalEnginePRO";
input int NumberOfTradesPerSignal = 1;
input int MaxOpenPositions = 1;
input double MaxSpreadPoints = 200;
input int MaxSlippagePoints = 3; // NEW: slippage max per sicurezza
input bool TradeOnlyNewBar = true;
input int ExecutionRetryCount = 3; // NEW: retry su execution fail
input group "07 — RISCHIO — LOTTO";
enum LotSizingMode
{
   LOT_FIXED,             // Lotto fisso
   LOT_RISK_PERCENT       // Lotto calcolato per rischiare una % del balance allo Stop Loss
};
input LotSizingMode LotMode = LOT_RISK_PERCENT;
input double FixedLot = 0.10;              // Usato solo con LOT_FIXED
input double RiskPercent = 1.0;            // % del balance rischiata per trade
input double MaxLotSize = 10.0;            // Tetto massimo di sicurezza

input group "07 — RISCHIO — STOP LOSS";
input double ATR_SL_Multiplier = 1.4;       // Distanza SL = ATR x moltiplicatore

input group "07 — RISCHIO — TAKE PROFIT";
input double RR_Ratio = 1.8;                // Distanza TP = distanza SL x R:R
//======================== ╔═ TRADE MANAGER — R BASED ═╗ ========================
// 1R = distanza iniziale tra prezzo di ingresso e Stop Loss.
// La distanza R viene ricostruita dal TP iniziale / RR_Ratio, quindi resta stabile
// anche dopo che Break Even o Trailing modificano lo Stop Loss.
input group "08 — GESTIONE POSIZIONE — R";
input bool   UseBreakEven = true;
input double BreakEvenTriggerR = 1.00;       // Attiva BE quando il profitto raggiunge +1R
input double BreakEvenPlusR = 0.05;          // Blocca +0.05R oltre il prezzo di ingresso (0 = BE puro)
input bool   UsePartialClose = true;
input double PartialTriggerR = 1.50;         // Chiusura parziale a +1.5R
input double PartialClosePercent = 50.0;     // Percentuale chiusa UNA SOLA VOLTA per posizione
input bool   UseRTrailing = true;
input double TrailStartR = 2.00;             // Inizia il trailing a +2R
input double TrailFirstLockR = 1.00;         // A +2R porta lo SL a +1R
input double TrailStepR = 0.50;              // Ogni ulteriori +0.5R, avanza lo SL di +0.5R
//======================== ╔═ EQUITY SAVE ═╗ ========================
input group "09 — EQUITY LOCK";
input bool UseEquityLock = true;
// se true usa % del balance, se false usa soldi
input bool EquityLockUsePercent = false;
// modalità soldi
input double EquityLockStartMoney = 12.0; // attiva lock quando floating >= +12
input double EquityLockTrailDDMoney = 8.0; // chiudi se ritraccia di 8 dal picco
// modalità percentuale
input double EquityLockStartPercent = 0.30; // attiva lock quando floating >= +0.30%
input double EquityLockTrailDDPercent = 0.20; // chiudi se ritraccia di 0.20% dal picco
// scope: true = chiude tutto account, false = chiude solo le posizione filtrate (consiglio)
input bool EquityLockCloseWholeAccount = false;
// sicurezza: non richiudere subito dopo una chiusura
input int EquityLockCooldownSec = 60;
//======================== ╔═ SIGNAL ENGINE MASTER ═╗ ========================
input group "10 — SEGNALI — GENERALE";
input(name="Attiva motore segnali") bool UseSignalEngine = true;
input(name="Punteggio minimo per il segnale") int Confirmation_Count = 4;
//======================== ╔═ FILTER SWITCHES ═╗ ========================
input group "10 — SEGNALI — FILTRI ATTIVI";
input(name="Usa RSI") bool UseRSI_Filter = true;
input(name="Usa MACD") bool UseMACD_Filter = true;
input(name="Usa Stocastico") bool UseStoch_Filter = true;
input(name="Usa struttura EMA") bool UseEMA_Filter = true;
input(name="Usa ADX") bool UseADX_Filter = true;
input(name="Usa SAR") bool UseSAR_Filter = true;
// ATR e sempre calcolato: serve a SL e filtro volatilita, non assegna punti al segnale
//======================== ╔═ FILTER WEIGHTS ═╗ ========================
input group "10 — SEGNALI — PESI";
input(name="Peso RSI") int Weight_RSI = 1;
input(name="Peso MACD") int Weight_MACD = 1;
input(name="Peso Stocastico") int Weight_STO = 1;
input(name="Peso struttura EMA") int Weight_EMA = 2;
input(name="Peso ADX") int Weight_ADX = 2;
input(name="Peso SAR") int Weight_SAR = 1;
//======================== ╔═ SIGNAL QUALITY FILTERS ═╗ ========================
input group "10 — SEGNALI — QUALITA";
input(name="Un solo segnale per candela") bool UseOneSignalPerBar = true;
input(name="Usa pausa tra i segnali") bool UseSignalCooldown = true;
input(name="Candele di pausa") int CooldownBars = 3;
input(name="Blocca inversioni troppo rapide") bool UseAntiFlipFilter = true;
input(name="Candele minime prima di invertire") int AntiFlipBars = 5;
//======================== ╔═ RSI ═╗ ========================
input group "11 — INDICATORI — RSI";
input(name="Periodo RSI") int RSI_Period = 14;
input(name="Periodo media RSI") int RSI_MA_Period = 9;
input(name="Tipo media RSI") ENUM_MA_METHOD RSI_MA_Method = MODE_EMA;
input(name="Soglia RSI BUY") double RSI_BuyLevel = 55;
input(name="Soglia RSI SELL") double RSI_SellLevel = 45;
//======================== ╔═ MACD ═╗ ========================
input group "11 — INDICATORI — MACD";
input(name="MACD periodo veloce") int MACD_Fast = 12;
input(name="MACD periodo lento") int MACD_Slow = 26;
input(name="MACD periodo segnale") int MACD_Signal = 9;
//======================== ╔═ STOCHASTIC ═╗ ========================
input group "11 — INDICATORI — STOCASTICO";
input(name="Stocastico K") int Stoch_K = 10;
input(name="Stocastico D") int Stoch_D = 3;
input(name="Stocastico rallentamento") int Stoch_Slow = 6;
input(name="Metodo Stocastico") ENUM_MA_METHOD StochMethod = MODE_SMA;
input(name="Prezzo Stocastico") ENUM_STO_PRICE StochPrice = STO_LOWHIGH;
//======================== ╔═ EMA STACK ═╗ ========================
input group "11 — INDICATORI — EMA";
input(name="EMA veloce 1") int EMA_1 = 5;
input(name="EMA veloce 2") int EMA_2 = 10;
input(name="EMA media") int EMA_3 = 50;
input(name="EMA lenta 1") int EMA_4 = 100;
input(name="EMA lenta 2") int EMA_5 = 200;
input(name="Metodo medie EMA") ENUM_MA_METHOD EMA_Method = MODE_EMA;
//======================== ╔═ ADX ═╗ ========================
input group "11 — INDICATORI — ADX";
input(name="Periodo ADX") int ADX_Period = 14;
input(name="Forza minima ADX") double ADX_MinTrend = 20;
//======================== ╔═ SAR ═╗ ========================
input group "11 — INDICATORI — SAR";
input(name="SAR passo") double SAR_Step = 0.02;
input(name="SAR massimo") double SAR_Max = 0.2;
//======================== ╔═ ATR ═╗ ========================
input group "11 — INDICATORI — ATR";
input(name="Periodo ATR") int ATR_Period = 14;
input(name="Usa filtro volatilita minima ATR") bool UseATRVolatilityFilter = true;
input(name="ATR minimo in punti") double MinATR_Points = 50;
//======================== ╔═ PIVOT POINTS PRO ═╗ ========================
enum PivotCalcMode
{
   PIVOT_CLASSIC = 0,
   PIVOT_FIBO = 1,
   PIVOT_WOODIE = 2,
   PIVOT_CAMARILLA = 3
};
enum PivotLabelMode
{
   PIVOT_LABEL_OFF = 0,
   PIVOT_LABEL_TAG_ONLY = 1,
   PIVOT_LABEL_TAG_PRICE = 2
};
input group "12 — PIVOT — GENERALE";
input bool EnablePivots = true;
input PivotCalcMode PivotMode = PIVOT_CLASSIC;
input string PivotPrefix = "PPIV_";
input group "12 — PIVOT — TIMEFRAME";
input bool PivotDaily_Enable = true;
input bool PivotWeekly_Enable = true;
input bool PivotMonthly_Enable = true;
input group "12 — PIVOT — LIVELLI";
input bool PivotShowP = true;
input bool PivotShowR1 = true;
input bool PivotShowR2 = true;
input bool PivotShowR3 = true;
input bool PivotShowR4 = true;
input bool PivotShowR5 = true;
input bool PivotShowS1 = true;
input bool PivotShowS2 = true;
input bool PivotShowS3 = true;
input bool PivotShowS4 = true;
input bool PivotShowS5 = true;
input group "12 — PIVOT — ETICHETTE";
input PivotLabelMode PivotLabels = PIVOT_LABEL_TAG_PRICE;
input string PivotLabelFont = "Consolas";
input int PivotLabelFontSize = 9;
input int PivotLabelXOffset = 10; // px dal bordo destro
input int PivotLabelYOffset = 0; // px su/giù
input group "12 — PIVOT — STILE DAILY";
input color PivotD_ColorP = clrWhite;
input color PivotD_ColorR = clrLime;
input color PivotD_ColorS = clrTomato;
input ENUM_LINE_STYLE PivotD_Style = STYLE_SOLID;
input int PivotD_Width = 1;
input group "12 — PIVOT — STILE WEEKLY";
input color PivotW_ColorP = clrAqua;
input color PivotW_ColorR = clrGreen;
input color PivotW_ColorS = clrRed;
input ENUM_LINE_STYLE PivotW_Style = STYLE_DASH;
input int PivotW_Width = 1;
input group "12 — PIVOT — STILE MONTHLY";
input color PivotM_ColorP = clrGold;
input color PivotM_ColorR = clrLimeGreen;
input color PivotM_ColorS = clrMagenta;
input ENUM_LINE_STYLE PivotM_Style = STYLE_DOT;
input int PivotM_Width = 1;
//====================================================================
// FILTRI AVANZATI SEMPLIFICATI — FASE 6
// Manteniamo solo il trend del timeframe superiore come autorizzazione direzionale.
// Extra Confirmation, Regime Volatilita secondario e Stabilita candele sono stati rimossi
// dal percorso di ingresso per evitare filtri sovrapposti e rendere il motore leggibile.
//====================================================================
input group "13 — FILTRO TREND SUPERIORE";
input(name="Usa filtro trend timeframe superiore") bool UseHTFTrendConfirm = true;
input(name="Timeframe trend superiore") ENUM_TIMEFRAMES HTF_Trend_TF = PERIOD_H4;
input(name="Periodo EMA trend superiore") int HTF_Trend_EMA = 50;

// Costanti interne di compatibilita: non sono esposte all'utente.
const bool UseExtraConfirmLayer = false;
const int ExtraConfirmScoreRequired = 0;
const bool UseVolatilityRegime = false;
const int ATR_Regime_Period = 20;
const double ATR_Regime_MinRatio = 0.90;
const bool UseSignalStability = false;
const int StabilityBars = 0;
const bool UseSARFlipConfirm = false;
const double SAR_MinDistance_Points = 50.0;
//======================== GLOBALS =========================
CTrade g_trade;
datetime g_lastBarTimePanel = 0;
datetime g_lastBarTimeSignal = 0;
datetime g_lastOvernightActionDay = 0;
datetime g_lastSummaryTick = 0;
int g_lastSignalBarIndex = -100000;
int g_lastSignalBar = -100000;
string g_lastSignalDirection = "";
// Day / Week tracking
datetime g_dayStartTime = 0;
datetime g_weekStartTime = 0;
datetime lastKnownMonday = 0;   // ←←← AGGIUNGI QUESTA RIGA
double g_dayStartBalance = 0.0;
double g_weekStartBalance = 0.0;
bool g_dayTargetNotified = false;
bool g_weekTargetNotified = false;
// News cache (panel/debug)
bool g_newsBlockedNow = false;
string g_newsReason = "";
datetime g_newsNearestTime= 0;
// Indicator handles
int hMACD = INVALID_HANDLE;
int hRSI = INVALID_HANDLE;
int hStoch = INVALID_HANDLE;
int hATR = INVALID_HANDLE;
int hADX = INVALID_HANDLE;
int hSAR = INVALID_HANDLE;
int hMA1 = INVALID_HANDLE;
int hMA2 = INVALID_HANDLE;
int hMA3 = INVALID_HANDLE;
int hMA4 = INVALID_HANDLE;
int hMA5 = INVALID_HANDLE;
int hHTFTrend = INVALID_HANDLE;
int hATR_Regime = INVALID_HANDLE;
//PIVOT POINTS
datetime g_lastPivotDay = 0;
datetime g_lastPivotWeek = 0;
datetime g_lastPivotMonth = 0;
datetime g_piv_last_chart_change = 0;
double g_eqPeak = 0.0;
bool g_eqArmed = false;
datetime g_eqLastClose = 0;

// NEW: Cache ATR per ottimizzazione
double g_cachedATR = 0.0;
datetime g_lastATRTime = 0;
// Aggiungi una mappa/tabella di "ultimo evento per ticket" con timestamp.
datetime g_lastTgTicketTime[];
ulong    g_lastTgTicket[];
// NEW: Array per tracciare deal (per profitto robusto)
struct TrackedDeal {
   ulong ticket;
   datetime time;
   double profit;
   double comm;
   double swap;
   double fee;
   string symbol;
   long magic;
};
TrackedDeal g_trackedDeals[];
int g_trackedDealsCount = 0;

bool PositionPassFilters(); // Forward declaration

//======================== PANEL UPDATE FLAGS =========================
bool g_piv_needRedraw = false;   // ridisegna pivots solo quando cambia il chart

//======================== PANEL CACHE (anti-flicker) =========================
string g_rowTextCache[];
color  g_rowColorCache[];
bool   g_cacheInit = false;

int RowIndexById(const string id)
{
   for(int i=0;i<ArraySize(Rows);i++)
      if(Rows[i]==id) return i;
   return -1;
}

void InitPanelCache()
{
   int n = ArraySize(Rows);
   ArrayResize(g_rowTextCache, n);
   ArrayResize(g_rowColorCache, n);
   for(int i=0;i<n;i++){ g_rowTextCache[i]=""; g_rowColorCache[i]=clrNONE; }
   g_cacheInit = true;
}

//======================== PANEL ROWS =========================
string Rows[]=
{
   "TITLE",
   "CANDLE_TIMER",
   "ACC_BAL",
   "ACC_EQU",
   "DAY_START",
   "DAY_PROFIT",
   "DAY_CLOSED",   // ✅ NEW
   "DAY_FLOAT",    // ✅ NEW
   "DAY_TARGET",
   "DAY_REMAIN",
   "DAY_STATUS",
   "SEP1",
   "WEEK_START",
   "WEEK_PROFIT",
   "WEEK_TARGET",
   "WEEK_REMAIN",
   "WEEK_STATUS",
   "SEP2",
   "NEWS_STATUS",
   "NEWS_NEXT",
   "SEP3",
   "SIG_SCORE",
   "SIG_BASE",
   "SIG_FILTERED",
   "SIG_STATUS",
   "SIG_CHECKS",
   "SIG_RSI",
   "SIG_RSI_MA",
   "SIG_MACD",
   "SIG_STOCH",
   "SIG_EMA",
   "EMA5",      // ← nuova riga
   "EMA10",     // ← nuova riga
   "EMA50",     // ← nuova riga
   "EMA100",    // ← nuova riga
   "EMA200",    // ← nuova riga
   "SIG_ADX",
   "SIG_SAR",
   "SIG_ATR",
   "FLAG_HTF",
   "FLAG_VOL",
};

string MakeSepLine(int n=34)
{
   string s="";
   for(int i=0;i<n;i++) s += "—";   // puoi cambiare in "-" se preferisci
   return s;
}
//======================== LOG =========================
void Dbg(const string msg){
   if(EnableDebugLog) Print(msg);
   if(EnableLogFile){
      int f = FileOpen("EA_Log.txt", FILE_READ|FILE_WRITE|FILE_TXT|FILE_ANSI);
      if(f != INVALID_HANDLE){
         FileSeek(f,0,SEEK_END);
         FileWrite(f, TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS) + " | " + msg);
         FileClose(f);
      }
   }
}
//======================== SAFE TEXT =========================
string BoolToText(const bool v, const string onText="OK", const string offText="BAD")
{
   return (v ? onText : offText);
}
string U64ToStr(const ulong v)
{
   return StringFormat("%I64u", v);
}
//======================== UTILS =========================
double NormalizeVolume(double vol)
{
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   double minv=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maxv=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   if(step<=0) step=0.01;
   vol = MathFloor(vol/step)*step;
   if(vol<minv) vol=minv;
   if(vol>maxv) vol=maxv;
   int prec=2;
   if(step<0.1) prec=3;
   if(step<0.01) prec=4;
   return NormalizeDouble(vol,prec);
}
bool IsVolumeValid(double vol)
{
   double step=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
   double minv=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double maxv=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MAX);
   if(vol<minv || vol>maxv) return false;
   if(step<=0) return true;
   double k = vol/step;
   double diff = MathAbs(k - MathRound(k));
   return (diff < 1e-8);
}
bool SpreadOK()
{
   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double sp=(ask-bid)/_Point;
   return (sp <= MaxSpreadPoints);
}

bool IsNewBarForPanel()
{
   datetime t = iTime(_Symbol, _Period, 0);
   if(t != g_lastBarTimePanel)
   {
      g_lastBarTimePanel = t;
      return true;
   }
   return false;
}

bool IsNewBarForSignal()
{
   datetime t = iTime(_Symbol, _Period, 0);
   if(t != g_lastBarTimeSignal)
   {
      g_lastBarTimeSignal = t;
      return true;
   }
   return false;
}


string GetCandleTimeLeft()
{
   datetime lastBar=iTime(_Symbol,_Period,0);
   int tfsec=PeriodSeconds(_Period);
   datetime closeTime=lastBar + tfsec;
   int left=(int)(closeTime - TimeCurrent());
   if(left<0) left=0;
   int h=left/3600;
   int m=(left%3600)/60;
   int s=left%60;
   return StringFormat("%02d:%02d:%02d",h,m,s);
}
bool IsFirstDayOfMonth(datetime t)
{
   MqlDateTime x; TimeToStruct(t,x);
   return (x.day==1);
}
bool IsLastDayOfMonth(datetime t)
{
   MqlDateTime x; TimeToStruct(t,x);
   MqlDateTime y=x; y.hour=0; y.min=0; y.sec=0;
   datetime d0=StructToTime(y);
   datetime d1=d0+86400;
   MqlDateTime n; TimeToStruct(d1,n);
   return (n.mon!=x.mon);
}
bool IsAllowedWeekday(datetime t)
{
   MqlDateTime x; TimeToStruct(t,x);
   int w=x.day_of_week; // 0=Sun..6=Sat
   if(w==1) return TradeMon;
   if(w==2) return TradeTue;
   if(w==3) return TradeWed;
   if(w==4) return TradeThu;
   if(w==5) return TradeFri;
   if(w==6) return TradeSat;
   return TradeSun;
}
bool IsAllowedTime(datetime t)
{
   if(Trading24H) return true;
   if(!UseTradingHours) return true;
   MqlDateTime x; TimeToStruct(t,x);
   int nowMin=x.hour*60 + x.min;
   int a=TradingStartHour*60 + TradingStartMinute;
   int b=TradingEndHour*60 + TradingEndMinute;
   if(a==b) return true;
   if(a<b) return (nowMin>=a && nowMin<=b);
   return (nowMin>=a || nowMin<=b);
}
bool IsWeekendNewTradeBlocked(datetime t)
{
   if(!UseWeekendProtection) return false;
   MqlDateTime x; TimeToStruct(t,x);
   int nowMin=x.hour*60+x.min;
   int friStop=FridayStopNewTradesHour*60+FridayStopNewTradesMinute;
   int monResume=MondayResumeHour*60+MondayResumeMinute;
   if(x.day_of_week==5 && nowMin>=friStop) return true;
   if(x.day_of_week==6 || x.day_of_week==0) return true;
   if(MondayResumeFilter && x.day_of_week==1 && nowMin<monResume) return true;
   return false;
}

bool IsWeekendCloseTime(datetime t)
{
   if(!UseWeekendProtection || !ClosePositionsBeforeWeekend) return false;
   MqlDateTime x; TimeToStruct(t,x);
   if(x.day_of_week!=5) return false;
   int nowMin=x.hour*60+x.min;
   int closeMin=FridayClosePositionsHour*60+FridayClosePositionsMinute;
   return (nowMin>=closeMin);
}

bool IsTradingAllowedNow()
{
   datetime now=TimeCurrent();
   if(IsWeekendNewTradeBlocked(now)) return false;
   if(!IsAllowedWeekday(now)) return false;
   if(BlockFirstDayOfMonth && IsFirstDayOfMonth(now)) return false;
   if(BlockLastDayOfMonth && IsLastDayOfMonth(now)) return false;
   if(!IsAllowedTime(now)) return false;
   return true;
}
// NEW: Check if auto-trading is allowed (global + symbol)
bool IsAutoTradingEnabled()
{
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
      return false;

   long mode = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE);
   if(mode == SYMBOL_TRADE_MODE_DISABLED)
      return false;

   return true;
}

// ====================== HELPER: CALCOLA IL GIORNO DELL'ANNO (1-366) ======================
int GetDayOfYear(datetime dt)
{
   MqlDateTime s;
   TimeToStruct(dt, s);
   
   int days = s.day;
   for(int m = 1; m < s.mon; m++)
   {
      if(m == 2)
         days += 28 + ((s.year % 4 == 0 && (s.year % 100 != 0 || s.year % 400 == 0)) ? 1 : 0);
      else if(m == 4 || m == 6 || m == 9 || m == 11)
         days += 30;
      else
         days += 31;
   }
   return days;
}

//======================== DAY / WEEK START TIME (START CONTABILE) =========================
datetime GetTodayTargetTime()
{
   datetime now = TimeCurrent();
   MqlDateTime t;
   TimeToStruct(now, t);
   t.hour = 0;
   t.min  = 0;
   t.sec  = 0;
   datetime midnight = StructToTime(t);
   
   Dbg("GetTodayTargetTime → Mezzanotte: " + TimeToString(midnight, TIME_DATE|TIME_MINUTES));
   return midnight;
}

//======================== GET MONDAY TARGET TIME (v12.1 - ULTRA ROBUSTA) =========================
datetime GetMondayTargetTime()
{
   datetime now = TimeCurrent();
   MqlDateTime t;
   TimeToStruct(now, t);
   
   // Calcola il lunedì della settimana corrente
   int daysBack = t.day_of_week - 1;
   if(daysBack < 0) daysBack = 6; // domenica
   
   datetime monday = now - daysBack * 86400;
   
   // Applica esattamente l'orario configurato
   TimeToStruct(monday, t);
   t.hour = WeekStartHour;
   t.min  = WeekStartMinute;
   t.sec  = 0;
   
   datetime weekStart = StructToTime(t);
   
   // Se siamo ancora PRIMA dell'orario di inizio questa settimana → usiamo la settimana precedente
   if(now < weekStart)
      weekStart -= 7 * 86400;
   
   Dbg(StringFormat("GetMondayTargetTime → Lunedì calcolato: %s (ora start %02d:%02d)", 
                    TimeToString(weekStart, TIME_DATE|TIME_MINUTES), WeekStartHour, WeekStartMinute));
   
   return weekStart;
}

//======================== GET BALANCE AT DATETIME (VERSIONE ULTRA-ROBUSTA) =========================
double GetBalanceAtDatetime(datetime targetTime)
{
   if(!HistorySelect(0, TimeCurrent() + 86400)) 
   {
      Dbg("GetBalanceAtDatetime: HistorySelect fallito");
      return 0.0;
   }
   
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double adjustment = 0.0;
   int total = HistoryDealsTotal();
   
   Dbg(StringFormat("GetBalanceAtDatetime: scanning %d deals backward from target %s", total, TimeToString(targetTime)));

   for(int i = total - 1; i >= 0; i--)
   {
      ulong ticket = HistoryDealGetTicket(i);
      if(ticket == 0) continue;
      
      datetime dealTime = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
      if(dealTime < targetTime) break;   // fermati appena vai prima del lunedì
      
      long type  = HistoryDealGetInteger(ticket, DEAL_TYPE);
      long entry = HistoryDealGetInteger(ticket, DEAL_ENTRY);
      double profit = HistoryDealGetDouble(ticket, DEAL_PROFIT);
      double comm  = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
      double swap  = HistoryDealGetDouble(ticket, DEAL_SWAP);
      double fee   = HistoryDealGetDouble(ticket, DEAL_FEE);
      
      double change = profit + comm + swap + fee;
      
      if(type == DEAL_TYPE_BALANCE || type == DEAL_TYPE_CREDIT || type == DEAL_TYPE_CORRECTION ||
         type == DEAL_TYPE_BONUS || type == DEAL_TYPE_COMMISSION || type == DEAL_TYPE_CHARGE || 
         type == DEAL_TYPE_INTEREST)
         adjustment += change;
      else if(entry == DEAL_ENTRY_OUT)
         adjustment += change;
   }
   
   return NormalizeDouble(currentBalance - adjustment, 2);
}

//======================== CHECK WEEK START (v12.3 - STORICO FORZATO) =========================
void CheckWeekStart()
{
   datetime expectedWeek = GetMondayTargetTime();

   // FORZA storico su OGNI avvio / riattacco / nuovo lunedì
   if(g_weekStartTime == 0 || g_weekStartTime != expectedWeek || lastKnownMonday == 0 || g_weekStartBalance <= 0)
   {
      lastKnownMonday = expectedWeek;
      double histBalance = GetBalanceAtDatetime(expectedWeek);

      if(histBalance > 0.0)
      {
         g_weekStartTime    = expectedWeek;
         g_weekStartBalance = histBalance;
         g_weekTargetNotified = false;

         Dbg(StringFormat(">>> WEEK FIXED FROM HISTORY | Start=%s | Base=%.2f EUR (STORICO LUNEDÌ)",
                          TimeToString(expectedWeek, TIME_DATE|TIME_MINUTES), g_weekStartBalance));
      }
      else
      {
         g_weekStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
         Dbg("WARNING: History non trovato → fallback corrente");
      }
   }
}


double ProfitFloatingAllScoped()
{
   double p = 0.0;

   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong tk = PositionGetTicket(i);
      if(tk==0) continue;
      if(!PositionSelectByTicket(tk)) continue;
      if(!PositionPassFilters()) continue;

      p += PositionGetDouble(POSITION_PROFIT);
   }
   return p;
}


//======================== PROFIT CALCULATION (NEW: ROBUST TRACKING) =========================
void TrackNewDeals()
{
   datetime endTime = TimeCurrent() + 86400;
   if(!HistorySelect(g_dayStartTime, endTime))
   {
      Dbg("TrackNewDeals: HistorySelect fallito da " + TimeToString(g_dayStartTime) +
          " a " + TimeToString(endTime));
      return;
   }
  
   int total = HistoryDealsTotal();
   Dbg("TrackNewDeals: trovati " + IntegerToString(total) + " deal totali");
  
   for(int i = 0; i < total; i++)
   {
      ulong tk = HistoryDealGetTicket(i);
      if(tk == 0) continue;
     
      bool alreadyTracked = false;
      for(int j = 0; j < g_trackedDealsCount; j++)
         if(g_trackedDeals[j].ticket == tk) { alreadyTracked = true; break; }
      if(alreadyTracked) continue;
     
      long entry = (long)HistoryDealGetInteger(tk, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT) continue;
     
      datetime dt = (datetime)HistoryDealGetInteger(tk, DEAL_TIME);
      if(dt < g_dayStartTime) continue;
     
      string sym = HistoryDealGetString(tk, DEAL_SYMBOL);
      long mg = (long)HistoryDealGetInteger(tk, DEAL_MAGIC);
     
      TrackedDeal temp = {tk, dt, 0,0,0,0, sym, mg};
      if(!DealPassFilters(temp)) continue;
     
      double profit = HistoryDealGetDouble(tk, DEAL_PROFIT);
      double comm = HistoryDealGetDouble(tk, DEAL_COMMISSION);
      double swap = HistoryDealGetDouble(tk, DEAL_SWAP);
      double fee = HistoryDealGetDouble(tk, DEAL_FEE);
     
      int n = g_trackedDealsCount;
      ArrayResize(g_trackedDeals, n + 1);
      g_trackedDeals[n].ticket = tk;
      g_trackedDeals[n].time = dt;
      g_trackedDeals[n].profit = profit;
      g_trackedDeals[n].comm = comm;
      g_trackedDeals[n].swap = swap;
      g_trackedDeals[n].fee = fee;
      g_trackedDeals[n].symbol = sym;
      g_trackedDeals[n].magic = mg;
      g_trackedDealsCount++;
     
      Dbg(StringFormat("Tracked new deal: ticket=%I64u | time=%s | profit=%.2f | sym=%s | magic=%d",
                       tk, TimeToString(dt), profit, sym, (int)mg));
   }
}

bool DealPassFilters(const TrackedDeal &d)
{
   if(TrackWholeAccount) return true;
   if(TrackOnlyThisSymbol && d.symbol != _Symbol) return false;
   if(TrackOnlyThisMagic && d.magic != MagicNumber) return false;
   if(TrackOnlyThisEA && d.magic != MagicNumber) return false;
   return true;
}

double ProfitClosedFrom(datetime fromTime)
{
   double p = 0.0;
   for(int i = 0; i < g_trackedDealsCount; i++)
   {
      if(g_trackedDeals[i].time < fromTime) continue;
      if(!DealPassFilters(g_trackedDeals[i])) continue;
      p += g_trackedDeals[i].profit + g_trackedDeals[i].comm +
           g_trackedDeals[i].swap + g_trackedDeals[i].fee;
   }
   Dbg(StringFormat("ProfitClosedFrom: %.2f EUR da %s", p, TimeToString(fromTime)));
   return p;
}

double ProfitFloating()
{
   double p = 0.0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      if(!PositionSelectByTicket(tk)) continue;
      if(!PositionPassFilters()) continue;
      
      // NUOVO FILTRO: solo posizioni aperte dopo inizio giornata
      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      if(openTime < g_dayStartTime) continue; // ignora posizioni vecchie
      
      p += PositionGetDouble(POSITION_PROFIT);
   }
   Dbg(StringFormat("ProfitFloating: %.2f EUR (solo posizioni aperte dopo %s)", 
                    p, TimeToString(g_dayStartTime, TIME_DATE|TIME_MINUTES)));
   return p;
}
//======================== PROFIT (PARAMETRICO, NO DIPENDENZA DAY) =========================
double ProfitClosedFromHistory(datetime fromTime)
{
   datetime endTime = TimeCurrent() + 86400;
   if(!HistorySelect(fromTime, endTime))
   {
      Dbg("ProfitClosedFromHistory: HistorySelect fail");
      return 0.0;
   }

   double p = 0.0;
   int total = HistoryDealsTotal();

   for(int i=0; i<total; i++)
   {
      ulong tk = HistoryDealGetTicket(i);
      if(tk==0) continue;

      long entry = (long)HistoryDealGetInteger(tk, DEAL_ENTRY);
      if(entry != DEAL_ENTRY_OUT) continue;

      TrackedDeal d;
      d.ticket = tk;
      d.time   = (datetime)HistoryDealGetInteger(tk, DEAL_TIME);
      d.symbol = HistoryDealGetString(tk, DEAL_SYMBOL);
      d.magic  = (long)HistoryDealGetInteger(tk, DEAL_MAGIC);

      if(d.time < fromTime) continue;
      if(!DealPassFilters(d)) continue;

      double profit = HistoryDealGetDouble(tk, DEAL_PROFIT);
      double comm   = HistoryDealGetDouble(tk, DEAL_COMMISSION);
      double swap   = HistoryDealGetDouble(tk, DEAL_SWAP);
      double fee    = HistoryDealGetDouble(tk, DEAL_FEE);

      p += (profit + comm + swap + fee);
   }
   return p;
}

double ProfitFloatingFrom(datetime fromTime)
{
   double p = 0.0;

   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong tk = PositionGetTicket(i);
      if(tk==0) continue;
      if(!PositionSelectByTicket(tk)) continue;
      if(!PositionPassFilters()) continue;

      datetime openTime = (datetime)PositionGetInteger(POSITION_TIME);
      if(openTime < fromTime) continue;

      p += PositionGetDouble(POSITION_PROFIT);
   }
   return p;
}
double ProfitTotalSince(datetime startTime, double /*startBalanceSnapshot*/)
{
   // Profit = Closed deals (OUT) + Floating positions opened after startTime
   // Esclude automaticamente depositi/prelievi/balance transfer perché non sono DEAL_ENTRY_OUT (trading)
   double closed   = ProfitClosedFromHistory(startTime);
   double floating = ProfitFloatingFrom(startTime);
   return (closed + floating);
}

//======================== SIMPLE LOT SIZING =========================
// Calcola il lotto in modo robusto usando OrderCalcProfit su 1 lotto.
// In questo modo il rischio si adatta alle specifiche reali del simbolo/broker
// (Forex, Gold, indici, petrolio, crypto, ecc.).
double CalcLotByRisk(const string sig, const double entry_price, const double stop_price)
{
   if(entry_price <= 0 || stop_price <= 0 || entry_price == stop_price) return 0.0;
   if(RiskPercent <= 0) return 0.0;

   double risk_money = AccountInfoDouble(ACCOUNT_BALANCE) * RiskPercent / 100.0;
   if(risk_money <= 0) return 0.0;

   ENUM_ORDER_TYPE order_type = (sig == "BUY") ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   double loss_one_lot = 0.0;
   if(!OrderCalcProfit(order_type, _Symbol, 1.0, entry_price, stop_price, loss_one_lot))
   {
      Dbg("RISK LOT | OrderCalcProfit failed: " + IntegerToString(GetLastError()));
      return 0.0;
   }

   loss_one_lot = MathAbs(loss_one_lot);
   if(loss_one_lot <= 0) return 0.0;

   double lot = risk_money / loss_one_lot;
   lot = MathMin(lot, MaxLotSize);
   return NormalizeVolume(lot);
}

double CalculateTradeLot(const string sig, const double entry_price, const double stop_price)
{
   double lot = 0.0;

   if(LotMode == LOT_FIXED)
      lot = FixedLot;
   else
      lot = CalcLotByRisk(sig, entry_price, stop_price);

   lot = MathMin(lot, MaxLotSize);
   return NormalizeVolume(lot);
}

//======================== INIT DAY/WEEK (SOLO DAY) =========================
void InitDayWeek()
{
   datetime now = TimeCurrent();
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double currentEquity = AccountInfoDouble(ACCOUNT_EQUITY);

   // ===================== SOLO DAY =====================
   datetime expectedDayStart = GetTodayTargetTime();
   bool dayResetNeeded = (g_dayStartTime == 0) ||
                         (g_dayStartTime != expectedDayStart) ||
                         (g_dayStartBalance <= 0.0);

//   if(g_dayStartBalance > 0.0 && MathAbs(currentBalance - g_dayStartBalance) > currentBalance * 0.05)
  // {
    //  Dbg("DAY RESET FORCED >5%");
      //dayResetNeeded = true;
   //}

   if(dayResetNeeded)
   {
      g_dayStartTime = expectedDayStart;
      g_dayStartBalance = (currentBalance > 0.0 ? currentBalance : currentEquity);
      g_dayTargetNotified = false;
      ArrayResize(g_trackedDeals, 0);
      g_trackedDealsCount = 0;
      Dbg(StringFormat("DAY RESET OK | Start=%s | Base=%.2f", 
                       TimeToString(expectedDayStart, TIME_DATE|TIME_MINUTES), g_dayStartBalance));
   }
}
  
//======================== EMAIL SENDER =========================
void SendTargetEmail(const bool weekly, const double profit, const double target)
{
   if(!SendEmailOnTarget) return;
   string subject = (weekly ? EmailSubjectWeek : EmailSubjectDay);
   string body =
      (weekly ? "TARGET SETTIMANALE RAGGIUNTO\n\n" : "TARGET GIORNALIERO RAGGIUNTO\n\n");
   body += "Time: " + TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES) + "\n";
   body += "Profit: " + DoubleToString(profit,2) + "\n";
   body += "Target: " + DoubleToString(target,2) + "\n";
   body += "Magic: " + IntegerToString((int)MagicNumber) + "\n";
   body += "Mode: " + (TrackWholeAccount ? "WHOLE_ACCOUNT" : "FILTERED") + "\n";
   body += "EmailTo(Hint): " + EmailToHint + "\n";
   body += "\nNOTE: MT5 invia al destinatario configurato in Terminale -> Opzioni -> Email.\n";
   SendMail(subject, body);
}

//======================== TARGET CHECK (EMAIL) v11.25 — DEBUG + ANTI-SPAM ========================
void CheckTargetsAndNotify()
{
   static datetime lastCheck = 0;
   static datetime lastEmailSent = 0;
   datetime now = TimeCurrent();

   // Controlla SOLO ogni 60 secondi (non più spesso)
   if(now - lastCheck < 60) return;
   lastCheck = now;

   Dbg("=== CHECK TARGETS START ===");

   // === DAY TARGET ===
   double dTotal  = ProfitTotalSince(g_dayStartTime, g_dayStartBalance);
   double dTarget = g_dayStartBalance * DailyTargetPercent / 100.0;

   Dbg(StringFormat("DAY  | Total=%.2f | Target=%.2f | Notified=%s | SendEmail=%s | CooldownOK=%s",
                    dTotal, dTarget,
                    g_dayTargetNotified ? "true" : "false",
                    SendEmailOnTarget ? "true" : "false",
                    (now - lastEmailSent > 3600) ? "OK" : "NO"));

   if(SendEmailOnTarget && !g_dayTargetNotified && dTotal >= dTarget && (now - lastEmailSent > 3600))
   {
      Dbg(">>> INVIO MAIL DAY TARGET RAGGIUNTO (1 volta sola!)");
      SendTargetEmail(false, dTotal, dTarget);
      g_dayTargetNotified = true;
      lastEmailSent = now;
   }

   if(dTotal < dTarget * 0.95)
      g_dayTargetNotified = false;

   // === WEEK TARGET ===
   if(EnableWeeklyTarget)
   {
      double wTotal  = ProfitTotalSince(g_weekStartTime, g_weekStartBalance);
      double wTarget = g_weekStartBalance * (MathPow(1.0 + DailyTargetPercent/100.0, 5) - 1.0);

      Dbg(StringFormat("WEEK | Total=%.2f | Target=%.2f | Notified=%s | CooldownOK=%s",
                       wTotal, wTarget,
                       g_weekTargetNotified ? "true" : "false",
                       (now - lastEmailSent > 3600) ? "OK" : "NO"));

      if(SendEmailOnTarget && !g_weekTargetNotified && wTotal >= wTarget && (now - lastEmailSent > 3600))
      {
         Dbg(">>> INVIO MAIL WEEK TARGET RAGGIUNTO (1 volta sola!)");
         SendTargetEmail(true, wTotal, wTarget);
         g_weekTargetNotified = true;
         lastEmailSent = now;
      }

      if(wTotal < wTarget * 0.95)
         g_weekTargetNotified = false;
   }

   Dbg("=== CHECK TARGETS END ===");
}


//======================== PANEL UI =========================
void CreateLabels()
{
   int y = OffsetY;

   for(int i=0; i<ArraySize(Rows); i++)
   {
      string n = "PP_" + Rows[i];

      ObjectDelete(0, n);
      ObjectCreate(0, n, OBJ_LABEL, 0, 0, 0);

      ObjectSetInteger(0, n, OBJPROP_CORNER,   PanelCorner);
      ObjectSetInteger(0, n, OBJPROP_XDISTANCE, OffsetX);
      ObjectSetInteger(0, n, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, n, OBJPROP_FONTSIZE, FontSize);
      ObjectSetString (0, n, OBJPROP_FONT,     FontName);
      ObjectSetInteger(0, n, OBJPROP_COLOR,    TextColor);

      // IMPORTANT: niente placeholder "Label"
      ObjectSetString(0, n, OBJPROP_TEXT, "");

      y += LineGap;
   }
}

void HideWeeklyRows(const bool hide)
{
   string weekly[]={"WEEK_START","WEEK_PROFIT","WEEK_TARGET","WEEK_REMAIN","WEEK_STATUS"};
   for(int i=0;i<ArraySize(weekly);i++)
   {
      string n="PP_"+weekly[i];
      if(ObjectFind(0,n)>=0) ObjectSetInteger(0,n,OBJPROP_HIDDEN,hide);
   }
}

void SetRow(const string id, const string txt, const color c)
{
   string n="PP_"+id;
   if(ObjectFind(0,n)<0) return;

   string t = txt;
   if(StringLen(t)==0) t = " ";

   if(!g_cacheInit) InitPanelCache();
   int idx = RowIndexById(id);
   if(idx >= 0)
   {
      // Se testo e colore sono identici, NON tocco l’oggetto -> niente flicker
      if(g_rowTextCache[idx] == t && g_rowColorCache[idx] == c)
         return;

      g_rowTextCache[idx]  = t;
      g_rowColorCache[idx] = c;
   }

   ObjectSetString (0, n, OBJPROP_TEXT,  t);
   ObjectSetInteger(0, n, OBJPROP_COLOR, c);
}

//======================== BUFFER READ (MT5) =========================
bool GetVal(const int handle, const int buffer, const int shift, double &out)
{
   out=0.0;
   if(handle==INVALID_HANDLE) return false;
   double arr[];
   ArraySetAsSeries(arr,true);
   if(CopyBuffer(handle, buffer, shift, 1, arr)<=0) return false;
   out=arr[0];
   return true;
}
double GetATRValue()
{
   if(hATR==INVALID_HANDLE) return 0.0;
   datetime now = iTime(_Symbol,_Period,0);
   if(now == g_lastATRTime && g_cachedATR > 0.0) return g_cachedATR; // NEW: cache
   double v[];
   ArraySetAsSeries(v,true);
   if(CopyBuffer(hATR,0,0,1,v)<=0) return 0.0;
   g_cachedATR = v[0];
   g_lastATRTime = now;
   return g_cachedATR;
}
double CalcRSIMA(const int shift)
{
   if(hRSI==INVALID_HANDLE) return 0.0;
   int need = RSI_MA_Period + shift + 10;
   double rsiArr[];
   ArraySetAsSeries(rsiArr,true);
   if(CopyBuffer(hRSI,0,0,need,rsiArr)<=0) return 0.0;
   if(RSI_MA_Period<=1) return rsiArr[shift];
   if(RSI_MA_Method==MODE_SMA)
   {
      double sum=0.0;
      for(int i=shift; i<shift+RSI_MA_Period; i++) sum += rsiArr[i];
      return sum/(double)RSI_MA_Period;
   }
   double k=2.0/(RSI_MA_Period+1.0);
   int start=shift + RSI_MA_Period - 1;
   double seed=0.0;
   for(int i=start; i>start-RSI_MA_Period; i--) seed += rsiArr[i];
   double ema=seed/(double)RSI_MA_Period;
   for(int i=start-1; i>=shift; i--)
      ema = rsiArr[i]*k + ema*(1.0-k);
   return ema;
}

//======================== NEWS FILTER — PROTOTYPES =========================
bool   IsNewsBlockedNow();
int    CalendarGetNearestBlockingEvent(datetime now, datetime &nearestTime, string &nearestText);

//======================== NEWS FILTER HELPERS =========================
int ImpactToCalendar(const NewsImpactLevel lvl)
{
   if(lvl==NEWS_IMPACT_LOW) return 0;
   if(lvl==NEWS_IMPACT_MEDIUM) return 1;
   return 2;
}
string Trim(const string s)
{
   string r=s;
   StringTrimLeft(r);
   StringTrimRight(r);
   return r;
}
bool SplitCSV(const string csv, string &outArr[])
{
   ArrayResize(outArr,0);
   string tmp = csv;
   StringReplace(tmp, ";", ",");
   StringReplace(tmp, "|", ",");
   StringReplace(tmp, " ", "");
   if(StringLen(tmp)<=0) return false;
   string parts[];
   int n=StringSplit(tmp, ',', parts);
   if(n<=0) return false;
   int k=0;
   ArrayResize(outArr,n);
   for(int i=0;i<n;i++)
   {
      string v=Trim(parts[i]);
      if(StringLen(v)<=0) continue;
      outArr[k]=v;
      k++;
   }
   ArrayResize(outArr,k);
   return (k>0);
}
bool InList(const string v, const string &arr[])
{
   for(int i=0;i<ArraySize(arr);i++)
      if(arr[i]==v) return true;
   return false;
}
bool GetSymbolCurrencies(string &base, string &quote)
{
   base="";
   quote="";
   string b = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_BASE);
   string p = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);
   if(StringLen(b)>=3) base=b;
   if(StringLen(p)>=3) quote=p;
   if(StringLen(base)<3 || StringLen(quote)<3)
   {
      string sym=_Symbol;
      int dot=StringFind(sym,".");
      if(dot>0) sym=StringSubstr(sym,0,dot);
      int len=(int)StringLen(sym);
      if(len>=6)
      {
         string p1=StringSubstr(sym,0,3);
         string p2=StringSubstr(sym,3,3);
         if(StringLen(base)<3) base=p1;
         if(StringLen(quote)<3) quote=p2;
      }
   }
   return (StringLen(base)>=3 && StringLen(quote)>=3);
}
int CalendarGetNearestBlockingEvent(datetime now, datetime &nearestTime, string &nearestText)
{
   nearestTime = 0;
   nearestText = "";

   if(!EnableNewsFilter) return 0;

   // --- currencies list
   string ccys[];
   ArrayResize(ccys,0);

   if(NewsCurrenciesMode==NEWS_CCY_CUSTOM)
   {
      if(!SplitCSV(NewsCurrenciesCustomCSV, ccys))
         return 0;
   }
   else
   {
      string base="", quote="";
      if(GetSymbolCurrencies(base, quote))
      {
         ArrayResize(ccys,2);
         ccys[0]=base;
         ccys[1]=quote;
      }
      else return 0;
   }

   int minImp = ImpactToCalendar(MinNewsImpactToBlock);

   datetime from = now - (NoTradeMinutesBefore * 60);
   datetime to   = now + ((NewsLookAheadMinutes + NoTradeMinutesAfter) * 60);

   MqlCalendarValue values[];
   int n = CalendarValueHistory(values, from, to);
   if(n<=0) return 0;

   bool foundNext=false;
   datetime nextTime=0;
   string nextText="";

   for(int i=0;i<n;i++)
   {
      MqlCalendarEvent ev;
      if(!CalendarEventById(values[i].event_id, ev)) continue;
      if((int)ev.importance < minImp) continue;

      MqlCalendarCountry ctry;
      if(!CalendarCountryById(ev.country_id, ctry)) continue;
      string ccy = ctry.currency;
      if(StringLen(ccy)<3) continue;
      if(!InList(ccy, ccys)) continue;

      datetime eventTime = (datetime)values[i].time;
      datetime wStart = eventTime - (NoTradeMinutesBefore*60);
      datetime wEnd   = eventTime + (NoTradeMinutesAfter*60);

      string impTxt = (ev.importance==0 ? "LOW" : (ev.importance==1 ? "MED" : "HIGH"));
      string thisText = StringFormat("%s %s | %s | %s",
                                     ccy,
                                     impTxt,
                                     TimeToString(eventTime, TIME_DATE|TIME_MINUTES),
                                     ev.name);

      // 1) se siamo dentro finestra -> BLOCK immediato e testo corretto
      if(now>=wStart && now<=wEnd)
      {
         nearestTime = eventTime;
         nearestText = "BLOCK: " + thisText;
         return 1;
      }

      // 2) NEXT = prossimo evento futuro più vicino (eventTime >= now)
      if(eventTime >= now)
      {
         if(!foundNext || eventTime < nextTime)
         {
            foundNext=true;
            nextTime=eventTime;
            nextText="NEXT: " + thisText;
         }
      }
   }

   // Se non bloccato, ma c'è un NEXT e lo vuoi mostrare
   if(foundNext && ShowNearestNewsOnPanel)
   {
      nearestTime = nextTime;
      nearestText = nextText;
   }

   return 0;
}
//======================== SIGNAL ENGINE CORE =========================
void CalcSignalPro(int &bull,int &bear,
                   double &rsi,double &rsima,
                   double &macdMain,double &macdSig,
                   double &k,double &d,
                   double &e1,double &e2,double &e3,double &e4,double &e5,
                   double &adx,double &pdi,double &mdi,
                   double &sar,double &atr1,double &atr2)
{
   bull=0; bear=0;
   rsi=rsima=macdMain=macdSig=k=d=e1=e2=e3=e4=e5=adx=pdi=mdi=sar=atr1=atr2=0.0;
   if(UseRSI_Filter)
   {
      double tmp=0.0;
      if(GetVal(hRSI,0,1,tmp)) rsi=tmp;
      rsima = CalcRSIMA(1);
      if(rsi > RSI_BuyLevel && rsi > rsima) bull += Weight_RSI;
      else if(rsi < RSI_SellLevel && rsi < rsima) bear += Weight_RSI;
   }
   if(UseMACD_Filter)
   {
      double mm=0.0, ms=0.0;
      GetVal(hMACD,0,1,mm);
      GetVal(hMACD,1,1,ms);
      macdMain=mm; macdSig=ms;
      if(macdMain > macdSig) bull += Weight_MACD;
      else bear += Weight_MACD;
   }
   if(UseStoch_Filter)
   {
      double kk=0.0, dd=0.0;
      GetVal(hStoch,0,1,kk);
      GetVal(hStoch,1,1,dd);
      k=kk; d=dd;
      if(k > d) bull += Weight_STO;
      else bear += Weight_STO;
   }
   if(UseEMA_Filter)
   {
      GetVal(hMA1,0,1,e1);
      GetVal(hMA2,0,1,e2);
      GetVal(hMA3,0,1,e3);
      GetVal(hMA4,0,1,e4);
      GetVal(hMA5,0,1,e5);
      if(e1>e2 && e2>e3 && e3>e4 && e4>e5) bull += Weight_EMA;
      if(e1<e2 && e2<e3 && e3<e4 && e4<e5) bear += Weight_EMA;
   }
   if(UseADX_Filter)
   {
      GetVal(hADX,0,1,adx);
      GetVal(hADX,1,1,pdi);
      GetVal(hADX,2,1,mdi);
      if(adx >= ADX_MinTrend)
      {
         if(pdi > mdi) bull += Weight_ADX;
         else bear += Weight_ADX;
      }
   }
   if(UseSAR_Filter)
   {
      GetVal(hSAR,0,1,sar);
      double c1=iClose(_Symbol,_Period,1);
      if(c1 > sar) bull += Weight_SAR;
      else bear += Weight_SAR;
   }
   // ATR non e un voto: viene sempre letto per volatilita, SL e gestione rischio.
   GetVal(hATR,0,1,atr1);
   GetVal(hATR,0,2,atr2);
}
string GetSignalPro(const int bull, const int bear, const double atr1)
{
   if(!UseSignalEngine) return "OFF";
   if(UseATRVolatilityFilter && MinATR_Points>0)
   {
      double minAtr = MinATR_Points * _Point;
      if(atr1 < minAtr) return "NO VOL";
   }
   if(bull >= Confirmation_Count && bull > bear) return "BUY";
   if(bear >= Confirmation_Count && bear > bull) return "SELL";
   return "NEUTRAL";
}
//======================== STEP A — EXTRA CONFIRM SCORE =========================
int ExtraConfirmScore(const double atr1, const double sar)
{
   if(!UseExtraConfirmLayer) return 0;
   int score=0;
   double close1=iClose(_Symbol,_Period,1);
   double distSarPts = MathAbs(close1 - sar) / _Point;
   if(distSarPts >= SAR_MinDistance_Points) score++;
   double body = MathAbs(iClose(_Symbol,_Period,1) - iOpen(_Symbol,_Period,1));
   if(atr1>0 && body > atr1*0.5) score++;
   if(close1 > iHigh(_Symbol,_Period,2) || close1 < iLow(_Symbol,_Period,2)) score++;
   if(UseSARFlipConfirm && UseSAR_Filter && hSAR!=INVALID_HANDLE)
   {
      double sarPrev=0.0;
      if(GetVal(hSAR,0,2,sarPrev))
      {
         bool flipBull = (iClose(_Symbol,_Period,2) < sarPrev && close1 > sar);
         bool flipBear = (iClose(_Symbol,_Period,2) > sarPrev && close1 < sar);
         if(flipBull || flipBear) score++;
      }
   }
   return score;
}
//======================== STEP B — HTF TREND SCORE =========================
int HTFTrendScore()
{
   if(!UseHTFTrendConfirm || hHTFTrend==INVALID_HANDLE) return 0;
   double ema=0.0;
   if(!GetVal(hHTFTrend,0,1,ema)) return 0;
   double price=iClose(_Symbol,_Period,1);
   if(price > ema) return 1;
   if(price < ema) return -1;
   return 0;
}
//======================== STEP C — VOLATILITY REGIME =========================
bool IsVolatilityGood(const double atrFast)
{
   if(!UseVolatilityRegime || hATR_Regime==INVALID_HANDLE) return true;
   double atrSlow=0.0;
   if(!GetVal(hATR_Regime,0,1,atrSlow)) return true;
   double ratio = ATR_Regime_MinRatio;
   if(ratio < 0.50) ratio = 0.50;
   if(ratio > 1.50) ratio = 1.50;
   return (atrFast > atrSlow * ratio);
}
//======================== STEP D — STABILITY =========================
bool SignalStable(const string sig)
{
   if(!UseSignalStability) return true;
   if(sig!="BUY" && sig!="SELL") return true;
   int ok=0;
   for(int i=1;i<=StabilityBars;i++)
   {
      double o=iOpen(_Symbol,_Period,i);
      double c=iClose(_Symbol,_Period,i);
      if(sig=="BUY" && c>o) ok++;
      if(sig=="SELL" && c<o) ok++;
   }
   return (ok==StabilityBars);
}
//======================== STEP E — FINAL FILTER =========================
string FinalSignalFilter(const string baseSig,
                         const int bull,const int bear,
                         const double atr1,const double sar,
                         int &outExtraScore,
                         int &outHTFScore,
                         bool &outVolOk,
                         bool &outStable)
{
   outExtraScore=0;
   outHTFScore=0;
   outVolOk=true;
   outStable=true;
   if(baseSig=="OFF") return baseSig;
   if(baseSig=="NEUTRAL") return baseSig;
   if(baseSig=="NO VOL") return baseSig;
   // Fase 6: il segnale base e gia filtrato dall'ATR minimo.
   // L'unico filtro direzionale avanzato rimasto e il trend del timeframe superiore.
   outExtraScore = 0;
   outHTFScore = HTFTrendScore();
   outVolOk = true;
   outStable = true;
   if(outHTFScore>0 && baseSig=="SELL") return "HTF_CONFLICT";
   if(outHTFScore<0 && baseSig=="BUY") return "HTF_CONFLICT";
   return baseSig;
}

//======================== COUNT OPEN POSITIONS (COERENTE CON MODE) =========================
int CountOpenPositionsFiltered()
{
   int c=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong tk = PositionGetTicket(i);
      if(tk==0) continue;
      if(!PositionSelectByTicket(tk)) continue;
      if(!PositionPassFilters()) continue;
      c++;
   }
   return c;
}

// ====================== POSITION PASS FILTERS (definizione corretta) ======================
bool PositionPassFilters()
{
   if(TrackWholeAccount) return true;
   string sym=PositionGetString(POSITION_SYMBOL);
   if(TrackOnlyThisSymbol && sym!=_Symbol) return false;
   long mg=(long)PositionGetInteger(POSITION_MAGIC);
   if(TrackOnlyThisMagic && mg!=MagicNumber) return false;
   if(TrackOnlyThisEA && mg!=MagicNumber) return false; // NEW
   return true;
}

//======================== EXECUTE TRADE (multi orders with retry) =========================
bool SendOneMarketOrderWithRetry(const string sig, const double lot, const double price,
                                 const double sl, const double tp, const ENUM_ORDER_TYPE_FILLING fillType)
{
   MqlTradeRequest req;
   MqlTradeResult res;
   ZeroMemory(req);
   ZeroMemory(res);

   req.action       = TRADE_ACTION_DEAL;
   req.symbol       = _Symbol;
   req.volume       = lot;
   req.magic        = MagicNumber;
   req.comment      = TradeComment;
   req.deviation    = MaxSlippagePoints;
   req.type         = (sig=="BUY") ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   req.price        = price;
   req.sl           = sl;
   req.tp           = tp;
   req.type_time    = ORDER_TIME_GTC;
   req.type_filling = fillType;

   int retries = ExecutionRetryCount;

   while(retries > 0)
   {
      ResetLastError();
      bool ok = OrderSend(req, res);

      if(ok && (res.retcode == TRADE_RETCODE_DONE || res.retcode == TRADE_RETCODE_PLACED))
      {
         Dbg(StringFormat("EXEC OK | ret=%d | deal=%I64u | order=%I64u", (int)res.retcode, res.deal, res.order));
         return true;
      }

      int err = GetLastError();
      Dbg(StringFormat("EXEC FAIL | ret=%d | err=%d | retry left=%d", (int)res.retcode, err, retries-1));

      // Blocca retry su errori fatali
      if(res.retcode == 10013 || res.retcode == 10018 || res.retcode == 10019 ||
         res.retcode == 10030 || res.retcode == 10033 || res.retcode == 10034 ||
         res.retcode == 10035 || res.retcode == 10039)
      {
         Dbg("EXEC FATAL RETCODE → stop retry: " + IntegerToString((int)res.retcode));
         return false;
      }

      retries--;
      Sleep(500);
   }

   Dbg("EXEC FAILED after all retries");
   return false;
}
void ExecuteSignalTrade(const string sig, const double atr)
{
   if(!EnableAutoTrading) { Dbg("EXEC BLOCK | AutoTrading OFF"); return; }
   if(!IsAutoTradingEnabled()) { Dbg("EXEC BLOCK | AutoTrading not allowed"); return; } // NEW
   if(EnableNewsFilter && IsNewsBlockedNow())
   {
      Dbg("EXEC BLOCK | NEWS FILTER | " + g_newsReason);
      return;
   }
   if(!IsTradingAllowedNow())
   {
      Dbg("EXEC BLOCK | schedule not allowed now");
      return;
   }
   if(!SpreadOK())
   {
      double sp=(SymbolInfoDouble(_Symbol,SYMBOL_ASK)-SymbolInfoDouble(_Symbol,SYMBOL_BID))/_Point;
      Dbg(StringFormat("EXEC BLOCK | spread %.1f > max %.1f", sp, MaxSpreadPoints));
      return;
   }
   if(TradeOnlyNewBar && !IsNewBarForSignal())
   {
      Dbg("EXEC BLOCK | TradeOnlyNewBar ON (not new bar)");
      return;
   }
   if(sig!="BUY" && sig!="SELL") { Dbg("EXEC BLOCK | sig invalid"); return; }
   if(atr<=0) { Dbg("EXEC BLOCK | ATR invalid"); return; }
   if(CountOpenPositionsFiltered() >= MaxOpenPositions)
   {
      Dbg(StringFormat("EXEC BLOCK | MaxOpenPositions reached (%d)", MaxOpenPositions));
      return;
   }
   double sl_points = (atr * ATR_SL_Multiplier) / _Point;
   if(sl_points<=0) { Dbg("EXEC BLOCK | sl_points invalid"); return; }

   double ask=SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid=SymbolInfoDouble(_Symbol,SYMBOL_BID);
   double price=(sig=="BUY") ? ask : bid;

   double sl = (sig=="BUY") ? price - sl_points*_Point
                              : price + sl_points*_Point;
   double tp = (sig=="BUY") ? price + sl_points*_Point*RR_Ratio
                              : price - sl_points*_Point*RR_Ratio;

   double lot = CalculateTradeLot(sig, price, sl);
   if(lot<=0 || !IsVolumeValid(lot))
   {
      Dbg("EXEC BLOCK | lot invalid");
      return;
   }
   int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   int freezeLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   int minDist = MathMax(stopsLevel, freezeLevel);
   if(minDist<0) minDist=0;
   if(minDist>0)
   {
      double slDist=MathAbs(price-sl)/_Point;
      double tpDist=MathAbs(tp-price)/_Point;
      if(slDist<minDist) sl = (sig=="BUY") ? price - minDist*_Point : price + minDist*_Point;
      if(tpDist<minDist) tp = (sig=="BUY") ? price + minDist*_Point : price - minDist*_Point;
   }
   price=NormalizeDouble(price,_Digits);
   sl =NormalizeDouble(sl,_Digits);
   tp =NormalizeDouble(tp,_Digits);
   int toOpen=MathMax(1,NumberOfTradesPerSignal);
   ENUM_ORDER_TYPE_FILLING fills[3]={ORDER_FILLING_IOC, ORDER_FILLING_FOK, ORDER_FILLING_RETURN};
   int opened=0;
   for(int n=0;n<toOpen;n++)
   {
      if(CountOpenPositionsFiltered() >= MaxOpenPositions) break;
      bool ok=false;
      for(int f=0; f<3; f++)
      {
         ok = SendOneMarketOrderWithRetry(sig, lot, price, sl, tp, fills[f]);
         if(ok) break;
      }
      if(ok) opened++;
      else break;
   }
   Dbg(StringFormat("EXEC SUMMARY | requested=%d | opened=%d", toOpen, opened));
}
//======================== SIGNAL PIPELINE =========================
void ProcessSignalAndTrade()
{
   if(!UseSignalEngine) return;
   int bull,bear;
   double rsi,rsima,macdMain,macdSig,kk,dd,e1,e2,e3,e4,e5,adx,pdi,mdi,sar,atr1,atr2;
   CalcSignalPro(bull,bear,
                 rsi,rsima,
                 macdMain,macdSig,
                 kk,dd,
                 e1,e2,e3,e4,e5,
                 adx,pdi,mdi,
                 sar,atr1,atr2);
   string baseSig = GetSignalPro(bull,bear,atr1);
   int extraScore=0, htfScore=0;
   bool volOk=true, stableOk=true;
   string filtSig = FinalSignalFilter(baseSig,bull,bear,atr1,sar,extraScore,htfScore,volOk,stableOk);
   if(filtSig!="BUY" && filtSig!="SELL") return;
   int barIndex = Bars(_Symbol,_Period);
   if(UseOneSignalPerBar && barIndex==g_lastSignalBar) return;
   if(UseSignalCooldown && (barIndex - g_lastSignalBarIndex) < CooldownBars) return;
   if(UseAntiFlipFilter &&
      g_lastSignalDirection!="" &&
      filtSig != g_lastSignalDirection &&
      (barIndex - g_lastSignalBar) < AntiFlipBars)
   {
      return;
   }
   ExecuteSignalTrade(filtSig, atr1);
   g_lastSignalBarIndex = barIndex;
   g_lastSignalBar = barIndex;
   g_lastSignalDirection = filtSig;
}
//======================== TRADE MANAGER (BE / TRAIL / PARTIAL) =========================
bool ModifyPositionSLTPWithCheck(const ulong ticket, const double sl, const double tp)
{
   if(!PositionSelectByTicket(ticket)) return false;
   MqlTradeRequest req;
   MqlTradeResult res;
   ZeroMemory(req);
   ZeroMemory(res);
   req.action = TRADE_ACTION_SLTP;
   req.position = ticket;
   req.symbol = PositionGetString(POSITION_SYMBOL);
   req.sl = sl;
   req.tp = tp;
   ResetLastError();
   bool ok=OrderSend(req,res);
   if(!ok){
      Dbg("Modify SLTP fail: " + IntegerToString(GetLastError()));
      return false;
   }
   if(res.retcode != TRADE_RETCODE_DONE && res.retcode != TRADE_RETCODE_PLACED){
      Dbg("Modify SLTP reject: ret=" + IntegerToString((int)res.retcode));
      return false;
   }
   return true;
}
bool ClosePartialPositionWithCheck(const ulong ticket, const double volume, const long posType)
{
   if(!PositionSelectByTicket(ticket)) return false;

   string sym = PositionGetString(POSITION_SYMBOL);
   double bid = SymbolInfoDouble(sym, SYMBOL_BID);
   double ask = SymbolInfoDouble(sym, SYMBOL_ASK);
   double price = (posType == POSITION_TYPE_BUY) ? bid : ask;

   ENUM_ORDER_TYPE_FILLING fills[3] = {ORDER_FILLING_IOC, ORDER_FILLING_FOK, ORDER_FILLING_RETURN};

   for(int i=0; i<3; i++)
   {
      MqlTradeRequest req;
      MqlTradeResult  res;
      ZeroMemory(req);
      ZeroMemory(res);

      req.action       = TRADE_ACTION_DEAL;
      req.position     = ticket;
      req.symbol       = sym;
      req.volume       = volume;
      req.magic        = MagicNumber;
      req.type         = (posType == POSITION_TYPE_BUY) ? ORDER_TYPE_SELL : ORDER_TYPE_BUY;
      req.price        = NormalizeDouble(price, _Digits);
      req.type_filling = fills[i];
      req.type_time    = ORDER_TIME_GTC;
      req.deviation    = MaxSlippagePoints;

      ResetLastError();
      bool ok = OrderSend(req, res);

      if(ok && (res.retcode == TRADE_RETCODE_DONE || res.retcode == TRADE_RETCODE_PLACED))
      {
         Dbg(StringFormat("Close partial OK | ticket=%I64u | fill=%d | vol=%.4f",
                          ticket, (int)fills[i], volume));
         return true;
      }

      Dbg(StringFormat("Close partial fail | ticket=%I64u | fill=%d | ret=%d | err=%d",
                       ticket, (int)fills[i], (int)res.retcode, GetLastError()));
   }

   return false;
}
//===================== TELEGRAM CORE (MT5 with retry) =====================
string UrlEncode(const string s)
{
   string r = s;
   StringReplace(r, "%", "%25");
   StringReplace(r, " ", "%20");
   StringReplace(r, "\n", "%0A");
   StringReplace(r, "\r", "%0D");
   StringReplace(r, "&", "%26");
   StringReplace(r, "?", "%3F");
   StringReplace(r, "=", "%3D");
   StringReplace(r, "#", "%23");
   StringReplace(r, "+", "%2B");
   StringReplace(r, "/", "%2F");
   StringReplace(r, ":", "%3A");
   return r;
}
bool StringToUtf8Bytes(const string text, uchar &out[])
{
   ArrayResize(out, 0);
   int len = StringToCharArray(text, out, 0, WHOLE_ARRAY, CP_UTF8);
   if(len <= 0) return false;
   if(out[len-1] == 0)
      ArrayResize(out, len-1);
   return true;
}
string ErrorDescriptionTelegram(const int error_code)
{
   switch(error_code)
   {
      case 0: return "Nessun errore";
      case 4014: return "URL non autorizzato (aggiungi https://api.telegram.org in WebRequest)";
      case 4060: return "Nessuna connessione al server";
      case 4106: return "Memoria insufficiente";
      case 5200: return "Timeout di connessione";
      default: return "Errore sconosciuto (" + IntegerToString(error_code) + ")";
   }
}
bool SendTelegramMessageWithRetry(const string message)
{
   if(!EnableTelegramNotifications) return false;
   if(StringLen(TelegramBotToken) < 10) return false;
   if(StringLen(message) <= 0) return false;
   string chat_ids[];
   ArrayResize(chat_ids, 1);
   chat_ids[0] = TelegramChatID;
   if(TelegramUseSecondChat && StringLen(TelegramChatID_2) > 0)
   {
      int n = ArraySize(chat_ids);
      ArrayResize(chat_ids, n+1);
      chat_ids[n] = TelegramChatID_2;
   }
   string url = "https://api.telegram.org/bot" + TelegramBotToken + "/sendMessage";
   bool success = false;
   for(int i=0; i<ArraySize(chat_ids); i++)
   {
      string payload = "chat_id=" + chat_ids[i] + "&text=" + UrlEncode(message);
      uchar post[];
      if(!StringToUtf8Bytes(payload, post)) continue;
      uchar result[];
      string headers = "Content-Type: application/x-www-form-urlencoded\r\n";
      int timeout = 7000;
      int retries = TelegramRetryCount;
      while(retries > 0)
      {
         ResetLastError();
         string resp_headers;
         int code = WebRequest("POST", url, headers, timeout, post, result, resp_headers);
         if(code == 200)
         {
            success = true;
            break;
         }
         else if(code == -1)
         {
            int err = GetLastError();
            Print("Telegram ERROR: ", err, " - ", ErrorDescriptionTelegram(err));
         }
         else
         {
            Print("Telegram HTTP ERROR: ", code, " | body: ", CharArrayToString(result));
         }
         retries--;
         Sleep(1000); // Pausa tra retry
      }
   }
   return success;
}
//===================== TELEGRAM — HELPERS (DETAILED EVENTS) =====================

// Converte il tipo di ordine/posizione in stringa leggibile
string SideToStr(const long t)
{
   if(t == ORDER_TYPE_BUY          || t == POSITION_TYPE_BUY)          return "BUY";
   if(t == ORDER_TYPE_SELL         || t == POSITION_TYPE_SELL)         return "SELL";
   if(t == ORDER_TYPE_BUY_LIMIT)                                       return "BUY_LIMIT";
   if(t == ORDER_TYPE_SELL_LIMIT)                                      return "SELL_LIMIT";
   if(t == ORDER_TYPE_BUY_STOP)                                        return "BUY_STOP";
   if(t == ORDER_TYPE_SELL_STOP)                                       return "SELL_STOP";
   if(t == ORDER_TYPE_BUY_STOP_LIMIT)                                  return "BUY_STOP_LIMIT";
   if(t == ORDER_TYPE_SELL_STOP_LIMIT)                                 return "SELL_STOP_LIMIT";
   return IntegerToString((int)t);  // fallback per tipi sconosciuti
}

// Verifica se l'evento Telegram deve essere inviato (filtri simbolo/magic)
bool PassTelegramFilters(const string sym, const long magic)
{
   if(!TelegramDetailedEvents) return false;
   if(TelegramOnlyThisSymbol && sym != _Symbol) return false;
   if(TelegramOnlyThisMagic && magic != (long)MagicNumber) return false;
   return true;
}

// Restituisce snapshot conto se abilitato (da aggiungere in fondo ai messaggi)
string AccountSnapIfEnabled()
{
   if(!TelegramIncludeAccountSnap) return "";
   
   string curr = AccountInfoString(ACCOUNT_CURRENCY);
   double bal = AccountInfoDouble(ACCOUNT_BALANCE);
   double eq  = AccountInfoDouble(ACCOUNT_EQUITY);
   double flt = eq - bal;
   
   return StringFormat("\n---\nBAL: %.2f %s | EQ: %.2f %s | FLT: %.2f %s",
                       bal, curr, eq, curr, flt, curr);
}

// Formatta un prezzo con il numero corretto di cifre decimali
string FormatPrice(const double p)
{
   if(p == 0.0) return "—";
   return DoubleToString(NormalizeDouble(p, _Digits), _Digits);
}

// ======================== DEDUPE ANTI-DOPPI (Sistema esistente) ========================

struct TgDedup
{
   long  key;     // hash della signature
   ulong micro;   // timestamp microsecondi
};

TgDedup g_tgDedup[];
int     g_tgDedupN = 0;

// Calcola hash semplice della stringa (per deduplicazione)
long HashEventKey(const string s)
{
   long h = 0;
   for(int i = 0; i < (int)StringLen(s); i++)
      h = (h * 31) + (uchar)StringGetCharacter(s, i);
   return h;
}

// Controlla se un evento è già stato inviato di recente
bool TgDedupeHit(const string signature)
{
   int window_ms = TelegramEventDedupeMs;
   if(window_ms <= 0) return false;
   
   long k = HashEventKey(signature);
   ulong now_us = GetMicrosecondCount();
   ulong window_us = (ulong)window_ms * 1000ULL;
   
   // Pulizia vecchie entry (più vecchie di 2 secondi)
   for(int i = g_tgDedupN - 1; i >= 0; i--)
   {
      if((now_us - g_tgDedup[i].micro) > 2000000ULL)
      {
         g_tgDedup[i] = g_tgDedup[g_tgDedupN - 1];
         g_tgDedupN--;
         ArrayResize(g_tgDedup, g_tgDedupN);
      }
   }
   
   // Cerca duplicato
   for(int i = 0; i < g_tgDedupN; i++)
   {
      if(g_tgDedup[i].key == k && (now_us - g_tgDedup[i].micro) <= window_us)
         return true;  // duplicato → non inviare
   }
   
   // Aggiungi nuovo
   int n = g_tgDedupN;
   g_tgDedupN++;
   ArrayResize(g_tgDedup, g_tgDedupN);
   g_tgDedup[n].key   = k;
   g_tgDedup[n].micro = now_us;
   
   return false;  // nuovo evento → ok inviare
}

//===================== ACCOUNT SUMMARY (ANTI-SPAM) =====================
// Stato precedente (anti-spam)
int prev_open_positions = 0;
int prev_pending_orders = 0;
int prev_total_orders = 0;
// memorizza SL/TP per ticket (posizioni + pendenti)
struct LastSLTP
{
   ulong ticket;
   double sl;
   double tp;
};
LastSLTP last_items[];
int last_items_count = 0;
datetime g_lastSummarySent = 0;
int FindLastItemIndex(const ulong ticket)
{
   for(int i=0; i<last_items_count; i++)
      if(last_items[i].ticket == ticket) return i;
   return -1;
}
double NormPrice(const double v)
{
   if(v == 0.0) return 0.0;
   return NormalizeDouble(v, _Digits);
}
bool DifferentPrice(const double a, const double b)
{
   double eps = _Point * 0.5;
   return (MathAbs(a - b) > eps);
}
bool GetLastSLTP(const ulong ticket, double &sl, double &tp)
{
   int idx = FindLastItemIndex(ticket);
   if(idx < 0) return false;
   sl = last_items[idx].sl;
   tp = last_items[idx].tp;
   return true;
}
bool DifferentSLTP(const double oldSL, const double oldTP, const double newSL, const double newTP)
{
   double nSL = NormPrice(newSL);
   double nTP = NormPrice(newTP);
   return (DifferentPrice(oldSL, nSL) || DifferentPrice(oldTP, nTP));
}
void UpsertLastItem(const ulong ticket, const double sl_in, const double tp_in, bool &changed)
{
   double sl = NormPrice(sl_in);
   double tp = NormPrice(tp_in);
   int idx = FindLastItemIndex(ticket);
   if(idx < 0)
   {
      int n = last_items_count;
      ArrayResize(last_items, n+1);
      last_items[n].ticket = ticket;
      last_items[n].sl = sl;
      last_items[n].tp = tp;
      last_items_count++;
      changed = true;
      return;
   }
   if(DifferentPrice(last_items[idx].sl, sl) || DifferentPrice(last_items[idx].tp, tp))
   {
      last_items[idx].sl = sl;
      last_items[idx].tp = tp;
      changed = true;
   }
}
bool SummaryCooldownOK()
{
   if(!TelegramSendAccountSummary) return false;
   if(TelegramSummaryCooldownSec<=0) return true;
   datetime now=TimeCurrent();
   return ((now - g_lastSummarySent) >= TelegramSummaryCooldownSec);
}
//===================== SL/TP EVENT NOTIFY (DETAILED) =====================
void TelegramNotifySLTPChange(const string kind, const ulong ticket,
                              const string sym, const long magic,
                              const double oldSL, const double oldTP,
                              const double newSL, const double newTP)
{
   if(!TelegramDetailedEvents) return;
   if(!EnableTelegramNotifications) return;
   string sig = StringFormat("SLTP|%s|%I64u|%s|%d|%.*f|%.*f|%.*f|%.*f",
                             kind, ticket, sym, (int)magic,
                             _Digits,oldSL, _Digits,oldTP, _Digits,newSL, _Digits,newTP);
   if(TgDedupeHit(sig)) return;
   string msg = StringFormat(
      "🛠 SL/TP CHANGED (%s)\nTime: %s\nSymbol: %s\nMagic: %d\nTicket: %I64u\nSL: %s → %s\nTP: %s → %s",
      kind,
      TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
      sym, (int)magic, ticket,
      FormatPrice(oldSL), FormatPrice(newSL),
      FormatPrice(oldTP), FormatPrice(newTP)
   );
   SendTelegramMessageWithRetry(msg + AccountSnapIfEnabled());
}
void SendOrderUpdateNotification_MT5()
{
   if(!EnableTelegramNotifications) return;
   if(!TelegramSendAccountSummary) return;
   if(!SummaryCooldownOK()) return;
   datetime now = TimeCurrent();
   if(g_lastSummaryTick == now) return;
   int open_positions = PositionsTotal();
   int pending_orders = OrdersTotal();
   int total_orders = open_positions + pending_orders;
   double account_balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double account_equity = AccountInfoDouble(ACCOUNT_EQUITY);
   double floating = account_equity - account_balance;
   bool has_changes = false;
   if(TelegramSummaryOnCountChange)
   {
      if(total_orders != prev_total_orders ||
         open_positions != prev_open_positions ||
         pending_orders != prev_pending_orders)
      {
         prev_total_orders = total_orders;
         prev_open_positions = open_positions;
         prev_pending_orders = pending_orders;
         has_changes = true;
      }
   }
   if(TelegramSummaryOnSLTPChange)
   {
      // POSIZIONI
      for(int i=0; i<PositionsTotal(); i++)
      {
         ulong tk = PositionGetTicket(i);
         if(tk==0) continue;
         if(!PositionSelectByTicket(tk)) continue;
         string sym = PositionGetString(POSITION_SYMBOL);
         long mg = (long)PositionGetInteger(POSITION_MAGIC);
         double sl = PositionGetDouble(POSITION_SL);
         double tp = PositionGetDouble(POSITION_TP);
         double oldSL=0, oldTP=0;
         bool had = GetLastSLTP(tk, oldSL, oldTP);
         if(had && DifferentSLTP(oldSL, oldTP, sl, tp))
            TelegramNotifySLTPChange("POSITION", tk, sym, mg, oldSL, oldTP, NormPrice(sl), NormPrice(tp));
         UpsertLastItem(tk, sl, tp, has_changes);
      }
      // ORDINI PENDENTI
      for(int i=0; i<OrdersTotal(); i++)
      {
         ulong tk = OrderGetTicket(i);
         if(tk==0) continue;
         if(!OrderSelect(tk)) continue;
         string sym = OrderGetString(ORDER_SYMBOL);
         long mg = (long)OrderGetInteger(ORDER_MAGIC);
         double sl = OrderGetDouble(ORDER_SL);
         double tp = OrderGetDouble(ORDER_TP);
         double oldSL=0, oldTP=0;
         bool had = GetLastSLTP(tk, oldSL, oldTP);
         if(had && DifferentSLTP(oldSL, oldTP, sl, tp))
            TelegramNotifySLTPChange("ORDER", tk, sym, mg, oldSL, oldTP, NormPrice(sl), NormPrice(tp));
         UpsertLastItem(tk, sl, tp, has_changes);
      }
   }
   if(!has_changes) return;
   string curr = AccountInfoString(ACCOUNT_CURRENCY);
   string message = "📊 *Riepilogo Conto*\n";
   message += "🧾 Ordini totali: " + IntegerToString(total_orders) + "\n";
   message += "📌 Posizioni aperte: " + IntegerToString(open_positions) + "\n";
   message += "⏳ Ordini pendenti: " + IntegerToString(pending_orders) + "\n";
   message += "💰 Saldo: " + DoubleToString(account_balance, 2) + " " + curr + "\n";
   message += "🏦 Equity: " + DoubleToString(account_equity, 2) + " " + curr + "\n";
   message += "📈 Floating: " + DoubleToString(floating, 2) + " " + curr + "\n";
   message += "🛰 Broker: " + AccountInfoString(ACCOUNT_SERVER);
   SendTelegramMessageWithRetry(message);
   g_lastSummarySent = now;
   g_lastSummaryTick = now;
}
double ApplyMinStopDistance(const string sym, const long posType, const double currentPrice, const double desiredSL)
{
   int stopsLevel = (int)SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL);
   int freezeLevel = (int)SymbolInfoInteger(sym, SYMBOL_TRADE_FREEZE_LEVEL);
   int minDist = MathMax(stopsLevel, freezeLevel);
   if(minDist < 0) minDist = 0;
   if(minDist == 0) return desiredSL;
   double point = SymbolInfoDouble(sym,SYMBOL_POINT);
   if(point<=0.0) point=_Point;
   double sl = desiredSL;
   if(posType == POSITION_TYPE_BUY)
   {
      double maxSL = currentPrice - minDist * point;
      if(sl > maxSL) sl = maxSL;
   }
   else // SELL
   {
      double minSL = currentPrice + minDist * point;
      if(sl < minSL) sl = minSL;
   }
   return sl;
}
//======================== TRADE MANAGER ACTIONS + TELEGRAM =========================
double GetInitialRiskDistanceR(const ulong ticket)
{
   if(!PositionSelectByTicket(ticket)) return 0.0;
   double open = PositionGetDouble(POSITION_PRICE_OPEN);
   double tp   = PositionGetDouble(POSITION_TP);

   // In Phase 2 il TP viene creato come distanza SL iniziale x RR_Ratio.
   // Usare il TP permette di conservare 1R anche dopo modifiche dello SL.
   string sym = PositionGetString(POSITION_SYMBOL);
   double point = SymbolInfoDouble(sym,SYMBOL_POINT);
   if(point<=0.0) point=_Point;
   if(open > 0.0 && tp > 0.0 && RR_Ratio > 0.0)
   {
      double r = MathAbs(tp - open) / RR_Ratio;
      if(r > point) return r;
   }

   // Fallback utile per posizioni prive di TP, finché lo SL è ancora quello iniziale.
   double sl = PositionGetDouble(POSITION_SL);
   if(open > 0.0 && sl > 0.0)
   {
      long type = (long)PositionGetInteger(POSITION_TYPE);
      if((type==POSITION_TYPE_BUY  && sl < open) ||
         (type==POSITION_TYPE_SELL && sl > open))
      {
         double r = MathAbs(open - sl);
         if(r > point) return r;
      }
   }
   return 0.0;
}

double GetPositionProfitR(const ulong ticket, const double riskDist)
{
   if(riskDist <= 0.0 || !PositionSelectByTicket(ticket)) return 0.0;
   double open = PositionGetDouble(POSITION_PRICE_OPEN);
   long type = (long)PositionGetInteger(POSITION_TYPE);
   string sym = PositionGetString(POSITION_SYMBOL);
   double price = (type==POSITION_TYPE_BUY) ? SymbolInfoDouble(sym,SYMBOL_BID)
                                             : SymbolInfoDouble(sym,SYMBOL_ASK);
   if(type==POSITION_TYPE_BUY) return (price-open)/riskDist;
   return (open-price)/riskDist;
}

string PartialDoneKey(const ulong ticket)
{
   if(!PositionSelectByTicket(ticket)) return "";
   ulong identifier = (ulong)PositionGetInteger(POSITION_IDENTIFIER);
   long login = AccountInfoInteger(ACCOUNT_LOGIN);
   return StringFormat("PPRO_P3_PARTIAL_%I64d_%I64u",login,identifier);
}

bool IsPartialDone(const ulong ticket)
{
   string key=PartialDoneKey(ticket);
   if(key=="") return false;
   return GlobalVariableCheck(key) && GlobalVariableGet(key)>0.5;
}

void MarkPartialDone(const ulong ticket)
{
   string key=PartialDoneKey(ticket);
   if(key!="") GlobalVariableSet(key,1.0);
}

void ManageBreakEven(const ulong ticket)
{
   if(!UseBreakEven || BreakEvenTriggerR<=0.0) return;
   if(!PositionSelectByTicket(ticket)) return;
   if(!PositionPassFilters()) return;

   double riskDist=GetInitialRiskDistanceR(ticket);
   if(riskDist<=0.0) return;
   double profitR=GetPositionProfitR(ticket,riskDist);
   if(profitR < BreakEvenTriggerR) return;

   double open=PositionGetDouble(POSITION_PRICE_OPEN);
   double sl=PositionGetDouble(POSITION_SL);
   double tp=PositionGetDouble(POSITION_TP);
   long type=(long)PositionGetInteger(POSITION_TYPE);
   string sym=PositionGetString(POSITION_SYMBOL);
   double price=(type==POSITION_TYPE_BUY) ? SymbolInfoDouble(sym,SYMBOL_BID)
                                          : SymbolInfoDouble(sym,SYMBOL_ASK);
   double plus=MathMax(0.0,BreakEvenPlusR)*riskDist;
   double targetSL=(type==POSITION_TYPE_BUY) ? open+plus : open-plus;
   bool improve=(type==POSITION_TYPE_BUY && (sl==0.0 || targetSL>sl)) ||
                (type==POSITION_TYPE_SELL && (sl==0.0 || targetSL<sl));
   if(!improve) return;

   targetSL=ApplyMinStopDistance(sym,type,price,targetSL);
   targetSL=NormalizeDouble(targetSL,(int)SymbolInfoInteger(sym,SYMBOL_DIGITS));
   if(type==POSITION_TYPE_BUY && targetSL>=price) return;
   if(type==POSITION_TYPE_SELL && targetSL<=price) return;
   double point=SymbolInfoDouble(sym,SYMBOL_POINT);
   if(point<=0.0) point=_Point;
   if(sl!=0.0 && MathAbs(targetSL-sl)<2*point) return;

   double oldSL=sl;
   if(ModifyPositionSLTPWithCheck(ticket,targetSL,tp))
   {
      Dbg(StringFormat("BE R OK | ticket=%I64u | profitR=%.2f | SL=%.*f",ticket,profitR,_Digits,targetSL));
      long mg=(long)PositionGetInteger(POSITION_MAGIC);
      if(EnableTelegramNotifications && TelegramDetailedEvents && PassTelegramFilters(sym,mg))
      {
         string m=StringFormat("🎯 BREAK EVEN R SET\nTime: %s\nSymbol: %s\nMagic: %d\nTicket: %I64u\nProfit: %.2fR\nSL: %s → %s\nLock: +%.2fR",
                               TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),sym,(int)mg,ticket,
                               profitR,FormatPrice(oldSL),FormatPrice(targetSL),MathMax(0.0,BreakEvenPlusR));
         SendTelegramMessageWithRetry(m+AccountSnapIfEnabled());
      }
   }
}

void ManageRTrailing(const ulong ticket)
{
   if(!UseRTrailing || TrailStartR<=0.0 || TrailStepR<=0.0) return;
   if(!PositionSelectByTicket(ticket)) return;
   if(!PositionPassFilters()) return;

   double riskDist=GetInitialRiskDistanceR(ticket);
   if(riskDist<=0.0) return;
   double profitR=GetPositionProfitR(ticket,riskDist);
   if(profitR < TrailStartR) return;

   double steps=MathFloor((profitR-TrailStartR)/TrailStepR + 1e-9);
   double lockR=MathMax(0.0,TrailFirstLockR) + steps*TrailStepR;
   double open=PositionGetDouble(POSITION_PRICE_OPEN);
   double sl=PositionGetDouble(POSITION_SL);
   double tp=PositionGetDouble(POSITION_TP);
   long type=(long)PositionGetInteger(POSITION_TYPE);
   string sym=PositionGetString(POSITION_SYMBOL);
   double price=(type==POSITION_TYPE_BUY) ? SymbolInfoDouble(sym,SYMBOL_BID)
                                          : SymbolInfoDouble(sym,SYMBOL_ASK);
   double newSL=(type==POSITION_TYPE_BUY) ? open+lockR*riskDist : open-lockR*riskDist;
   newSL=ApplyMinStopDistance(sym,type,price,newSL);
   newSL=NormalizeDouble(newSL,(int)SymbolInfoInteger(sym,SYMBOL_DIGITS));

   bool improve=(type==POSITION_TYPE_BUY && (sl==0.0 || newSL>sl)) ||
                (type==POSITION_TYPE_SELL && (sl==0.0 || newSL<sl));
   if(!improve) return;
   if(type==POSITION_TYPE_BUY && newSL>=price) return;
   if(type==POSITION_TYPE_SELL && newSL<=price) return;
   double point=SymbolInfoDouble(sym,SYMBOL_POINT);
   if(point<=0.0) point=_Point;
   if(sl!=0.0 && MathAbs(newSL-sl)<2*point) return;

   double oldSL=sl;
   if(ModifyPositionSLTPWithCheck(ticket,newSL,tp))
   {
      Dbg(StringFormat("R TRAIL OK | ticket=%I64u | profitR=%.2f | lockR=%.2f",ticket,profitR,lockR));
      long mg=(long)PositionGetInteger(POSITION_MAGIC);
      if(EnableTelegramNotifications && TelegramDetailedEvents && PassTelegramFilters(sym,mg))
      {
         string m=StringFormat("🧭 R TRAILING MOVE\nTime: %s\nSymbol: %s\nMagic: %d\nTicket: %I64u\nProfit: %.2fR\nLocked: %.2fR\nSL: %s → %s",
                               TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),sym,(int)mg,ticket,
                               profitR,lockR,FormatPrice(oldSL),FormatPrice(newSL));
         SendTelegramMessageWithRetry(m+AccountSnapIfEnabled());
      }
   }
}

void ManagePartialClose(const ulong ticket)
{
   if(!UsePartialClose || PartialTriggerR<=0.0 || PartialClosePercent<=0.0) return;
   if(!PositionSelectByTicket(ticket)) return;
   if(!PositionPassFilters()) return;
   if(IsPartialDone(ticket)) return;

   double riskDist=GetInitialRiskDistanceR(ticket);
   if(riskDist<=0.0) return;
   double profitR=GetPositionProfitR(ticket,riskDist);
   if(profitR < PartialTriggerR) return;

   double vol=PositionGetDouble(POSITION_VOLUME);
   long type=(long)PositionGetInteger(POSITION_TYPE);
   string sym=PositionGetString(POSITION_SYMBOL);
   double closeVol=NormalizeVolume(vol*(MathMin(100.0,PartialClosePercent)/100.0));
   if(closeVol<=0.0 || closeVol>=vol) return;

   if(ClosePartialPositionWithCheck(ticket,closeVol,type))
   {
      MarkPartialDone(ticket);
      Dbg(StringFormat("PARTIAL R OK | ticket=%I64u | profitR=%.2f | vol=%.4f",ticket,profitR,closeVol));
      long mg=(long)PositionGetInteger(POSITION_MAGIC);
      if(EnableTelegramNotifications && TelegramDetailedEvents && PassTelegramFilters(sym,mg))
      {
         string m=StringFormat("✂️ PARTIAL CLOSE R\nTime: %s\nSymbol: %s\nMagic: %d\nTicket: %I64u\nTrigger: %.2fR\nClosed Vol: %.4f",
                               TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),sym,(int)mg,ticket,
                               profitR,closeVol);
         SendTelegramMessageWithRetry(m+AccountSnapIfEnabled());
      }
   }
}
double EquityFloatingScoped()
{
   if(EquityLockCloseWholeAccount)
   {
      // floating totale account
      double bal = AccountInfoDouble(ACCOUNT_BALANCE);
      double eq = AccountInfoDouble(ACCOUNT_EQUITY);
      return (eq - bal);
   }
   // floating solo posizione filtrate (Magic/Symbol se hai filtri attivi)
   return ProfitFloating();
}
int CloseAllScopedPositions()
{
   int closed = 0;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      ulong tk = PositionGetTicket(i);
      if(tk==0) continue;
      if(!PositionSelectByTicket(tk)) continue;
      if(!EquityLockCloseWholeAccount)
      {
         // rispetta i filtri del tuo EA (TrackWholeAccount/OnlySymbol/OnlyMagic)
         if(!PositionPassFilters()) continue;
      }
      long type = (long)PositionGetInteger(POSITION_TYPE);
      double vol = PositionGetDouble(POSITION_VOLUME);
      if(vol<=0) continue;
      if(ClosePartialPositionWithCheck(tk, vol, type))
         closed++;
   }
   return closed;
}
int CloseWeekendEAPositions()
{
   int closed=0;
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong tk=PositionGetTicket(i);
      if(tk==0 || !PositionSelectByTicket(tk)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=_Symbol) continue;
      if((long)PositionGetInteger(POSITION_MAGIC)!=MagicNumber) continue;
      long type=(long)PositionGetInteger(POSITION_TYPE);
      double vol=PositionGetDouble(POSITION_VOLUME);
      if(vol<=0) continue;
      if(ClosePartialPositionWithCheck(tk,vol,type)) closed++;
   }
   return closed;
}

void ManageWeekendProtection()
{
   static int lastCloseDay=-1;
   datetime now=TimeCurrent();
   if(!IsWeekendCloseTime(now)) return;
   MqlDateTime x; TimeToStruct(now,x);
   int dayKey=x.year*1000+x.day_of_year;
   if(lastCloseDay==dayKey && CountOpenPositionsFiltered()==0) return;
   int closed=CloseWeekendEAPositions();
   if(closed>0)
      Dbg(StringFormat("WEEKEND PROTECTION | closed=%d | server=%s",closed,TimeToString(now,TIME_DATE|TIME_MINUTES)));
   lastCloseDay=dayKey;
}

void ManageEquityLock()
{
   if(!UseEquityLock) return;
   datetime now = TimeCurrent();
   if(g_eqLastClose != 0 && (now - g_eqLastClose) < EquityLockCooldownSec)
      return;
   // floating profit corrente
   double flt = EquityFloatingScoped();
   // soglie
   double start = 0.0;
   double trail = 0.0;
   if(EquityLockUsePercent)
   {
      double bal = AccountInfoDouble(ACCOUNT_BALANCE);
      start = bal * (EquityLockStartPercent/100.0);
      trail = bal * (EquityLockTrailDDPercent/100.0);
   }
   else
   {
      start = EquityLockStartMoney;
      trail = EquityLockTrailDDMoney;
   }
   if(start <= 0 || trail <= 0) return;
   // ARMA quando superi la soglia
   if(!g_eqArmed)
   {
      if(flt >= start)
      {
         g_eqArmed = true;
         g_eqPeak = flt;
         Dbg(StringFormat("EQ LOCK ARMED | floating=%.2f | start=%.2f", flt, start));
      }
      return;
   }
   // aggiorna picco
   if(flt > g_eqPeak) g_eqPeak = flt;
   // ritraccio dal picco
   double ddFromPeak = g_eqPeak - flt;
   if(ddFromPeak >= trail)
   {
      int closed = CloseAllScopedPositions();
      g_eqLastClose = now;
      Dbg(StringFormat("EQ LOCK TRIGGER | peak=%.2f | now=%.2f | dd=%.2f | trail=%.2f | closed=%d",
                       g_eqPeak, flt, ddFromPeak, trail, closed));
      if(EnableTelegramNotifications && TelegramDetailedEvents)
      {
         string msg = StringFormat("🔒 EQUITY LOCK TRIGGERED\nTime: %s\nPeakFloating: %.2f\nNowFloating: %.2f\nDrawdownFromPeak: %.2f\nTrail: %.2f\nClosedPos: %d\nScope: %s",
                                   TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
                                   g_eqPeak, flt, ddFromPeak, trail, closed,
                                   (EquityLockCloseWholeAccount ? "WHOLE_ACCOUNT" : "FILTERED"));
         SendTelegramMessageWithRetry(msg + AccountSnapIfEnabled());
      }
      // reset
      g_eqArmed = false;
      g_eqPeak = 0.0;
   }
}
void ManageOpenPositions()
{
   for(int i=PositionsTotal()-1;i>=0;i--)
   {
      ulong tk=PositionGetTicket(i);
      if(tk==0) continue;
      if(!PositionSelectByTicket(tk)) continue;
      if(!PositionPassFilters()) continue;
      ManageBreakEven(tk);
      ManagePartialClose(tk);
      ManageRTrailing(tk);
   }
}

void UpdatePanel_Live()
{
   string curr = AccountInfoString(ACCOUNT_CURRENCY);
   double bal  = AccountInfoDouble(ACCOUNT_BALANCE);
   double eq   = AccountInfoDouble(ACCOUNT_EQUITY);

   string modeTxt = TrackWholeAccount ? "MODE: WHOLE_ACCOUNT" : "MODE: FILTERED";

   SetRow("TITLE",        "PROFIT TARGET + SIGNAL ENGINE PRO — " + TimeToString(TimeCurrent(), TIME_DATE) + " | " + modeTxt, TitleColor);
   SetRow("CANDLE_TIMER", "Candle Close In : " + GetCandleTimeLeft(), StatusColor);
   SetRow("ACC_BAL",      "Account Balance : " + DoubleToString(bal,2) + " " + curr, TextColor);
   SetRow("ACC_EQU",      "Current Equity  : " + DoubleToString(eq,2)  + " " + curr, TextColor);

   // separatori (ok anche live)
   if(UseSeparators){
      SetRow("SEP1", SepStyleText, SepColor);
      SetRow("SEP2", SepStyleText, SepColor);
      SetRow("SEP3", SepStyleText, SepColor);
   } else {
      SetRow("SEP1"," ",TextColor);
      SetRow("SEP2"," ",TextColor);
      SetRow("SEP3"," ",TextColor);
   }
}

void UpdatePanel_DayWeekNews()
{
   string curr = AccountInfoString(ACCOUNT_CURRENCY);

   // DAY
   double dTotal    = ProfitTotalSince(g_dayStartTime, g_dayStartBalance);
   double dClosed   = ProfitClosedFromHistory(g_dayStartTime);
   double dFloating = ProfitFloatingAllScoped();

   double dTarget = g_dayStartBalance * DailyTargetPercent / 100.0;
   double dRemain = dTarget - dTotal;

   double dPerc = (g_dayStartBalance > 0) ? (dTotal / g_dayStartBalance * 100.0) : 0.0;
   color  dCol  = (dTotal >= 0) ? PositiveColor : NegativeColor;

   string dStatus = (dTotal >= dTarget ? "TARGET RAGGIUNTO" : "IN CORSO");

   string dRemainLabel;
   double dRemainAbs;
   color  dRemainCol;

   if(dRemain <= 0){
      dRemainLabel = "Day Over Target : ";
      dRemainAbs   = MathAbs(dRemain);
      dRemainCol   = PositiveColor;
   } else {
      dRemainLabel = "Day Remaining   : ";
      dRemainAbs   = dRemain;
      dRemainCol   = (dRemain < dTarget*0.3 ? clrYellow : NegativeColor);
   }

   SetRow("DAY_START",  "Day Start Base : " + DoubleToString(g_dayStartBalance,2) + " " + curr, TextColor);

   color dClosedCol = (dClosed   >= 0) ? PositiveColor : NegativeColor;
   color dFloatCol  = (dFloating >= 0) ? PositiveColor : NegativeColor;

   SetRow("DAY_PROFIT", "Day Net Result : " + DoubleToString(dTotal,2) + " " + curr +
                        " (" + DoubleToString(dPerc,2) + "%)", dCol);
   SetRow("DAY_CLOSED", "Day Closed P/L : " + DoubleToString(dClosed,2)   + " " + curr, dClosedCol);
   SetRow("DAY_FLOAT",  "Day Float  P/L : " + DoubleToString(dFloating,2) + " " + curr, dFloatCol);
   SetRow("DAY_TARGET", "Day Target     : " + DoubleToString(dTarget,2) + " " + curr, TextColor);
   SetRow("DAY_REMAIN", dRemainLabel + DoubleToString(dRemainAbs,2) + " " + curr, dRemainCol);
   SetRow("DAY_STATUS", "Day Status     : " + dStatus, (dStatus=="TARGET RAGGIUNTO" ? PositiveColor : StatusColor));

   // WEEK
   double wTotal  = ProfitTotalSince(g_weekStartTime, g_weekStartBalance);
   double wTarget = g_weekStartBalance * (MathPow(1.0 + DailyTargetPercent/100.0, 5) - 1.0);
   double wRemain = wTarget - wTotal;

   double wPerc = (g_weekStartBalance > 0) ? (wTotal / g_weekStartBalance * 100.0) : 0.0;
   color  wCol  = (wTotal >= 0) ? PositiveColor : NegativeColor;

   string wStatus = (wTotal >= wTarget ? "TARGET RAGGIUNTO" : "IN CORSO");

   string wRemainLabel;
   double wRemainAbs;
   color  wRemainCol;

   if(wRemain <= 0){
      wRemainLabel = "Week Over Target : ";
      wRemainAbs   = MathAbs(wRemain);
      wRemainCol   = PositiveColor;
   } else {
      wRemainLabel = "Week Remaining   : ";
      wRemainAbs   = wRemain;
      wRemainCol   = (wRemain < wTarget*0.3 ? clrYellow : NegativeColor);
   }

   SetRow("WEEK_START",  "Week Start Base : " + DoubleToString(g_weekStartBalance,2) + " " + curr, TextColor);
   SetRow("WEEK_PROFIT", "Week Profit     : " + DoubleToString(wTotal,2) + " " + curr +
                         " (" + DoubleToString(wPerc,2) + "%)", wCol);
   SetRow("WEEK_TARGET", "Week Target     : " + DoubleToString(wTarget,2) + " " + curr, TextColor);
   SetRow("WEEK_REMAIN", wRemainLabel + DoubleToString(wRemainAbs,2) + " " + curr, wRemainCol);
   SetRow("WEEK_STATUS", "Week Status     : " + wStatus, (wStatus=="TARGET RAGGIUNTO" ? PositiveColor : StatusColor));

   // NEWS (non farlo ogni secondo: pesante e “ballerino”)
   bool nb = (EnableNewsFilter && IsNewsBlockedNow());
   color ncol = nb ? NegativeColor : PositiveColor;

   SetRow("NEWS_STATUS", "NEWS Filter     : " + (EnableNewsFilter ? (nb ? "BLOCKED" : "OK") : "OFF"), ncol);
   if(ShowNearestNewsOnPanel && StringLen(g_newsReason)>0)
      SetRow("NEWS_NEXT", g_newsReason, (nb ? NegativeColor : TextColor));
   else
      SetRow("NEWS_NEXT", " ", TextColor);
}


//======================== UPDATE PANEL — SIGNAL ONLY =========================
void UpdatePanel_Signal()
{
   // Dashboard diagnostica: sola visualizzazione, nessuna modifica alla logica operativa.
   SetRow("SIG_SCORE",    "Punteggio: —", TextColor);
   SetRow("SIG_BASE",     "Segnale base: —", TextColor);
   SetRow("SIG_FILTERED", "Segnale filtrato: —", TextColor);
   SetRow("SIG_STATUS",   "STATO: —", StatusColor);
   SetRow("SIG_CHECKS",   "Controlli: —", TextColor);
   SetRow("SIG_RSI",      "RSI: —", TextColor);
   SetRow("SIG_RSI_MA",   "Media RSI: —", TextColor);
   SetRow("SIG_MACD",     "MACD: —", TextColor);
   SetRow("SIG_STOCH",    "Stocastico: —", TextColor);
   SetRow("SIG_EMA",      "Struttura EMA: —", TextColor);
   SetRow("EMA5",         "EMA 5: —", TextColor);
   SetRow("EMA10",        "EMA 10: —", TextColor);
   SetRow("EMA50",        "EMA 50: —", TextColor);
   SetRow("EMA100",       "EMA 100: —", TextColor);
   SetRow("EMA200",       "EMA 200: —", TextColor);
   SetRow("SIG_ADX",      "ADX: —", TextColor);
   SetRow("SIG_SAR",      "SAR: —", TextColor);
   SetRow("SIG_ATR",      "Volatilita ATR: —", TextColor);
   SetRow("FLAG_HTF",     "Trend superiore: —", TextColor);
   SetRow("FLAG_VOL",     "Filtro ATR minimo: —", TextColor);
   if(!UseSignalEngine)
   {
      SetRow("SIG_STATUS", "STATO: MOTORE SEGNALI DISATTIVATO", StatusColor);
      return;
   }

   int bull=0, bear=0;
   double rsi=0, rsima=0, macdMain=0, macdSig=0, kk=0, dd=0;
   double e1=0, e2=0, e3=0, e4=0, e5=0;
   double adx=0, pdi=0, mdi=0, sar=0, atr1=0, atr2=0;

   CalcSignalPro(bull,bear,
                 rsi,rsima,
                 macdMain,macdSig,
                 kk,dd,
                 e1,e2,e3,e4,e5,
                 adx,pdi,mdi,
                 sar,atr1,atr2);

   string baseSig = GetSignalPro(bull,bear,atr1);
   int extraScore=0, htfScore=0;
   bool volOk=true, stableOk=true;
   string filtSig = FinalSignalFilter(baseSig,bull,bear,atr1,sar,extraScore,htfScore,volOk,stableOk);

   // Punteggio: mostra chiaramente soglia e direzione prevalente.
   SetRow("SIG_SCORE", StringFormat("Punteggio: BUY %d | SELL %d | minimo %d", bull, bear, Confirmation_Count), TextColor);
   color baseCol = (baseSig=="BUY") ? PositiveColor : ((baseSig=="SELL") ? NegativeColor : TextColor);
   string baseTxt=baseSig;
   if(baseSig=="NO VOL") baseTxt="BLOCCATO - ATR INSUFFICIENTE";
   else if(baseSig=="NEUTRAL") baseTxt="NESSUN SEGNALE";
   SetRow("SIG_BASE", "Segnale base: " + baseTxt, baseCol);

   color fsCol = (filtSig=="BUY") ? PositiveColor : ((filtSig=="SELL") ? NegativeColor : TextColor);
   string filtTxt=filtSig;
   if(filtSig=="HTF_CONFLICT") filtTxt="BLOCCATO - TREND SUPERIORE CONTRARIO";
   else if(filtSig=="NEUTRAL") filtTxt="NESSUN SEGNALE";
   else if(filtSig=="NO VOL") filtTxt="BLOCCATO - ATR INSUFFICIENTE";
   SetRow("SIG_FILTERED", "Segnale filtrato: " + filtTxt, fsCol);

   // Diagnostica dei controlli operativi: legge le stesse condizioni usate dall'esecuzione.
   bool atrOk = (!UseATRVolatilityFilter || MinATR_Points<=0 || atr1 >= MinATR_Points*_Point);
   bool htfOk = (filtSig!="HTF_CONFLICT");
   bool newsOk = (!EnableNewsFilter || !g_newsBlockedNow);
   bool scheduleOk = IsTradingAllowedNow();
   bool spreadOk = SpreadOK();
   bool posOk = (CountOpenPositionsFiltered() < MaxOpenPositions);
   bool autoOk = (EnableAutoTrading && IsAutoTradingEnabled());
   int barIndex = Bars(_Symbol,_Period);
   bool oneBarOk = (!UseOneSignalPerBar || barIndex!=g_lastSignalBar);
   bool cooldownOk = (!UseSignalCooldown || (barIndex-g_lastSignalBarIndex)>=CooldownBars);
   bool antiFlipOk = true;
   if(UseAntiFlipFilter && g_lastSignalDirection!="" && (filtSig=="BUY" || filtSig=="SELL") &&
      filtSig!=g_lastSignalDirection && (barIndex-g_lastSignalBar)<AntiFlipBars) antiFlipOk=false;

   string checks = "ATR " + string(atrOk?"OK":"NO") +
                   " | HTF " + string(htfOk?"OK":"NO") +
                   " | NEWS " + string(newsOk?"OK":"NO") +
                   " | ORARIO " + string(scheduleOk?"OK":"NO") +
                   " | SPREAD " + string(spreadOk?"OK":"NO");
   SetRow("SIG_CHECKS", "Controlli: " + checks, TextColor);

   string status="ATTESA - PUNTEGGIO INSUFFICIENTE O CONTRASTANTE";
   color statusCol=StatusColor;
   if(baseSig=="NO VOL") status="BLOCCATO - VOLATILITA ATR INSUFFICIENTE";
   else if(filtSig=="HTF_CONFLICT") status="BLOCCATO - TREND SUPERIORE CONTRARIO";
   else if(filtSig=="BUY" || filtSig=="SELL")
   {
      if(!autoOk) status="BLOCCATO - AUTOTRADING DISATTIVATO";
      else if(!newsOk) status="BLOCCATO - NEWS";
      else if(!scheduleOk) status="BLOCCATO - FUORI ORARIO";
      else if(!spreadOk) status="BLOCCATO - SPREAD ELEVATO";
      else if(!oneBarOk) status="ATTESA - SEGNALE GIA GESTITO SU QUESTA CANDELA";
      else if(!cooldownOk) status="ATTESA - COOLDOWN ATTIVO";
      else if(!antiFlipOk) status="ATTESA - PROTEZIONE ANTI-INVERSIONE";
      else if(!posOk) status="BLOCCATO - LIMITE POSIZIONI RAGGIUNTO";
      else { status="INGRESSO " + filtSig + " AUTORIZZATO"; statusCol=(filtSig=="BUY"?PositiveColor:NegativeColor); }
   }
   SetRow("SIG_STATUS", "STATO: " + status, statusCol);

   // RSI / MACD / STOCASTICO con contributo al punteggio.
   string rsiDir="NEUTRO"; color rsiCol=TextColor;
   if(UseRSI_Filter && rsi>RSI_BuyLevel && rsi>rsima){ rsiDir="BUY +"+IntegerToString(Weight_RSI); rsiCol=PositiveColor; }
   else if(UseRSI_Filter && rsi<RSI_SellLevel && rsi<rsima){ rsiDir="SELL +"+IntegerToString(Weight_RSI); rsiCol=NegativeColor; }
   SetRow("SIG_RSI", "RSI: " + DoubleToString(rsi,1) + " | " + rsiDir, rsiCol);
   SetRow("SIG_RSI_MA", "Media RSI: " + DoubleToString(rsima,1), TextColor);

   string macdDir = macdMain>macdSig ? "BUY +"+IntegerToString(Weight_MACD) : "SELL +"+IntegerToString(Weight_MACD);
   SetRow("SIG_MACD", "MACD: " + DoubleToString(macdMain,5) + " | Signal: " + DoubleToString(macdSig,5) + " | " + macdDir,
          (macdMain>macdSig ? PositiveColor : NegativeColor));

   string stoDir = kk>dd ? "BUY +"+IntegerToString(Weight_STO) : "SELL +"+IntegerToString(Weight_STO);
   SetRow("SIG_STOCH", "Stocastico K: " + DoubleToString(kk,1) + " | D: " + DoubleToString(dd,1) + " | " + stoDir,
          (kk>dd ? PositiveColor : NegativeColor));

   bool emaBull=(e1>e2 && e2>e3 && e3>e4 && e4>e5);
   bool emaBear=(e1<e2 && e2<e3 && e3<e4 && e4<e5);
   color stackColor=emaBull?PositiveColor:(emaBear?NegativeColor:TextColor);
   string stackTxt=emaBull?("BUY +"+IntegerToString(Weight_EMA)):(emaBear?("SELL +"+IntegerToString(Weight_EMA)):"MISTA - 0");

   double e1_now=0,e2_now=0,e3_now=0,e4_now=0,e5_now=0;
   GetVal(hMA1,0,0,e1_now); GetVal(hMA2,0,0,e2_now); GetVal(hMA3,0,0,e3_now); GetVal(hMA4,0,0,e4_now); GetVal(hMA5,0,0,e5_now);
   SetRow("SIG_EMA", "Struttura EMA: " + stackTxt, stackColor);
   SetRow("EMA5",   StringFormat("EMA 5:   %s %s",DoubleToString(e1_now,_Digits),(e1_now>e1?"▲":"▼")),(e1_now>e1?PositiveColor:NegativeColor));
   SetRow("EMA10",  StringFormat("EMA 10:  %s %s",DoubleToString(e2_now,_Digits),(e2_now>e2?"▲":"▼")),(e2_now>e2?PositiveColor:NegativeColor));
   SetRow("EMA50",  StringFormat("EMA 50:  %s %s",DoubleToString(e3_now,_Digits),(e3_now>e3?"▲":"▼")),(e3_now>e3?PositiveColor:NegativeColor));
   SetRow("EMA100", StringFormat("EMA 100: %s %s",DoubleToString(e4_now,_Digits),(e4_now>e4?"▲":"▼")),(e4_now>e4?PositiveColor:NegativeColor));
   SetRow("EMA200", StringFormat("EMA 200: %s %s",DoubleToString(e5_now,_Digits),(e5_now>e5?"▲":"▼")),(e5_now>e5?PositiveColor:NegativeColor));

   string adxDir="NESSUN VOTO"; color adxCol=StatusColor;
   if(adx>=ADX_MinTrend){ if(pdi>mdi){adxDir="BUY +"+IntegerToString(Weight_ADX);adxCol=PositiveColor;} else {adxDir="SELL +"+IntegerToString(Weight_ADX);adxCol=NegativeColor;} }
   SetRow("SIG_ADX", "ADX: "+DoubleToString(adx,1)+" | +DI: "+DoubleToString(pdi,1)+" | -DI: "+DoubleToString(mdi,1)+" | "+adxDir, adxCol);

   double c1=iClose(_Symbol,_Period,1);
   string sarDir=c1>sar?("BUY +"+IntegerToString(Weight_SAR)):("SELL +"+IntegerToString(Weight_SAR));
   SetRow("SIG_SAR", "SAR: "+DoubleToString(sar,_Digits)+" | "+sarDir,(c1>sar?PositiveColor:NegativeColor));

   double atrPts=(atr1/_Point);
   SetRow("SIG_ATR", StringFormat("Volatilita ATR: %.1f punti | minimo %.1f | %s",atrPts,MinATR_Points,(atrOk?"OK":"BASSA")),
          (atrOk?PositiveColor:NegativeColor));

   string htfTxt="Trend superiore: N/D"; color htfCol=StatusColor;
   if(htfScore>0){htfTxt="Trend superiore: RIALZISTA";htfCol=PositiveColor;}
   else if(htfScore<0){htfTxt="Trend superiore: RIBASSISTA";htfCol=NegativeColor;}
   SetRow("FLAG_HTF",htfTxt,htfCol);
   SetRow("FLAG_VOL","Filtro ATR minimo: "+string(atrOk?"OK":"BLOCCATO"),(atrOk?PositiveColor:NegativeColor));
}

//======================== UPDATE PANEL =========================
//======================== UPDATE PANEL (SLOW wrapper: Day/Week/News ONLY) =========================
void UpdatePanel()
{
   UpdatePanel_DayWeekNews();
}


//======================== PIVOT MODULE (FULL) =========================
struct PivotLevels { double P, R1, R2, R3, R4, R5, S1, S2, S3, S4, S5; };
enum PivotTF { PIV_D=0, PIV_W=1, PIV_M=2 };
string PivotTFName(const PivotTF tf)
{
   if(tf==PIV_D) return "D1";
   if(tf==PIV_W) return "W1";
   return "MN1";
}
ENUM_TIMEFRAMES PivotTimeframe(const PivotTF tf)
{
   if(tf==PIV_D) return PERIOD_D1;
   if(tf==PIV_W) return PERIOD_W1;
   return PERIOD_MN1;
}
string ObjLineName(const PivotTF tf, const string lvl) { return PivotPrefix + PivotTFName(tf) + "_" + lvl + "_LINE"; }
string ObjTextName(const PivotTF tf, const string lvl) { return PivotPrefix + PivotTFName(tf) + "_" + lvl + "_TXT"; }
bool PivotLevelEnabled(const string lvl)
{
   if(lvl=="P") return PivotShowP;
   if(lvl=="R1") return PivotShowR1;
   if(lvl=="R2") return PivotShowR2;
   if(lvl=="R3") return PivotShowR3;
   if(lvl=="R4") return PivotShowR4;
   if(lvl=="R5") return PivotShowR5;
   if(lvl=="S1") return PivotShowS1;
   if(lvl=="S2") return PivotShowS2;
   if(lvl=="S3") return PivotShowS3;
   if(lvl=="S4") return PivotShowS4;
   if(lvl=="S5") return PivotShowS5;
   return true;
}
double PivotLevelPrice(const PivotLevels &p, const string lvl)
{
   if(lvl=="P") return p.P;
   if(lvl=="R1") return p.R1;
   if(lvl=="R2") return p.R2;
   if(lvl=="R3") return p.R3;
   if(lvl=="R4") return p.R4;
   if(lvl=="R5") return p.R5;
   if(lvl=="S1") return p.S1;
   if(lvl=="S2") return p.S2;
   if(lvl=="S3") return p.S3;
   if(lvl=="S4") return p.S4;
   if(lvl=="S5") return p.S5;
   return 0.0;
}
color PivotLevelColor(const string lvl, const color colP, const color colR, const color colS)
{
   if(lvl=="P") return colP;
   if(StringLen(lvl)>0 && StringGetCharacter(lvl,0)=='R') return colR;
   return colS;
}
string PivotMakeLabel(const string tf, const string lvl, const double price)
{
   if(PivotLabels == PIVOT_LABEL_OFF) return "";
   if(PivotLabels == PIVOT_LABEL_TAG_ONLY) return tf + " " + lvl;
   return tf + " " + lvl + " " + DoubleToString(price, _Digits);
}
//------------------ DRAW: line ------------------
void SetHLine(const string name, const double price, const color col, const ENUM_LINE_STYLE style, const int width)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}
//------------------ DRAW: label (pixel-based, regolabile) ------------------
bool PriceToY(const double price, int &y_out)
{
   int x=0, y=0;
   datetime t = iTime(_Symbol, _Period, 0);
   if(t<=0) t = TimeCurrent();
   if(!ChartTimePriceToXY(0, 0, t, price, x, y))
      return false;
   y_out = y;
   return true;
}
void SetLabelRightEdgeAtPrice(const string name, const string text, const double price, const color col)
{
   int y=0;
   if(!PriceToY(price, y))
      return;
   int w = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
   int x = w - PivotLabelXOffset;
   y += PivotLabelYOffset;
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, 0); // top-left
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, col);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, PivotLabelFontSize);
   ObjectSetString(0, name, OBJPROP_FONT, PivotLabelFont);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_RIGHT);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}
//------------------ CLEANUP ------------------
void DeletePivotObjectsByTF(const PivotTF tf)
{
   string lvls[]={"P","R1","R2","R3","R4","R5","S1","S2","S3","S4","S5"};
   for(int i=0;i<ArraySize(lvls);i++)
   {
      ObjectDelete(0, ObjLineName(tf, lvls[i]));
      ObjectDelete(0, ObjTextName(tf, lvls[i]));
   }
}
void DeleteAllPivots()
{
   DeletePivotObjectsByTF(PIV_D);
   DeletePivotObjectsByTF(PIV_W);
   DeletePivotObjectsByTF(PIV_M);
}
//------------------ DATA: prev period H/L/C ------------------
bool GetPrevPeriodHLC(const PivotTF tf, double &H, double &L, double &C)
{
   ENUM_TIMEFRAMES tfr = PivotTimeframe(tf);
   if(Bars(_Symbol, tfr) < 2) return false;
   H = iHigh(_Symbol, tfr, 1);
   L = iLow(_Symbol, tfr, 1);
   C = iClose(_Symbol,tfr, 1);
   if(H<=0 || L<=0) return false;
   return true;
}
//------------------ CALC: multi-mode pivots ------------------
PivotLevels CalcPivots(const double H, const double L, const double C, const PivotCalcMode mode)
{
   PivotLevels x;
   double range = H - L;
   double P=0,R1=0,R2=0,R3=0,R4=0,R5=0,S1=0,S2=0,S3=0,S4=0,S5=0;
   if(mode == PIVOT_WOODIE)
   {
      P = (H + L + 2.0*C) / 4.0;
      R1 = 2.0*P - L;
      S1 = 2.0*P - H;
      R2 = P + range;
      S2 = P - range;
      R3 = H + 2.0*(P - L);
      S3 = L - 2.0*(H - P);
      R4 = R3 + range;
      S4 = S3 - range;
      R5 = R4 + range;
      S5 = S4 - range;
   }
   else if(mode == PIVOT_FIBO)
   {
      P = (H + L + C) / 3.0;
      R1 = P + 0.382*range;
      S1 = P - 0.382*range;
      R2 = P + 0.618*range;
      S2 = P - 0.618*range;
      R3 = P + 1.000*range;
      S3 = P - 1.000*range;
      R4 = P + 1.618*range;
      S4 = P - 1.618*range;
      R5 = P + 2.618*range;
      S5 = P - 2.618*range;
   }
   else if(mode == PIVOT_CAMARILLA)
   {
      P = (H + L + C) / 3.0;
      R1 = C + (range * 1.1 / 12.0);
      S1 = C - (range * 1.1 / 12.0);
      R2 = C + (range * 1.1 / 6.0);
      S2 = C - (range * 1.1 / 6.0);
      R3 = C + (range * 1.1 / 4.0);
      S3 = C - (range * 1.1 / 4.0);
      R4 = C + (range * 1.1 / 2.0);
      S4 = C - (range * 1.1 / 2.0);
      R5 = (L > 0.0 ? (H / L) * C : 0.0);
      S5 = (R5 > 0.0 ? C - (R5 - C) : 0.0);
   }
   else // CLASSIC
   {
      P = (H + L + C) / 3.0;
      R1 = 2.0*P - L;
      S1 = 2.0*P - H;
      R2 = P + range;
      S2 = P - range;
      R3 = H + 2.0*(P - L);
      S3 = L - 2.0*(H - P);
      R4 = R3 + range;
      S4 = S3 - range;
      R5 = R4 + range;
      S5 = S4 - range;
   }
   x.P=P; x.R1=R1; x.R2=R2; x.R3=R3; x.R4=R4; x.R5=R5; x.S1=S1; x.S2=S2; x.S3=S3; x.S4=S4; x.S5=S5;
   return x;
}
//------------------ DRAW SET ------------------
void DrawPivotSet(const PivotTF tf, const PivotLevels &p,
                  const color colP, const color colR, const color colS,
                  const ENUM_LINE_STYLE style, const int width)
{
   string tfTag = PivotTFName(tf);
   string lvls[]={"P","R1","R2","R3","R4","R5","S1","S2","S3","S4","S5"};
   for(int i=0;i<ArraySize(lvls);i++)
   {
      string lvl = lvls[i];
      string ln = ObjLineName(tf, lvl);
      string tx = ObjTextName(tf, lvl);
      if(!PivotLevelEnabled(lvl))
      {
         ObjectDelete(0, ln);
         ObjectDelete(0, tx);
         continue;
      }
      double price = PivotLevelPrice(p, lvl);
      if(price <= 0.0)
      {
         ObjectDelete(0, ln);
         ObjectDelete(0, tx);
         continue;
      }
      color c = PivotLevelColor(lvl, colP, colR, colS);
      // line
      SetHLine(ln, price, c, style, width);
      // label
      string label = PivotMakeLabel(tfTag, lvl, price);
      if(StringLen(label) > 0)
         SetLabelRightEdgeAtPrice(tx, label, price, c);
      else
         ObjectDelete(0, tx);
   }
}
//------------------ PUBLIC: Update ------------------
void UpdatePivots()
{
   if(!EnablePivots)
   {
      DeleteAllPivots();
      return;
   }
   // ridisegniamo SEMPRE per mantenere labels perfette su zoom/scroll/TF
   if(PivotDaily_Enable)
   {
      double H,L,C;
      if(GetPrevPeriodHLC(PIV_D, H, L, C))
      {
         PivotLevels p = CalcPivots(H,L,C, PivotMode);
         DrawPivotSet(PIV_D, p, PivotD_ColorP, PivotD_ColorR, PivotD_ColorS, PivotD_Style, PivotD_Width);
      }
   }
   else DeletePivotObjectsByTF(PIV_D);
   if(PivotWeekly_Enable)
   {
      double H,L,C;
      if(GetPrevPeriodHLC(PIV_W, H, L, C))
      {
         PivotLevels p = CalcPivots(H,L,C, PivotMode);
         DrawPivotSet(PIV_W, p, PivotW_ColorP, PivotW_ColorR, PivotW_ColorS, PivotW_Style, PivotW_Width);
      }
   }
   else DeletePivotObjectsByTF(PIV_W);
   if(PivotMonthly_Enable)
   {
      double H,L,C;
      if(GetPrevPeriodHLC(PIV_M, H, L, C))
      {
         PivotLevels p = CalcPivots(H,L,C, PivotMode);
         DrawPivotSet(PIV_M, p, PivotM_ColorP, PivotM_ColorR, PivotM_ColorS, PivotM_Style, PivotM_Width);
      }
   }
   else DeletePivotObjectsByTF(PIV_M);
}


//------------------ FORWARD DECLARATION ------------------
void UpdatePanel_Live();
void UpdatePanel();              // Day/Week/News (lento)
void UpdatePanel_Signal();       // Signal (solo se serve)


bool IsNewsBlockedNow()
{
   g_newsBlockedNow=false;
   g_newsReason="";
   g_newsNearestTime=0;

   if(!EnableNewsFilter) return false;

   datetime now=TimeCurrent();
   datetime nt=0;
   string txt="";
   int blocked = CalendarGetNearestBlockingEvent(now, nt, txt);

   if(blocked==1)
   {
      g_newsBlockedNow=true;
      g_newsReason=txt;
      g_newsNearestTime=nt;
      return true;
   }

   if(StringLen(txt)>0)
   {
      g_newsReason=txt;
      g_newsNearestTime=nt;
   }
   return false;
}

//------------------ ON INIT ------------------
int OnInit()
{
   g_trade.SetExpertMagicNumber(MagicNumber);

   // ✅ PULIZIA: elimina Label orfani e vecchi PP_ prima di ricreare il pannello
   CleanupOrphanLabels();

   CreateLabels();
   InitPanelCache();
   HideWeeklyRows(!EnableWeeklyTarget);
   
   // FORZA RESET COMPLETO DELLA SETTIMANA AD OGNI AVVIO / RIATTACCO
   g_weekStartTime = 0;
   lastKnownMonday = 0;
   g_weekStartBalance = 0;
   
   CheckWeekStart();   // carica il lunedì storico
   InitDayWeek();      // solo giorno (rimane invariato)

   if(UseSignalEngine)
   {
      hMACD = iMACD(_Symbol,_Period,MACD_Fast,MACD_Slow,MACD_Signal,PRICE_CLOSE);
      hRSI = iRSI(_Symbol,_Period,RSI_Period,PRICE_CLOSE);
      hStoch = iStochastic(_Symbol,_Period,Stoch_K,Stoch_D,Stoch_Slow,StochMethod,StochPrice);
      hATR = iATR(_Symbol,_Period,ATR_Period);
      hADX = iADX(_Symbol,_Period,ADX_Period);
      hSAR = iSAR(_Symbol,_Period,SAR_Step,SAR_Max);
      hMA1 = iMA(_Symbol,_Period,EMA_1,0,EMA_Method,PRICE_CLOSE);
      hMA2 = iMA(_Symbol,_Period,EMA_2,0,EMA_Method,PRICE_CLOSE);
      hMA3 = iMA(_Symbol,_Period,EMA_3,0,EMA_Method,PRICE_CLOSE);
      hMA4 = iMA(_Symbol,_Period,EMA_4,0,EMA_Method,PRICE_CLOSE);
      hMA5 = iMA(_Symbol,_Period,EMA_5,0,EMA_Method,PRICE_CLOSE);
      if(UseHTFTrendConfirm)
         hHTFTrend = iMA(_Symbol,HTF_Trend_TF,HTF_Trend_EMA,0,MODE_EMA,PRICE_CLOSE);
      // Fase 6: rimosso il secondo filtro ATR (regime volatilita).
   }

   EventSetTimer(1);

// primo paint completo (evita righe vuote al primo avvio)
UpdatePanel_Live();
UpdatePanel_DayWeekNews();
UpdatePanel_Signal();
UpdatePivots();

ChartRedraw(0);
return INIT_SUCCEEDED;
}

//======================== CLEANUP ORPHAN LABELS =========================
void CleanupOrphanLabels()
{
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, -1);
      if(StringLen(name) <= 0) continue;

      if(StringFind(name, "PP_") == 0)
      {
         ObjectDelete(0, name);
         continue;
      }

      if(StringFind(name, PivotPrefix) == 0)
      {
         ObjectDelete(0, name);
         continue;
      }
   }
}
//+------------------------------------------------------------------+
//| Helper per Overnight Policy                                      |
//+------------------------------------------------------------------+
bool SameDay(datetime a, datetime b)
{
   MqlDateTime x,y;
   TimeToStruct(a,x);
   TimeToStruct(b,y);
   return (x.year==y.year && x.mon==y.mon && x.day==y.day);
}

bool IsAfterOvernightTime(datetime now)
{
   MqlDateTime t; TimeToStruct(now,t);
   int nowMin = t.hour*60 + t.min;
   int trgMin = OvernightCloseHour*60 + OvernightCloseMinute;
   return (nowMin >= trgMin);
}

//+------------------------------------------------------------------+
//| OVERNIGHT POLICY - Chiusura serale configurabile                 |
//+------------------------------------------------------------------+
void ApplyOvernightPolicy()
{
   if(OvernightMode == OVERNIGHT_DO_NOTHING) return;

   datetime now = TimeCurrent();
   if(!IsAfterOvernightTime(now)) return;
   if(g_lastOvernightActionDay != 0 && SameDay(g_lastOvernightActionDay, now)) return;

   int closed = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--)
   {
      ulong tk = PositionGetTicket(i);
      if(tk == 0) continue;
      if(!PositionSelectByTicket(tk)) continue;
      if(!PositionPassFilters()) continue;

      double profit = PositionGetDouble(POSITION_PROFIT);
      bool doClose = false;

      if(OvernightMode == OVERNIGHT_CLOSE_ALL_BEFORE_TIME) doClose = true;
      else if(OvernightMode == OVERNIGHT_KEEP_PROFIT_CLOSE_LOSS && profit < 0) doClose = true;
      else if(OvernightMode == OVERNIGHT_KEEP_LOSS_CLOSE_PROFIT && profit > 0) doClose = true;

      if(doClose)
      {
         long type = PositionGetInteger(POSITION_TYPE);
         double vol = PositionGetDouble(POSITION_VOLUME);
         if(vol > 0 && ClosePartialPositionWithCheck(tk, vol, type))
            closed++;
      }
   }

   g_lastOvernightActionDay = now;
   Dbg(StringFormat("OVERNIGHT ACTION | mode=%d | closed=%d", (int)OvernightMode, closed));
}

//======================== ON TIMER =========================
void OnTimer()
{
   static datetime lastWeekCheck = 0;
   static datetime lastSlowPanel = 0;

   datetime now = TimeCurrent();

   if(now - lastWeekCheck >= 60)
   {
      CheckWeekStart();
      lastWeekCheck = now;
   }

   InitDayWeek();
   CheckTargetsAndNotify();

   UpdatePanel_Live();

   if(now - lastSlowPanel >= 5)
   {
      UpdatePanel(); // SOLO day/week/news (adesso)
      lastSlowPanel = now;
   }

if(IsNewBarForPanel())
   UpdatePanel_Signal();

   if(g_piv_needRedraw)
   {
      UpdatePivots();
      g_piv_needRedraw = false;
   }

   SendOrderUpdateNotification_MT5();

   ChartRedraw(0);
}


//======================== ON TICK =========================

void OnTick()
{
   InitDayWeek();
   ApplyOvernightPolicy();
   ManageWeekendProtection();
   ProcessSignalAndTrade();

ManageOpenPositions();
ManageEquityLock();
}

//===================== TRADE TRANSACTION (DETAILED TELEGRAM) =====================
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   if(!TelegramDetailedEvents) return;
   if(!EnableTelegramNotifications) return;
   string sym = trans.symbol;
   if(StringLen(sym)<=0) sym = _Symbol;
   // --- FIX: in MT5 non usare trans.magic (spesso non esiste). Ricava magic così:
   long magic = (long)request.magic; // fonte primaria (quando disponibile)
   // fallback 1: posizione
   if(magic==0 && trans.position>0)
   {
      if(PositionSelectByTicket((ulong)trans.position))
      {
         string ps = PositionGetString(POSITION_SYMBOL);
         if(StringLen(ps)>0) sym = ps;
         magic = (long)PositionGetInteger(POSITION_MAGIC);
      }
   }
   // fallback 2: ordine
   if(magic==0 && trans.order>0)
   {
      if(OrderSelect((ulong)trans.order))
      {
         string os = OrderGetString(ORDER_SYMBOL);
         if(StringLen(os)>0) sym = os;
         magic = (long)OrderGetInteger(ORDER_MAGIC);
      }
   }
   // fallback 3: deal (storico)
   if(magic==0 && trans.deal>0)
   {
      if(HistoryDealSelect((ulong)trans.deal))
      {
         string ds = HistoryDealGetString((ulong)trans.deal, DEAL_SYMBOL);
         if(StringLen(ds)>0) sym = ds;
         magic = (long)HistoryDealGetInteger((ulong)trans.deal, DEAL_MAGIC);
      }
   }
   // filtri Telegram (qui se magic=0 e hai filtro magic attivo, i manuali verranno esclusi)
   if(!PassTelegramFilters(sym, magic))
      return;
   datetime now = TimeCurrent();
   string ts = TimeToString(now, TIME_DATE|TIME_SECONDS);
   string msg = "";
   // 1) ORDINE (creazione/modifica/cancellazione)
   if(trans.type == TRADE_TRANSACTION_ORDER_ADD ||
      trans.type == TRADE_TRANSACTION_ORDER_UPDATE ||
      trans.type == TRADE_TRANSACTION_ORDER_DELETE)
   {
      ulong order_ticket = (ulong)trans.order;
      bool okSel = (order_ticket>0 && OrderSelect(order_ticket));
      long otype = okSel ? (long)OrderGetInteger(ORDER_TYPE) : (long)trans.order_type;
      long ostate = okSel ? (long)OrderGetInteger(ORDER_STATE): (long)trans.order_state;
      double ovol = okSel ? OrderGetDouble(ORDER_VOLUME_CURRENT) : trans.volume;
      double oprice = okSel ? OrderGetDouble(ORDER_PRICE_OPEN) : trans.price;
      double osl = okSel ? OrderGetDouble(ORDER_SL) : trans.price_sl;
      double otp = okSel ? OrderGetDouble(ORDER_TP) : trans.price_tp;
      // se OrderSelect riuscito, riallineo simbolo/magic corretti
      if(okSel)
      {
         string os = OrderGetString(ORDER_SYMBOL);
         if(StringLen(os)>0) sym = os;
         long om = (long)OrderGetInteger(ORDER_MAGIC);
         if(om!=0) magic = om;
      }
      string action =
         (trans.type==TRADE_TRANSACTION_ORDER_ADD ? "📌 ORDER PLACED" :
          trans.type==TRADE_TRANSACTION_ORDER_UPDATE ? "✏️ ORDER UPDATED" :
          "🗑 ORDER DELETED");
      string sig = StringFormat("ORD|%d|%I64u|%s|%d|%.4f|%s|%s|%s",
                                (int)trans.type, order_ticket, sym, (int)magic, ovol,
                                FormatPrice(oprice), FormatPrice(osl), FormatPrice(otp));
      if(TgDedupeHit(sig)) return;
      msg = StringFormat(
         "%s\nTime: %s\nSymbol: %s\nMagic: %d\nTicket: %I64u\nType: %s\nState: %d\nVol: %.4f\nPrice: %s\nSL: %s | TP: %s",
         action, ts, sym, (int)magic, order_ticket, SideToStr(otype), (int)ostate,
         ovol, FormatPrice(oprice), FormatPrice(osl), FormatPrice(otp)
      );
   }
   // 2) DEAL (eseguito reale: entrata/uscita/parziale/SL/TP)
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      ulong deal_ticket = (ulong)trans.deal;
      if(deal_ticket>0 && HistoryDealSelect(deal_ticket))
      {
         long dtype = (long)HistoryDealGetInteger(deal_ticket, DEAL_TYPE);
         long dentry = (long)HistoryDealGetInteger(deal_ticket, DEAL_ENTRY);
         long dmagic = (long)HistoryDealGetInteger(deal_ticket, DEAL_MAGIC);
         string dsym = HistoryDealGetString(deal_ticket, DEAL_SYMBOL);
         double dvol = HistoryDealGetDouble(deal_ticket, DEAL_VOLUME);
         double dprice = HistoryDealGetDouble(deal_ticket, DEAL_PRICE);
         double dprofit= HistoryDealGetDouble(deal_ticket, DEAL_PROFIT)
                       + HistoryDealGetDouble(deal_ticket, DEAL_COMMISSION)
                       + HistoryDealGetDouble(deal_ticket, DEAL_SWAP)
                       + HistoryDealGetDouble(deal_ticket, DEAL_FEE);
         long dreason = (long)HistoryDealGetInteger(deal_ticket, DEAL_REASON);
         // riallineo symbol/magic “ufficiali” del deal
         sym = dsym;
         magic = dmagic;
         if(!PassTelegramFilters(dsym, dmagic))
            return;
         string entryTxt =
            (dentry==DEAL_ENTRY_IN ? "ENTRY (IN)" :
             dentry==DEAL_ENTRY_OUT ? "EXIT (OUT)" :
             dentry==DEAL_ENTRY_INOUT ? "IN/OUT" : IntegerToString((int)dentry));
         string typeTxt =
            (dtype==DEAL_TYPE_BUY ? "BUY" :
             dtype==DEAL_TYPE_SELL ? "SELL" :
             IntegerToString((int)dtype));
         string sig = StringFormat("DEAL|%I64u|%s|%d|%.4f|%s|%.2f|%d",
                                   deal_ticket, dsym, (int)dmagic, dvol, FormatPrice(dprice), dprofit, (int)dentry);
         if(TgDedupeHit(sig)) return;
         msg = StringFormat(
            "✅ DEAL EXECUTED\nTime: %s\nSymbol: %s\nMagic: %d\nDeal: %I64u\n%s | %s\nVol: %.4f\nPrice: %s\nP/L: %.2f\nReason: %d",
            ts, dsym, (int)dmagic, deal_ticket, typeTxt, entryTxt, dvol, FormatPrice(dprice), dprofit, (int)dreason
         );
      }
   }
   // 3) POSITION (aggiornamenti posizione: perfetto per SL/TP e “entrato a mercato”)
   if(trans.type == TRADE_TRANSACTION_POSITION)
   {
      ulong pos_ticket = (ulong)trans.position;
      if(pos_ticket>0 && PositionSelectByTicket(pos_ticket))
      {
         string psym = PositionGetString(POSITION_SYMBOL);
         long pmg = (long)PositionGetInteger(POSITION_MAGIC);
         long ptype = (long)PositionGetInteger(POSITION_TYPE);
         double pvol = PositionGetDouble(POSITION_VOLUME);
         double popen = PositionGetDouble(POSITION_PRICE_OPEN);
         double psl = PositionGetDouble(POSITION_SL);
         double ptp = PositionGetDouble(POSITION_TP);
         double ppr = PositionGetDouble(POSITION_PROFIT);
         // riallineo
         sym = psym;
         magic = pmg;
         if(!PassTelegramFilters(psym, pmg))
            return;
         string sig = StringFormat("POS|%I64u|%s|%d|%.4f|%s|%s|%s",
                                   pos_ticket, psym, (int)ptype, pvol,
                                   FormatPrice(popen), FormatPrice(psl), FormatPrice(ptp));
         if(TgDedupeHit(sig)) return;
         msg = StringFormat(
            "📍 POSITION UPDATE\nTime: %s\nSymbol: %s\nMagic: %d\nPos: %I64u\nSide: %s\nVol: %.4f\nOpen: %s\nSL: %s | TP: %s\nFloating: %.2f",
            ts, psym, (int)pmg, pos_ticket, SideToStr(ptype), pvol,
            FormatPrice(popen), FormatPrice(psl), FormatPrice(ptp), ppr
         );
      }
   }
   if(StringLen(msg)>0)
      SendTelegramMessageWithRetry(msg + AccountSnapIfEnabled());
}


void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_CHART_CHANGE)
      g_piv_needRedraw = true;
}


void DeletePanelObjects()
{
   // cancella tutti i label del panel (PP_)
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, "PP_") == 0)
         ObjectDelete(0, name);
   }
}

void DeletePivotObjects()
{
   // cancella tutto ciò che inizia con PivotPrefix (es. "PPIV_")
   int total = ObjectsTotal(0, 0, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, -1);
      if(StringFind(name, PivotPrefix) == 0)
         ObjectDelete(0, name);
   }
}


//======================== ON DE INIT =========================

void OnDeinit(const int reason)
{
   EventKillTimer();

   CleanupOrphanLabels(); // elimina PP_*
   DeleteAllPivots();     // elimina pivot objects

   ChartRedraw(0);
}