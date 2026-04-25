(function(){
// Backtester Note — Tab bar + Settings overlay + Today/Widgets stubs
const { Icon } = window;

function TabBar({ value, onChange }) {
  const tabs = [
    { k: 'today',    l: '今日', Ico: Icon.Home },
    { k: 'holdings', l: '持仓', Ico: Icon.Wallet },
    { k: 'backtest', l: '回测', Ico: Icon.Beaker },
    { k: 'widgets',  l: '组件', Ico: Icon.Grid },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 18, left: 16, right: 16,
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '6px 6px', borderRadius: 22,
    }} className="bn-tabbar">
      {tabs.map(t => {
        const on = value === t.k;
        return (
          <button key={t.k} onClick={() => onChange(t.k)} style={{
            flex: 1, background: 'transparent', border: 'none', cursor: 'pointer',
            padding: '8px 4px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            color: on ? 'var(--bn-fg)' : 'var(--bn-fg-mute)',
            borderRadius: 16, transition: 'color .15s',
          }}>
            <t.Ico size={20} filled={on}/>
            <span style={{ fontSize: 10, fontWeight: on ? 600 : 500 }}>{t.l}</span>
          </button>
        );
      })}
    </div>
  );
}

// ── Settings overlay (sheet) ─────────────────────────────────
function SettingsSheet({ open, onClose }) {
  if (!open) return null;
  const Row = ({ label, value, rightEl }) => (
    <div style={{
      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
      padding: '13px 16px', borderBottom: '0.5px solid var(--bn-border)',
    }}>
      <span style={{ fontSize: 13.5, color: 'var(--bn-fg)' }}>{label}</span>
      {rightEl || <span style={{ fontSize: 12.5, color: 'var(--bn-fg-dim)', display: 'flex', alignItems: 'center', gap: 4 }}>
        {value} <Icon.Chevron size={12}/>
      </span>}
    </div>
  );
  const Section = ({ title, children }) => (
    <div style={{ marginBottom: 18 }}>
      <div className="bn-label" style={{ padding: '0 16px 6px', fontSize: 10 }}>{title}</div>
      <div style={{ background: 'var(--bn-surface)', border: '0.5px solid var(--bn-border)', borderRadius: 12, overflow: 'hidden', margin: '0 12px' }}>
        {children}
      </div>
    </div>
  );

  return (
    <div onClick={onClose} style={{
      position: 'absolute', inset: 0, zIndex: 50,
      background: 'rgba(0,0,0,0.5)', backdropFilter: 'blur(8px)',
      display: 'flex', alignItems: 'flex-end',
    }}>
      <div onClick={e => e.stopPropagation()} style={{
        width: '100%', maxHeight: '86%',
        background: 'var(--bn-bg-elev)',
        borderTopLeftRadius: 26, borderTopRightRadius: 26,
        borderTop: '0.5px solid var(--bn-border-strong)',
        paddingBottom: 40, overflow: 'auto',
        animation: 'slideUp .25s cubic-bezier(.2,.8,.25,1)',
      }} className="bn-root bn-scroll">
        <div style={{ display: 'flex', justifyContent: 'center', padding: '8px 0 0' }}>
          <div style={{ width: 36, height: 4, background: 'var(--bn-fg-faint)', borderRadius: 2 }}/>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '10px 18px 14px' }}>
          <div className="bn-h2">设置</div>
          <button onClick={onClose} style={{ background: 'transparent', border: 'none', color: 'var(--bn-fg-dim)', cursor: 'pointer' }}>
            <Icon.Close/>
          </button>
        </div>

        <Section title="账户">
          <Row label="主账户" value="elvis · 默认"/>
          <Row label="Pro 订阅" value="已激活" rightEl={<span className="bn-chip" style={{ background: 'var(--bn-accent-dim)', color: 'var(--bn-accent)' }}>PRO</span>}/>
          <Row label="家庭共享" value="关闭"/>
        </Section>

        <Section title="数据维护">
          <Row label="官方净值更新" value="今天 15:32" rightEl={<span style={{ color: 'var(--bn-down)', fontSize: 12, display:'flex', alignItems:'center', gap: 4 }}><Icon.Refresh size={12}/> 刷新</span>}/>
          <Row label="盘中估值" value="自动 · 每 60s"/>
          <Row label="快捷指令导入" value="3 个模板"/>
          <Row label="交易流水对账" value="待核对 2 条" rightEl={<span className="bn-chip" style={{ background: 'var(--bn-accent-dim)', color: 'var(--bn-accent)' }}>2</span>}/>
        </Section>

        <Section title="缓存">
          <Row label="本地缓存" value="128.4 MB"/>
          <Row label="历史净值窗口" value="5 年"/>
          <Row label="清除估值缓存"/>
        </Section>

        <Section title="关于">
          <Row label="版本" value="v0.4.2 (dev)"/>
          <Row label="调试日志"/>
          <Row label="重置全部数据"/>
        </Section>
      </div>
      <style>{`@keyframes slideUp { from { transform: translateY(24px); opacity: 0 } to { transform: none; opacity: 1 } }`}</style>
    </div>
  );
}

// ── Today screen (minimal stub — dashboard header) ─────────
function TodayScreen({ invert }) {
  const { OVERVIEW, fmt, pnlColor, LineChart, NAV_SERIES, RADAR } = window;
  const data = NAV_SERIES['1M'];
  const last = data.account[data.account.length - 1].v;
  const upColor = pnlColor(OVERVIEW.dayPnl, invert);
  return (
    <div className="bn-root" style={{ width: '100%', height: '100%', background: 'var(--bn-bg)', overflow: 'auto' }}>
      <div style={{ padding: '14px 20px 0' }}>
        <div className="bn-label">Today · 04 · 24</div>
        <div className="bn-h1" style={{ marginTop: 2 }}>今日</div>
      </div>

      <div className="bn-glass" style={{ margin: '14px 16px 0', padding: 16, borderRadius: 18 }}>
        <div style={{ fontSize: 10.5, color: 'var(--bn-fg-mute)', fontWeight: 600 }}>今日预估</div>
        <div className="bn-num" style={{ fontSize: 30, fontWeight: 600, color: upColor, marginTop: 4 }}>
          {fmt.signed(OVERVIEW.dayPnl)}
        </div>
        <div className="bn-num" style={{ fontSize: 12, color: 'var(--bn-fg-dim)', marginTop: 2 }}>
          {fmt.pct(OVERVIEW.dayPct)} · 总市值 ¥{fmt.money(OVERVIEW.totalValue)}
        </div>
        <div style={{ marginTop: 10, marginLeft: -8, marginRight: -8 }}>
          <LineChart series={data.account} width={342} height={80} padX={8} padY={6} color={upColor === 'var(--bn-up)' ? '#F6465D' : '#2EBD85'} showGrid={false}/>
        </div>
      </div>

      <div className="bn-glass" style={{ margin: '12px 16px 0', padding: 14, borderRadius: 18 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8 }}>
          <div style={{ fontSize: 12, color: 'var(--bn-fg-dim)', fontWeight: 600 }}>趋势雷达</div>
          <span className="bn-num" style={{ fontSize: 12, color: 'var(--bn-up)', fontWeight: 600 }}>{RADAR.scores.current.toFixed(1)} ↑</span>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8 }}>
          {RADAR.dims.map((d, i) => (
            <div key={d} style={{ padding: '8px 10px', background: 'var(--bn-surface)', borderRadius: 10, border: '0.5px solid var(--bn-border)' }}>
              <div style={{ fontSize: 9.5, color: 'var(--bn-fg-mute)' }}>{d}</div>
              <div className="bn-num" style={{ fontSize: 14, fontWeight: 600, color: 'var(--bn-fg)' }}>{RADAR.current[i]}</div>
            </div>
          ))}
        </div>
      </div>

      <div className="bn-glass" style={{ margin: '12px 16px 0', padding: 14, borderRadius: 18 }}>
        <div style={{ fontSize: 12, color: 'var(--bn-fg-dim)', fontWeight: 600, marginBottom: 8 }}>异常提醒 · 2</div>
        {[
          { t: '中证1000ETF 低配 4.0pp', s: '建议补仓 ¥3,200' },
          { t: '核心-卫星 组合漂移 5.8%', s: '已超再平衡阈值' },
        ].map((a, i) => (
          <div key={i} style={{ padding: '8px 0', borderTop: i ? '0.5px solid var(--bn-border)' : 'none', display: 'flex', justifyContent: 'space-between' }}>
            <div>
              <div style={{ fontSize: 12.5, color: 'var(--bn-fg)', fontWeight: 500 }}>{a.t}</div>
              <div style={{ fontSize: 10.5, color: 'var(--bn-fg-mute)' }}>{a.s}</div>
            </div>
            <Icon.Chevron/>
          </div>
        ))}
      </div>
      <div style={{ height: 120 }}/>
    </div>
  );
}

// ── Widgets screen (stub) ────────────────────────────────────
function WidgetsScreen() {
  const { Sparkline, makeSeries, OVERVIEW, RADAR, fmt } = window;
  const ws = makeSeries(20, 111, 0, 0.01, 0.001);

  const Widget = ({ title, children, size = 'sm' }) => (
    <div style={{
      background: 'var(--bn-surface)', border: '0.5px solid var(--bn-border)',
      borderRadius: 18, padding: 14,
      gridColumn: size === 'lg' ? 'span 2' : 'span 1',
      minHeight: 140,
    }}>
      <div style={{ fontSize: 10, color: 'var(--bn-fg-mute)', fontWeight: 600, letterSpacing: '0.06em', marginBottom: 8 }}>{title}</div>
      {children}
    </div>
  );

  return (
    <div className="bn-root" style={{ width: '100%', height: '100%', background: 'var(--bn-bg)', overflow: 'auto' }}>
      <div style={{ padding: '14px 20px 6px' }}>
        <div className="bn-label">Widgets</div>
        <div className="bn-h1" style={{ marginTop: 2 }}>组件</div>
        <div style={{ fontSize: 12, color: 'var(--bn-fg-dim)', marginTop: 4 }}>最近同步 · 04-24 15:32 · 5/5 成功</div>
      </div>
      <div style={{ padding: '10px 16px 140px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        <Widget title="今日收益">
          <div className="bn-num" style={{ fontSize: 20, fontWeight: 600, color: 'var(--bn-up)' }}>+¥1,284</div>
          <div className="bn-num" style={{ fontSize: 10, color: 'var(--bn-fg-dim)', marginTop: 2 }}>+0.85%</div>
          <div style={{ marginTop: 8 }}><Sparkline series={ws} width={110} height={28} color="#F6465D"/></div>
        </Widget>
        <Widget title="雷达总分">
          <div className="bn-num" style={{ fontSize: 28, fontWeight: 600, color: 'var(--bn-fg)' }}>{RADAR.scores.current.toFixed(0)}</div>
          <div style={{ fontSize: 10.5, color: 'var(--bn-up)', fontWeight: 600, marginTop: 2 }}>↑ 2.2 vs 上周</div>
          <div style={{ marginTop: 8, fontSize: 10, color: 'var(--bn-fg-mute)' }}>6 维度健康</div>
        </Widget>
        <Widget title="净值曲线 · 30D" size="lg">
          <div className="bn-num" style={{ fontSize: 16, fontWeight: 600, color: 'var(--bn-fg)' }}>¥{fmt.money(OVERVIEW.totalValue)}</div>
          <div style={{ marginTop: 10, marginLeft: -4 }}>
            <Sparkline series={ws} width={280} height={50} color="#F6465D"/>
          </div>
        </Widget>
        <Widget title="定投提醒">
          <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--bn-fg)' }}>周一 09:30</div>
          <div className="bn-num" style={{ fontSize: 11, color: 'var(--bn-fg-dim)', marginTop: 2 }}>沪深300 · ¥1,000</div>
          <div style={{ marginTop: 16, display: 'flex', alignItems: 'center', gap: 6 }}>
            <span style={{ width: 6, height: 6, borderRadius: 3, background: 'var(--bn-accent)' }}/>
            <span style={{ fontSize: 10, color: 'var(--bn-fg-mute)' }}>3 天后</span>
          </div>
        </Widget>
        <Widget title="异常提醒">
          <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--bn-fg)' }}>2 条待处理</div>
          <div style={{ marginTop: 6, fontSize: 10.5, color: 'var(--bn-fg-mute)', lineHeight: 1.5 }}>
            · 中证1000 低配<br/>· 核心-卫星 漂移
          </div>
        </Widget>
      </div>
    </div>
  );
}

Object.assign(window, { TabBar, SettingsSheet, TodayScreen, WidgetsScreen });

})();
