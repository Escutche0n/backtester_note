(function(){
// Backtester Note — shared data + chart primitives (React, Babel)
// Exported to window so every screen script can consume them.

// ─── Seeded RNG for stable mock data ────────────────────────
function mulberry32(seed) {
  return function () {
    let t = (seed += 0x6D2B79F5);
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// ─── Mock funds (real codes / names, fabricated holdings) ────
const FUNDS = [
  { code: '510300', name: '沪深300ETF', type: '宽基', shortName: 'HS300', color: '#E3B15C' },
  { code: '513500', name: '标普500ETF', type: '海外', shortName: 'SP500', color: '#6FA8DC' },
  { code: '512100', name: '中证1000ETF', type: '宽基', shortName: 'ZZ1000', color: '#C99A6B' },
  { code: '159920', name: '恒生ETF', type: '海外', shortName: 'HSI', color: '#8884D8' },
  { code: '512760', name: '芯片ETF', type: '行业', shortName: 'CHIP', color: '#D67B7B' },
  { code: '512170', name: '医疗ETF', type: '行业', shortName: 'MED', color: '#7FB88F' },
  { code: '159915', name: '创业板ETF', type: '宽基', shortName: 'GEM', color: '#B89868' },
  { code: '518880', name: '黄金ETF', type: '商品', shortName: 'AU', color: '#C5A572' },
];

// ─── Mock holdings with NAV-like state ───────────────────────
const HOLDINGS = [
  { code: '510300', name: '沪深300ETF',   type: '宽基', target: 0.30, value: 48_320.42, cost: 42_100.00,  shares: 19840, dayPct: +1.24, holdPct: +14.77, trend: +1 },
  { code: '513500', name: '标普500ETF',   type: '海外', target: 0.25, value: 42_180.88, cost: 38_500.00,  shares:  2420, dayPct: -0.42, holdPct:  +9.56, trend: +1 },
  { code: '512100', name: '中证1000ETF', type: '宽基',  target: 0.15, value: 24_106.55, cost: 26_800.00,  shares:  9840, dayPct: +2.11, holdPct: -10.05, trend: -1 },
  { code: '512760', name: '芯片ETF',      type: '行业', target: 0.10, value: 19_844.10, cost: 15_200.00,  shares: 12900, dayPct: +3.47, holdPct: +30.55, trend: +1 },
  { code: '512170', name: '医疗ETF',      type: '行业', target: 0.10, value:  9_233.40, cost: 12_600.00,  shares:  8760, dayPct: -1.18, holdPct: -26.72, trend: -1 },
  { code: '518880', name: '黄金ETF',      type: '商品', target: 0.10, value: 12_940.22, cost: 10_100.00,  shares:  1860, dayPct: +0.68, holdPct: +28.12, trend: +1 },
];

const TOTAL_VALUE = HOLDINGS.reduce((a, h) => a + h.value, 0);
const TOTAL_COST  = HOLDINGS.reduce((a, h) => a + h.cost, 0);

// Overview metrics (computed + hand-tuned to look real)
const OVERVIEW = {
  totalValue: TOTAL_VALUE,
  nav: 1.2847,           // 账户单位净值
  dayPnl: +1_284.62,
  dayPct: +0.85,
  dayDrawdown: -0.32,    // 当日回撤 %
  holdPnl: TOTAL_VALUE - TOTAL_COST,
  holdPct: ((TOTAL_VALUE - TOTAL_COST) / TOTAL_COST) * 100,
  xirr: +12.83,          // %
  excess: +4.62,         // vs 沪深300
  maxDrawdown6m: -8.24,
  sharpe: 1.42,
  calmar: 1.78,
  unbalance: 0.143,      // 失衡比例 (L2 from target weights)
};

// ─── NAV curve generator ────────────────────────────────────
function makeSeries(days, seed, startVal = 0, vol = 0.008, drift = 0.0006) {
  const rand = mulberry32(seed);
  const out = [{ i: 0, v: startVal }];
  let v = startVal;
  for (let i = 1; i <= days; i++) {
    const shock = (rand() - 0.5) * 2 * vol + drift;
    v = v + shock * 100; // convert to % scale
    // smooth a bit
    v = v * 0.995 + (i * drift * 50);
    out.push({ i, v });
  }
  return out;
}

const NAV_SERIES = {
  '1M':  { days: 30,  account: makeSeries(30, 12345, 0, 0.010, 0.0012), bench: makeSeries(30, 9911, 0, 0.009, 0.0007) },
  '3M':  { days: 90,  account: makeSeries(90, 23456, 0, 0.009, 0.0010), bench: makeSeries(90, 8833, 0, 0.009, 0.0006) },
  '6M':  { days: 180, account: makeSeries(180, 34567, 0, 0.008, 0.0009), bench: makeSeries(180, 7722, 0, 0.008, 0.0005) },
  '1Y':  { days: 365, account: makeSeries(365, 45678, 0, 0.008, 0.0008), bench: makeSeries(365, 6611, 0, 0.008, 0.0004) },
};

// ─── Radar: 6 dims × 3 snapshots ─────────────────────────────
const RADAR = {
  dims: ['超额收益', '执行程度', '投资纪律', '风险控制', '风格', '收益'],
  current: [78, 84, 72, 65, 70, 76],
  lastWeek: [74, 81, 75, 62, 68, 72],
  lastMonth: [69, 77, 70, 58, 65, 68],
  scores: { current: 74.2, lastWeek: 72.0, lastMonth: 67.8 },
};

// ─── Portfolios (saved/favorite) ─────────────────────────────
const PORTFOLIOS = [
  { id: 'p1', name: '核心-卫星', funds: ['510300','513500','512100','512760'], weights: [0.40,0.30,0.20,0.10], note: '60/40 变体,季度再平衡' },
  { id: 'p2', name: '全天候',     funds: ['510300','513500','518880','159920'], weights: [0.30,0.30,0.20,0.20], note: '风险平价' },
  { id: 'p3', name: '进攻型',     funds: ['512100','512760','159915'],          weights: [0.40,0.35,0.25], note: '高波动,月度再平衡' },
];

// ─── Backtest history records ───────────────────────────────
const BACKTESTS = [
  { id: 'b1', name: '核心-卫星 · 月定投',  type: 'portfolio', period: '2020-01 → 2025-12', cagr: +11.8, maxdd: -18.2, sharpe: 1.23, xirr: +12.1, savedAt: '04-18' },
  { id: 'b2', name: '沪深300 · 周定投',    type: 'sip',       period: '2018-01 → 2025-12', cagr:  +6.4, maxdd: -32.1, sharpe: 0.58, xirr:  +6.9, savedAt: '04-15' },
  { id: 'b3', name: '全天候 · 季再平衡',   type: 'portfolio', period: '2019-01 → 2025-12', cagr:  +8.2, maxdd: -11.4, sharpe: 1.38, xirr:  +8.5, savedAt: '04-10' },
  { id: 'b4', name: '芯片ETF · 单基',       type: 'single',    period: '2021-01 → 2025-12', cagr: -2.1,  maxdd: -46.8, sharpe: 0.12, xirr: -1.8, savedAt: '04-03' },
];

// ─── Primitive: LineChart (thin line + soft fill) ────────────
function LineChart({ series = [], benchmark = null, width = 358, height = 140, padX = 0, padY = 12, color = '#F6465D', benchColor = '#7A8AA8', isUp = true, showFill = true, showGrid = true, showAxis = false }) {
  if (!series.length) return null;
  const all = benchmark ? [...series, ...benchmark] : series;
  const minV = Math.min(...all.map(d => d.v));
  const maxV = Math.max(...all.map(d => d.v));
  const range = maxV - minV || 1;
  const xs = series.length - 1;

  const toX = (i) => padX + (i / xs) * (width - padX * 2);
  const toY = (v) => padY + (1 - (v - minV) / range) * (height - padY * 2);

  const path = series.map((d, i) => `${i ? 'L' : 'M'}${toX(i).toFixed(2)},${toY(d.v).toFixed(2)}`).join(' ');
  const fill = `${path} L${toX(xs).toFixed(2)},${(height - padY).toFixed(2)} L${toX(0).toFixed(2)},${(height - padY).toFixed(2)} Z`;
  const benchPath = benchmark ? benchmark.map((d, i) => `${i ? 'L' : 'M'}${toX(i).toFixed(2)},${toY(d.v).toFixed(2)}`).join(' ') : null;

  // Zero line
  const zeroY = toY(0);
  const showZero = minV < 0 && maxV > 0;
  const gradId = `grad-${Math.abs(series[0].v * 1000 | 0)}-${series.length}`;

  return (
    <svg width={width} height={height} viewBox={`0 0 ${width} ${height}`} style={{ display: 'block' }}>
      <defs>
        <linearGradient id={gradId} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={color} stopOpacity={0.22}/>
          <stop offset="100%" stopColor={color} stopOpacity={0}/>
        </linearGradient>
      </defs>
      {showGrid && (
        <g>
          {[0.25, 0.5, 0.75].map(t => (
            <line key={t} x1={padX} y1={padY + t * (height - padY * 2)} x2={width - padX} y2={padY + t * (height - padY * 2)} className="bn-gridline" strokeDasharray="2,4"/>
          ))}
        </g>
      )}
      {showZero && <line x1={padX} y1={zeroY} x2={width - padX} y2={zeroY} stroke="rgba(255,255,255,0.18)" strokeWidth="0.5" strokeDasharray="3,3"/>}
      {benchPath && <path d={benchPath} fill="none" stroke={benchColor} strokeWidth="1.25" strokeLinecap="round" strokeLinejoin="round" strokeDasharray="3,3" opacity="0.75"/>}
      {showFill && <path d={fill} fill={`url(#${gradId})`}/>}
      <path d={path} fill="none" stroke={color} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}

// ─── Primitive: Sparkline (tiny, no axis) ────────────────────
function Sparkline({ series, width = 56, height = 18, color = '#F6465D' }) {
  return <LineChart series={series} width={width} height={height} padX={1} padY={2} color={color} showFill={false} showGrid={false}/>;
}

// ─── Primitive: Radar ────────────────────────────────────────
function Radar({ dims, series = [], colors = [], size = 260, max = 100 }) {
  const cx = size / 2, cy = size / 2;
  const r = size / 2 - 32;
  const n = dims.length;

  const point = (i, val) => {
    const a = (Math.PI * 2 * i) / n - Math.PI / 2;
    const rr = (val / max) * r;
    return [cx + Math.cos(a) * rr, cy + Math.sin(a) * rr];
  };
  const labelPoint = (i) => {
    const a = (Math.PI * 2 * i) / n - Math.PI / 2;
    const rr = r + 18;
    return [cx + Math.cos(a) * rr, cy + Math.sin(a) * rr];
  };

  const polyFor = (vals) => vals.map((v, i) => point(i, v).join(',')).join(' ');

  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      {/* grid */}
      {[0.25, 0.5, 0.75, 1].map((t, idx) => (
        <polygon
          key={idx}
          points={dims.map((_, i) => point(i, max * t).join(',')).join(' ')}
          fill="none"
          stroke="rgba(255,255,255,0.07)"
          strokeWidth="0.5"
        />
      ))}
      {/* spokes */}
      {dims.map((_, i) => {
        const [x, y] = point(i, max);
        return <line key={i} x1={cx} y1={cy} x2={x} y2={y} stroke="rgba(255,255,255,0.05)" strokeWidth="0.5"/>;
      })}
      {/* data polygons — last one drawn on top */}
      {series.map((vals, idx) => {
        const c = colors[idx] || '#fff';
        const isTop = idx === series.length - 1;
        return (
          <g key={idx}>
            <polygon points={polyFor(vals)} fill={c} fillOpacity={isTop ? 0.18 : 0.06} stroke={c} strokeWidth={isTop ? 1.5 : 1} strokeOpacity={isTop ? 1 : 0.5}/>
            {isTop && vals.map((v, i) => {
              const [x, y] = point(i, v);
              return <circle key={i} cx={x} cy={y} r="2.5" fill={c}/>;
            })}
          </g>
        );
      })}
      {/* labels */}
      {dims.map((d, i) => {
        const [x, y] = labelPoint(i);
        return (
          <text key={d} x={x} y={y} fontSize="10.5" fontFamily="var(--bn-sans)" fontWeight="500"
                fill="rgba(242,242,245,0.62)" textAnchor="middle" dominantBaseline="middle">{d}</text>
        );
      })}
    </svg>
  );
}

// ─── Number formatters ──────────────────────────────────────
const fmt = {
  money: (v, d = 2) => v.toLocaleString('en-US', { minimumFractionDigits: d, maximumFractionDigits: d }),
  pct: (v, d = 2) => `${v >= 0 ? '+' : ''}${v.toFixed(d)}%`,
  pctAbs: (v, d = 2) => `${v.toFixed(d)}%`,
  money0: (v) => v.toLocaleString('en-US', { minimumFractionDigits: 0, maximumFractionDigits: 0 }),
  signed: (v, d = 2) => `${v >= 0 ? '+' : ''}${v.toFixed(d)}`,
};

// Red-green color (CN market default) — can be flipped via theme
function pnlColor(v, invert = false) {
  if (v === 0) return 'var(--bn-fg-dim)';
  const up = v > 0;
  if (invert) return up ? 'var(--bn-down)' : 'var(--bn-up)';
  return up ? 'var(--bn-up)' : 'var(--bn-down)';
}

// ─── Icons (minimal, stroke-based) ──────────────────────────
const Icon = {
  Cog: ({ size = 18 }) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <circle cx="12" cy="12" r="3"/>
      <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/>
    </svg>
  ),
  Plus: ({ size = 16 }) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
  ),
  Chevron: ({ size = 14, dir = 'right' }) => {
    const rot = { right: 0, left: 180, down: 90, up: -90 }[dir];
    return <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{ transform: `rotate(${rot}deg)` }}><polyline points="9 18 15 12 9 6"/></svg>;
  },
  Dot: ({ size = 6, color = 'currentColor' }) => (
    <svg width={size} height={size} viewBox="0 0 6 6"><circle cx="3" cy="3" r="3" fill={color}/></svg>
  ),
  Home: ({ size = 22, filled = false }) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={filled ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M3 10.5L12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-7h-6v7H4a1 1 0 0 1-1-1z"/>
    </svg>
  ),
  Wallet: ({ size = 22, filled = false }) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={filled ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="6" width="18" height="14" rx="2.5"/><path d="M3 10h18"/><circle cx="17" cy="15" r="1.2" fill="currentColor"/>
    </svg>
  ),
  Beaker: ({ size = 22, filled = false }) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={filled ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M9 3h6M10 3v6L5 20a1 1 0 0 0 .9 1.4h12.2A1 1 0 0 0 19 20l-5-11V3"/>
    </svg>
  ),
  Grid: ({ size = 22, filled = false }) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill={filled ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
      <rect x="3" y="3" width="8" height="8" rx="1.5"/><rect x="13" y="3" width="8" height="8" rx="1.5"/><rect x="3" y="13" width="8" height="8" rx="1.5"/><rect x="13" y="13" width="8" height="8" rx="1.5"/>
    </svg>
  ),
  Close: ({ size = 18 }) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round"><line x1="6" y1="6" x2="18" y2="18"/><line x1="18" y1="6" x2="6" y2="18"/></svg>
  ),
  Refresh: ({ size = 14 }) => (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round">
      <polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/>
    </svg>
  ),
};

Object.assign(window, {
  FUNDS, HOLDINGS, TOTAL_VALUE, TOTAL_COST, OVERVIEW,
  NAV_SERIES, RADAR, PORTFOLIOS, BACKTESTS,
  LineChart, Sparkline, Radar,
  fmt, pnlColor, Icon, mulberry32, makeSeries,
});

})();
