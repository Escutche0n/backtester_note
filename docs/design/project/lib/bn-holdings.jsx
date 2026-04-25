(function(){
// Backtester Note — Holdings (持仓) screen
// Full-bleed iPhone content. Consumes globals exported by bn-data.jsx.

const { LineChart, Radar, Sparkline, Icon, fmt, pnlColor,
  HOLDINGS, OVERVIEW, NAV_SERIES, RADAR, TOTAL_VALUE } = window;

// ── Overview metric tile ─────────────────────────────────────
function MetricTile({ label, value, sub, valueColor, mono = true, small = false }) {
  return (
    <div style={{ padding: '10px 12px', minWidth: 0 }}>
      <div style={{ fontSize: 10.5, color: 'var(--bn-fg-mute)', fontWeight: 500, letterSpacing: '0.02em', marginBottom: 4, whiteSpace: 'nowrap' }}>{label}</div>
      <div className={mono ? 'bn-num' : ''} style={{ fontSize: small ? 13 : 14.5, fontWeight: 600, color: valueColor || 'var(--bn-fg)', letterSpacing: '-0.02em' }}>{value}</div>
      {sub && <div className="bn-num" style={{ fontSize: 10.5, color: 'var(--bn-fg-dim)', marginTop: 2 }}>{sub}</div>}
    </div>
  );
}

// ── Total value header ───────────────────────────────────────
function TotalHeader({ onSettings, invert }) {
  const upColor = pnlColor(OVERVIEW.dayPnl, invert);
  return (
    <div style={{ padding: '14px 20px 8px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div>
          <div className="bn-label">总市值 · CNY</div>
          <div className="bn-big-num" style={{ fontSize: 34, marginTop: 4, color: 'var(--bn-fg)' }}>
            ¥{fmt.money(OVERVIEW.totalValue)}
          </div>
          <div style={{ display: 'flex', gap: 8, alignItems: 'center', marginTop: 6 }}>
            <span className="bn-num" style={{ color: upColor, fontSize: 13, fontWeight: 600 }}>
              {fmt.signed(OVERVIEW.dayPnl)} · {fmt.pct(OVERVIEW.dayPct)}
            </span>
            <span style={{ fontSize: 11, color: 'var(--bn-fg-mute)' }}>今日</span>
            <span style={{ width: 3, height: 3, borderRadius: 2, background: 'var(--bn-fg-faint)' }}/>
            <span className="bn-num" style={{ fontSize: 11, color: 'var(--bn-fg-dim)' }}>
              单位净值 {OVERVIEW.nav.toFixed(4)}
            </span>
          </div>
        </div>
        <button onClick={onSettings} aria-label="设置" style={{
          width: 34, height: 34, borderRadius: 17,
          background: 'rgba(255,255,255,0.06)',
          border: '0.5px solid var(--bn-border)',
          color: 'var(--bn-fg-dim)', cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon.Cog size={16}/>
        </button>
      </div>
    </div>
  );
}

// ── Overview metrics panel ───────────────────────────────────
function OverviewPanel({ invert }) {
  const o = OVERVIEW;
  const row1 = [
    { label: '当日盈亏',   value: fmt.signed(o.dayPnl), color: pnlColor(o.dayPnl, invert) },
    { label: '当日收益率', value: fmt.pct(o.dayPct),   color: pnlColor(o.dayPct, invert) },
    { label: '当日回撤',   value: fmt.pctAbs(o.dayDrawdown), color: 'var(--bn-fg-dim)' },
  ];
  const row2 = [
    { label: '持有收益',   value: fmt.signed(o.holdPnl, 0), color: pnlColor(o.holdPnl, invert) },
    { label: '持有收益率', value: fmt.pct(o.holdPct),   color: pnlColor(o.holdPct, invert) },
    { label: 'XIRR',       value: fmt.pct(o.xirr),      color: pnlColor(o.xirr, invert) },
  ];
  const row3 = [
    { label: '超额 vs 沪深300', value: fmt.pct(o.excess), color: pnlColor(o.excess, invert) },
    { label: '近半年最大回撤',  value: fmt.pctAbs(o.maxDrawdown6m), color: 'var(--bn-fg-dim)' },
    { label: '夏普 / 卡尔马',   value: `${o.sharpe.toFixed(2)} · ${o.calmar.toFixed(2)}`, color: 'var(--bn-fg)' },
  ];

  const Row = ({ items }) => (
    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', borderTop: '0.5px solid var(--bn-border)' }}>
      {items.map((it, i) => (
        <div key={i} style={{ padding: '10px 12px', borderRight: i < 2 ? '0.5px solid var(--bn-border)' : 'none' }}>
          <div style={{ fontSize: 10, color: 'var(--bn-fg-mute)', fontWeight: 500, marginBottom: 4, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{it.label}</div>
          <div className="bn-num" style={{ fontSize: 14, fontWeight: 600, color: it.color }}>{it.value}</div>
        </div>
      ))}
    </div>
  );

  const pct = (o.unbalance * 100).toFixed(1);

  return (
    <div className="bn-glass" style={{ margin: '8px 16px 0', borderRadius: 18, overflow: 'hidden' }}>
      <div style={{ padding: '10px 14px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ fontSize: 12, color: 'var(--bn-fg-dim)', fontWeight: 600 }}>总览</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <span style={{ fontSize: 10.5, color: 'var(--bn-fg-mute)' }}>失衡</span>
          <span className="bn-num" style={{ fontSize: 11, fontWeight: 600, color: o.unbalance > 0.1 ? 'var(--bn-accent)' : 'var(--bn-fg-dim)' }}>
            {pct}%
          </span>
          <div style={{ width: 44 }}>
            <div className="bn-bar"><span style={{ width: Math.min(100, o.unbalance * 300) + '%', background: o.unbalance > 0.1 ? 'var(--bn-accent)' : 'var(--bn-fg-mute)' }}/></div>
          </div>
        </div>
      </div>
      <Row items={row1}/>
      <Row items={row2}/>
      <Row items={row3}/>
    </div>
  );
}

// ── NAV curve card with range selector ──────────────────────
function NavCard({ invert, fillMode = 'soft' }) {
  const [range, setRange] = React.useState('3M');
  const data = NAV_SERIES[range];
  const acct = data.account, bench = data.bench;
  const lastV = acct[acct.length - 1].v;
  const lastB = bench[bench.length - 1].v;
  const excess = lastV - lastB;
  const isUp = lastV >= 0;
  const color = isUp ? (invert ? 'var(--bn-down)' : 'var(--bn-up)') : (invert ? 'var(--bn-up)' : 'var(--bn-down)');
  const colorHex = isUp ? (invert ? '#2EBD85' : '#F6465D') : (invert ? '#F6465D' : '#2EBD85');

  return (
    <div className="bn-glass" style={{ margin: '14px 16px 0', borderRadius: 18, padding: '14px 0 10px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', padding: '0 16px 8px' }}>
        <div>
          <div style={{ fontSize: 12, color: 'var(--bn-fg-dim)', fontWeight: 600, marginBottom: 2 }}>净值曲线</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8 }}>
            <span className="bn-num" style={{ fontSize: 22, fontWeight: 600, color }}>
              {lastV >= 0 ? '+' : ''}{lastV.toFixed(2)}%
            </span>
            <span className="bn-num" style={{ fontSize: 11, color: 'var(--bn-fg-dim)' }}>
              账户 · 从起始日
            </span>
          </div>
        </div>
        <div style={{ textAlign: 'right' }}>
          <div className="bn-num" style={{ fontSize: 12, color: 'var(--bn-benchmark)', fontWeight: 500 }}>
            {lastB >= 0 ? '+' : ''}{lastB.toFixed(2)}% <span style={{ fontSize: 10, color: 'var(--bn-fg-mute)' }}>沪深300</span>
          </div>
          <div className="bn-num" style={{ fontSize: 11, color: pnlColor(excess, invert), fontWeight: 600, marginTop: 2 }}>
            超额 {excess >= 0 ? '+' : ''}{excess.toFixed(2)}%
          </div>
        </div>
      </div>
      <div style={{ padding: '0 8px' }}>
        <LineChart series={acct} benchmark={bench} width={358} height={140} padX={8} color={colorHex} showFill={fillMode !== 'none'}/>
      </div>
      <div style={{ padding: '8px 16px 0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div className="bn-seg">
          {['1M','3M','6M','1Y','自定义'].map(r => (
            <button key={r} className={range === r ? 'on' : ''} onClick={() => setRange(r === '自定义' ? '1Y' : r)}>{r}</button>
          ))}
        </div>
        <div style={{ display: 'flex', gap: 10, fontSize: 10, color: 'var(--bn-fg-mute)' }}>
          <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
            <span style={{ width: 8, height: 2, background: colorHex, borderRadius: 1 }}/>账户
          </span>
          <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
            <span style={{ width: 8, height: 0, borderTop: '1px dashed var(--bn-benchmark)' }}/>基准
          </span>
        </div>
      </div>
    </div>
  );
}

// ── Trend Radar card ─────────────────────────────────────────
function RadarCard() {
  const [snap, setSnap] = React.useState('current'); // current / lastWeek / lastMonth
  const order = ['lastMonth', 'lastWeek', 'current']; // bottom to top for layering
  const idx = order.indexOf(snap);
  const visible = order.slice(0, idx + 1);
  const series = visible.map(k => RADAR[k]);
  const colors = visible.map(k => ({
    lastMonth: 'rgba(227,177,92,0.6)',
    lastWeek:  'rgba(122,138,168,0.75)',
    current:   '#F2F2F5',
  }[k]));
  const score = RADAR.scores[snap];
  const delta = snap === 'current' ? RADAR.scores.current - RADAR.scores.lastWeek : 0;

  return (
    <div className="bn-glass" style={{ margin: '14px 16px 0', borderRadius: 18, padding: '14px 16px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
        <div>
          <div style={{ fontSize: 12, color: 'var(--bn-fg-dim)', fontWeight: 600 }}>趋势雷达</div>
          <div style={{ fontSize: 10.5, color: 'var(--bn-fg-mute)', marginTop: 2 }}>六维度投资复盘评分</div>
        </div>
        <div className="bn-seg">
          {[['current','当前'],['lastWeek','上周'],['lastMonth','上月']].map(([k, l]) => (
            <button key={k} className={snap === k ? 'on' : ''} onClick={() => setSnap(k)}>{l}</button>
          ))}
        </div>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '220px 1fr', gap: 6, alignItems: 'center' }}>
        <div style={{ marginLeft: -10 }}>
          <Radar dims={RADAR.dims} series={series} colors={colors} size={224} max={100}/>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          <div>
            <div style={{ fontSize: 10.5, color: 'var(--bn-fg-mute)', fontWeight: 600, letterSpacing: '0.06em' }}>总分</div>
            <div className="bn-num" style={{ fontSize: 28, fontWeight: 600, color: 'var(--bn-fg)' }}>{score.toFixed(1)}</div>
            {snap === 'current' && (
              <div className="bn-num" style={{ fontSize: 10.5, color: delta >= 0 ? 'var(--bn-up)' : 'var(--bn-down)', fontWeight: 600 }}>
                {delta >= 0 ? '↑' : '↓'} {Math.abs(delta).toFixed(1)} vs 上周
              </div>
            )}
          </div>
          <div style={{ display: 'grid', gap: 4, marginTop: 4 }}>
            {RADAR.dims.map((d, i) => {
              const cur = RADAR[snap][i];
              const prev = snap === 'current' ? RADAR.lastWeek[i] : snap === 'lastWeek' ? RADAR.lastMonth[i] : RADAR.lastMonth[i];
              const ddelta = cur - prev;
              return (
                <div key={d} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 10.5, gap: 6 }}>
                  <span style={{ color: 'var(--bn-fg-dim)' }}>{d}</span>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                    <span className="bn-num" style={{ color: 'var(--bn-fg)', fontWeight: 600, minWidth: 16, textAlign: 'right' }}>{cur}</span>
                    {ddelta !== 0 && snap === 'current' && (
                      <span className="bn-num" style={{ fontSize: 9, color: ddelta > 0 ? 'var(--bn-up)' : 'var(--bn-down)', minWidth: 18, textAlign: 'right' }}>
                        {ddelta > 0 ? '+' : ''}{ddelta}
                      </span>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}

// ── Holding row (wide card with imbalance bar) ──────────────
function HoldingCard({ h, invert, seed }) {
  const total = TOTAL_VALUE;
  const actual = h.value / total;
  const target = h.target;
  const delta = actual - target;
  const driftPct = Math.abs(delta) / target;
  const signColor = pnlColor(h.dayPct, invert);
  const holdColor = pnlColor(h.holdPct, invert);
  const miniSeries = React.useMemo(() => window.makeSeries(30, seed, 0, 0.012, h.trend * 0.0008), [seed, h.trend]);
  const sparkColor = h.holdPct >= 0 ? (invert ? '#2EBD85' : '#F6465D') : (invert ? '#F6465D' : '#2EBD85');

  return (
    <div className="bn-frost" style={{
      padding: '14px 14px',
      borderRadius: 14,
      marginBottom: 8,
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, minWidth: 0 }}>
          <div style={{
            width: 32, height: 32, borderRadius: 8,
            background: 'rgba(255,255,255,0.04)',
            border: '0.5px solid var(--bn-border)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontSize: 10, fontWeight: 600, color: 'var(--bn-fg-dim)',
            fontFamily: 'var(--bn-mono)',
          }}>{h.type}</div>
          <div style={{ minWidth: 0 }}>
            <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--bn-fg)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
              {h.name}
            </div>
            <div className="bn-num" style={{ fontSize: 10.5, color: 'var(--bn-fg-mute)', marginTop: 1 }}>
              {h.code} · {fmt.money0(h.shares)} 份
            </div>
          </div>
        </div>
        <div style={{ textAlign: 'right' }}>
          <div className="bn-num" style={{ fontSize: 14, fontWeight: 600, color: 'var(--bn-fg)' }}>¥{fmt.money(h.value)}</div>
          <div className="bn-num" style={{ fontSize: 10.5, color: signColor, fontWeight: 600, marginTop: 1 }}>{fmt.pct(h.dayPct)} 今日</div>
        </div>
      </div>

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 10, gap: 12 }}>
        <div style={{ display: 'flex', gap: 14 }}>
          <div>
            <div style={{ fontSize: 9.5, color: 'var(--bn-fg-mute)', fontWeight: 500 }}>持有收益</div>
            <div className="bn-num" style={{ fontSize: 12, color: holdColor, fontWeight: 600 }}>{fmt.pct(h.holdPct)}</div>
          </div>
          <div>
            <div style={{ fontSize: 9.5, color: 'var(--bn-fg-mute)', fontWeight: 500 }}>成本 / 份</div>
            <div className="bn-num" style={{ fontSize: 12, color: 'var(--bn-fg-dim)', fontWeight: 500 }}>¥{(h.cost / h.shares).toFixed(4)}</div>
          </div>
        </div>
        <div style={{ opacity: 0.9 }}>
          <Sparkline series={miniSeries} width={72} height={22} color={sparkColor}/>
        </div>
      </div>

      {/* imbalance bar */}
      <div style={{ marginTop: 12 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 10, marginBottom: 4 }}>
          <span style={{ color: 'var(--bn-fg-mute)' }}>仓位</span>
          <span className="bn-num" style={{ color: 'var(--bn-fg-dim)' }}>
            实际 <span style={{ color: 'var(--bn-fg)', fontWeight: 600 }}>{(actual * 100).toFixed(1)}%</span>
            <span style={{ color: 'var(--bn-fg-faint)', margin: '0 4px' }}>/</span>
            目标 {(target * 100).toFixed(0)}%
          </span>
        </div>
        {/* Stacked bar with target marker */}
        <div style={{ position: 'relative', height: 4, background: 'rgba(255,255,255,0.05)', borderRadius: 2 }}>
          <div style={{ position: 'absolute', left: 0, top: 0, bottom: 0, width: `${actual * 100}%`, background: Math.abs(delta) > 0.03 ? 'var(--bn-accent)' : 'var(--bn-fg-dim)', borderRadius: 2 }}/>
          <div style={{ position: 'absolute', left: `${target * 100}%`, top: -2, width: 1, height: 8, background: 'var(--bn-fg)', borderRadius: 1 }}/>
        </div>
        {Math.abs(delta) > 0.02 && (
          <div className="bn-num" style={{ fontSize: 9.5, color: delta > 0 ? 'var(--bn-accent)' : 'var(--bn-benchmark)', marginTop: 4, fontWeight: 500 }}>
            {delta > 0 ? '超配' : '低配'} {(Math.abs(delta) * 100).toFixed(1)}pp
          </div>
        )}
      </div>
    </div>
  );
}

function HoldingsList({ invert }) {
  return (
    <div style={{ padding: '16px 16px 100px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
        <div style={{ fontSize: 12, color: 'var(--bn-fg-dim)', fontWeight: 600 }}>持仓基金 · {HOLDINGS.length}</div>
        <div className="bn-seg">
          <button className="on">按市值</button>
          <button>按收益</button>
          <button>按失衡</button>
        </div>
      </div>
      {HOLDINGS.map((h, i) => <HoldingCard key={h.code} h={h} invert={invert} seed={1000 + i * 77}/>)}
    </div>
  );
}

// ── Page root ────────────────────────────────────────────────
function HoldingsScreen({ onSettings, invert = false, fillMode = 'soft' }) {
  return (
    <div className="bn-root" style={{ width: '100%', height: '100%', background: 'var(--bn-bg)', overflow: 'auto' }}>
      <div style={{ paddingTop: 8 }}>
        <TotalHeader onSettings={onSettings} invert={invert}/>
        <OverviewPanel invert={invert}/>
        <NavCard invert={invert} fillMode={fillMode}/>
        <RadarCard/>
        <HoldingsList invert={invert}/>
      </div>
    </div>
  );
}

Object.assign(window, { HoldingsScreen, HoldingCard, OverviewPanel, NavCard, RadarCard, TotalHeader });

})();
