(function(){
// Backtester Note — Backtest (回测) screen
const { LineChart, Icon, fmt, pnlColor, FUNDS, PORTFOLIOS, BACKTESTS, makeSeries } = window;

function Segmented({ options, value, onChange }) {
  return (
    <div className="bn-seg" style={{ width: '100%', display: 'flex' }}>
      {options.map(([k, l]) => (
        <button key={k} className={value === k ? 'on' : ''} onClick={() => onChange(k)} style={{ flex: 1 }}>{l}</button>
      ))}
    </div>
  );
}

function Field({ label, value, sub, onClick, rightArrow = true }) {
  return (
    <button onClick={onClick} style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      width: '100%', padding: '12px 14px',
      background: 'var(--bn-surface)', border: '0.5px solid var(--bn-border)',
      borderRadius: 12, color: 'var(--bn-fg)', cursor: onClick ? 'pointer' : 'default',
      textAlign: 'left', fontFamily: 'inherit',
    }}>
      <div>
        <div style={{ fontSize: 10.5, color: 'var(--bn-fg-mute)', fontWeight: 500, marginBottom: 2 }}>{label}</div>
        <div style={{ fontSize: 14, fontWeight: 600 }}>{value}</div>
        {sub && <div className="bn-num" style={{ fontSize: 10.5, color: 'var(--bn-fg-dim)', marginTop: 2 }}>{sub}</div>}
      </div>
      {rightArrow && <span style={{ color: 'var(--bn-fg-mute)' }}><Icon.Chevron/></span>}
    </button>
  );
}

function ResultMetric({ label, value, color }) {
  return (
    <div style={{ flex: 1, padding: '10px 8px', textAlign: 'center' }}>
      <div style={{ fontSize: 10, color: 'var(--bn-fg-mute)', fontWeight: 500, marginBottom: 3 }}>{label}</div>
      <div className="bn-num" style={{ fontSize: 15, fontWeight: 600, color: color || 'var(--bn-fg)' }}>{value}</div>
    </div>
  );
}

function BacktestTabBar({ value, onChange }) {
  const tabs = [['single', '单基金'], ['portfolio', '组合'], ['sip', '定投'], ['history', '历史']];
  return (
    <div style={{ padding: '10px 16px 0' }}>
      <Segmented options={tabs} value={value} onChange={onChange}/>
    </div>
  );
}

// Single-fund / Portfolio / SIP config
function ConfigCard({ mode, invert }) {
  const [selectedPortfolio, setSelectedPortfolio] = React.useState('p1');
  const [selectedFund, setSelectedFund] = React.useState('510300');
  const [start, setStart] = React.useState('2020-01-01');
  const [end, setEnd] = React.useState('2025-12-31');
  const [freq, setFreq] = React.useState('weekly');
  const [dow, setDow] = React.useState('周一');
  const [firstAmt, setFirstAmt] = React.useState(5000);
  const [periodAmt, setPeriodAmt] = React.useState(1000);
  const [rebalance, setRebalance] = React.useState(true);
  const [threshold, setThreshold] = React.useState(5);

  const fund = FUNDS.find(f => f.code === selectedFund);
  const pf = PORTFOLIOS.find(p => p.id === selectedPortfolio);

  return (
    <div style={{ padding: '14px 16px 0', display: 'flex', flexDirection: 'column', gap: 10 }}>
      {mode === 'single' && (
        <Field label="标的基金" value={fund.name} sub={`${fund.code} · ${fund.type}`}/>
      )}
      {(mode === 'portfolio' || (mode === 'sip')) && (
        <>
          <div>
            <div className="bn-label" style={{ marginBottom: 6 }}>组合 · 来自收藏</div>
            <div style={{ display: 'flex', gap: 8, overflowX: 'auto' }} className="bn-scroll">
              {PORTFOLIOS.map(p => {
                const on = p.id === selectedPortfolio;
                return (
                  <button key={p.id} onClick={() => setSelectedPortfolio(p.id)} style={{
                    minWidth: 150, padding: '10px 12px',
                    background: on ? 'rgba(227,177,92,0.08)' : 'var(--bn-surface)',
                    border: on ? '0.5px solid var(--bn-accent)' : '0.5px solid var(--bn-border)',
                    borderRadius: 12, color: 'var(--bn-fg)', cursor: 'pointer', textAlign: 'left',
                    fontFamily: 'inherit', flexShrink: 0,
                  }}>
                    <div style={{ fontSize: 13, fontWeight: 600 }}>{p.name}</div>
                    <div className="bn-num" style={{ fontSize: 10.5, color: 'var(--bn-fg-dim)', marginTop: 2 }}>
                      {p.funds.length} 只 · {p.weights.map(w => (w*100).toFixed(0)).join('/')}%
                    </div>
                    <div style={{ fontSize: 9.5, color: 'var(--bn-fg-mute)', marginTop: 3, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{p.note}</div>
                  </button>
                );
              })}
            </div>
          </div>
          {pf && (
            <div style={{ background: 'var(--bn-surface)', border: '0.5px solid var(--bn-border)', borderRadius: 12, padding: '10px 12px' }}>
              <div style={{ fontSize: 10.5, color: 'var(--bn-fg-mute)', fontWeight: 500, marginBottom: 6 }}>组合构成</div>
              {pf.funds.map((c, i) => {
                const f = FUNDS.find(x => x.code === c);
                return (
                  <div key={c} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '4px 0' }}>
                    <span style={{ fontSize: 12, color: 'var(--bn-fg)' }}>{f.name}</span>
                    <span className="bn-num" style={{ fontSize: 12, color: 'var(--bn-fg-dim)' }}>{(pf.weights[i] * 100).toFixed(0)}%</span>
                  </div>
                );
              })}
            </div>
          )}
        </>
      )}

      <div className="bn-label" style={{ marginTop: 6 }}>回测区间</div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
        <Field label="起始" value={start} rightArrow={false}/>
        <Field label="截止" value={end} rightArrow={false}/>
      </div>
      <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
        {['1Y','3Y','5Y','成立起'].map(q => (
          <button key={q} className="bn-btn" style={{ padding: '5px 10px', fontSize: 11 }}>{q}</button>
        ))}
      </div>

      {mode !== 'single' && (
        <>
          <div className="bn-label" style={{ marginTop: 6 }}>定投规则</div>
          <div style={{ background: 'var(--bn-surface)', border: '0.5px solid var(--bn-border)', borderRadius: 12, padding: 12 }}>
            <div className="bn-seg" style={{ width: '100%', display: 'flex', marginBottom: 10 }}>
              {[['weekly','周定投'],['biweekly','双周'],['monthly','月定投']].map(([k,l]) => (
                <button key={k} className={freq === k ? 'on' : ''} onClick={() => setFreq(k)} style={{ flex: 1 }}>{l}</button>
              ))}
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8, marginBottom: 10 }}>
              <div>
                <div style={{ fontSize: 10.5, color: 'var(--bn-fg-mute)', marginBottom: 4 }}>扣款日</div>
                <div className="bn-num" style={{ fontSize: 13, fontWeight: 600, color: 'var(--bn-fg)' }}>{freq === 'monthly' ? '每月 15 日' : dow}</div>
              </div>
              <div>
                <div style={{ fontSize: 10.5, color: 'var(--bn-fg-mute)', marginBottom: 4 }}>首笔 / 每期</div>
                <div className="bn-num" style={{ fontSize: 13, fontWeight: 600, color: 'var(--bn-fg)' }}>¥{firstAmt.toLocaleString()} / ¥{periodAmt.toLocaleString()}</div>
              </div>
            </div>
            {mode === 'portfolio' && (
              <>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 0', borderTop: '0.5px solid var(--bn-border)' }}>
                  <div style={{ fontSize: 12, color: 'var(--bn-fg)' }}>启用再平衡</div>
                  <button onClick={() => setRebalance(!rebalance)} style={{
                    width: 42, height: 24, borderRadius: 14, border: 'none', cursor: 'pointer',
                    background: rebalance ? 'var(--bn-up)' : 'rgba(255,255,255,0.15)', position: 'relative', transition: 'background .2s',
                  }}>
                    <span style={{ position: 'absolute', top: 2, left: rebalance ? 20 : 2, width: 20, height: 20, borderRadius: 10, background: '#fff', transition: 'left .2s' }}/>
                  </button>
                </div>
                {rebalance && (
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', fontSize: 11.5, color: 'var(--bn-fg-dim)', paddingTop: 4 }}>
                    <span>偏离阈值</span>
                    <span className="bn-num" style={{ fontWeight: 600, color: 'var(--bn-fg)' }}>{threshold}%</span>
                  </div>
                )}
              </>
            )}
          </div>
        </>
      )}

      <button className="bn-btn primary" style={{ marginTop: 6, padding: '12px', fontSize: 14 }}>
        开始回测
      </button>
    </div>
  );
}

// Result preview (always-visible last-run)
function ResultPreview({ invert, fillMode }) {
  const series = React.useMemo(() => makeSeries(240, 8899, 0, 0.009, 0.0012), []);
  const bench  = React.useMemo(() => makeSeries(240, 4422, 0, 0.009, 0.0007), []);
  const last = series[series.length - 1].v;
  const lastB = bench[bench.length - 1].v;
  const excess = last - lastB;

  return (
    <div className="bn-glass" style={{ margin: '14px 16px 0', borderRadius: 18, padding: '14px 0 10px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', padding: '0 16px 8px' }}>
        <div>
          <div style={{ fontSize: 11, color: 'var(--bn-fg-mute)', fontWeight: 600, letterSpacing: '0.06em', textTransform: 'uppercase' }}>上次回测</div>
          <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--bn-fg)', marginTop: 2 }}>核心-卫星 · 月定投</div>
        </div>
        <div style={{ textAlign: 'right' }}>
          <div className="bn-num" style={{ fontSize: 16, fontWeight: 600, color: pnlColor(last, invert) }}>
            {last >= 0 ? '+' : ''}{last.toFixed(2)}%
          </div>
          <div className="bn-num" style={{ fontSize: 10.5, color: 'var(--bn-fg-mute)' }}>2020 · 01 → 2025 · 12</div>
        </div>
      </div>
      <div style={{ padding: '0 8px' }}>
        <LineChart series={series} benchmark={bench} width={358} height={120} padX={8} color={last >= 0 ? (invert ? '#2EBD85' : '#F6465D') : (invert ? '#F6465D' : '#2EBD85')} showFill={fillMode !== 'none'}/>
      </div>
      <div style={{ display: 'flex', padding: '8px 6px 0', borderTop: '0.5px solid var(--bn-border)', marginTop: 6 }}>
        <ResultMetric label="CAGR" value="+11.8%" color={pnlColor(11.8, invert)}/>
        <ResultMetric label="XIRR" value="+12.1%" color={pnlColor(12.1, invert)}/>
        <ResultMetric label="最大回撤" value="-18.2%" color="var(--bn-fg-dim)"/>
        <ResultMetric label="夏普" value="1.23"/>
        <ResultMetric label="超额" value={fmt.pct(excess)} color={pnlColor(excess, invert)}/>
      </div>
    </div>
  );
}

function HistoryList({ invert }) {
  return (
    <div style={{ padding: '14px 16px 100px', display: 'flex', flexDirection: 'column', gap: 8 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div style={{ fontSize: 12, color: 'var(--bn-fg-dim)', fontWeight: 600 }}>历史回测 · {BACKTESTS.length}</div>
        <button className="bn-btn" style={{ padding: '5px 10px', fontSize: 11 }}>对比</button>
      </div>
      {BACKTESTS.map(b => {
        const seed = b.id.charCodeAt(1) * 97;
        const series = makeSeries(80, seed, 0, 0.009, b.cagr * 0.0001);
        const color = b.cagr >= 0 ? (invert ? '#2EBD85' : '#F6465D') : (invert ? '#F6465D' : '#2EBD85');
        const typeLabel = { portfolio: '组合', sip: '定投', single: '单基' }[b.type];
        return (
          <div key={b.id} style={{
            padding: 12, borderRadius: 12,
            background: 'var(--bn-surface)', border: '0.5px solid var(--bn-border)',
            display: 'grid', gridTemplateColumns: '1fr auto', gap: 10,
          }}>
            <div style={{ minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 3 }}>
                <span className="bn-chip bn-chip-neutral">{typeLabel}</span>
                <span style={{ fontSize: 9.5, color: 'var(--bn-fg-mute)' }}>{b.savedAt}</span>
              </div>
              <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--bn-fg)', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{b.name}</div>
              <div className="bn-num" style={{ fontSize: 10.5, color: 'var(--bn-fg-mute)', marginTop: 2 }}>{b.period}</div>
              <div style={{ display: 'flex', gap: 12, marginTop: 8 }}>
                <div>
                  <div style={{ fontSize: 9, color: 'var(--bn-fg-mute)' }}>CAGR</div>
                  <div className="bn-num" style={{ fontSize: 12, fontWeight: 600, color: pnlColor(b.cagr, invert) }}>{fmt.pct(b.cagr, 1)}</div>
                </div>
                <div>
                  <div style={{ fontSize: 9, color: 'var(--bn-fg-mute)' }}>最大回撤</div>
                  <div className="bn-num" style={{ fontSize: 12, fontWeight: 600, color: 'var(--bn-fg-dim)' }}>{b.maxdd.toFixed(1)}%</div>
                </div>
                <div>
                  <div style={{ fontSize: 9, color: 'var(--bn-fg-mute)' }}>夏普</div>
                  <div className="bn-num" style={{ fontSize: 12, fontWeight: 600, color: 'var(--bn-fg)' }}>{b.sharpe.toFixed(2)}</div>
                </div>
              </div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center' }}>
              <LineChart series={series} width={80} height={48} padX={2} padY={4} color={color} showGrid={false} showFill={true}/>
            </div>
          </div>
        );
      })}
    </div>
  );
}

function BacktestScreen({ invert = false, fillMode = 'soft' }) {
  const [mode, setMode] = React.useState('portfolio');
  return (
    <div className="bn-root" style={{ width: '100%', height: '100%', background: 'var(--bn-bg)', overflow: 'auto' }}>
      <div style={{ padding: '14px 20px 4px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <div className="bn-label">Backtest</div>
          <div className="bn-h1" style={{ fontSize: 26, marginTop: 2 }}>回测</div>
        </div>
        <button className="bn-btn" style={{ padding: '6px 10px', fontSize: 11, display: 'flex', alignItems: 'center', gap: 4 }}>
          <Icon.Plus size={12}/> 新建
        </button>
      </div>
      <BacktestTabBar value={mode} onChange={setMode}/>
      {mode === 'history'
        ? <HistoryList invert={invert}/>
        : <>
            <ConfigCard mode={mode} invert={invert}/>
            <ResultPreview invert={invert} fillMode={fillMode}/>
            <div style={{ height: 100 }}/>
          </>
      }
    </div>
  );
}

Object.assign(window, { BacktestScreen, BacktestTabBar, ConfigCard, ResultPreview, HistoryList });

})();
