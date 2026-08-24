import Image from "next/image";

const installCommand = "brew install --cask takeshita-0x0201/tap/room";
const releaseUrl = "https://github.com/takeshita-0x0201/room/releases";
const repoUrl = "https://github.com/takeshita-0x0201/room";

function RoomMark({ className = "" }: { className?: string }) {
  return (
    <span className={`room-mark ${className}`} aria-hidden="true">
      <i className="room-back" /><i className="room-left" /><i className="room-right" />
      <i className="room-floor-left" /><i className="room-floor-right" />
    </span>
  );
}

function MemoryIcon() {
  return <span className="memory-icon" aria-hidden="true"><i /></span>;
}

function StorageIcon() {
  return <span className="storage-icon" aria-hidden="true"><i /></span>;
}

function MenuPreview() {
  return (
    <div className="product-stage" aria-label="Room menu bar app preview">
      <div className="ambient-orbit orbit-one" /><div className="ambient-orbit orbit-two" />
      <div className="menubar-chip">
        <span><MemoryIcon /><b>72</b></span><span><StorageIcon /><b>68</b></span>
      </div>
      <div className="popover">
        <div className="popover-notch" />
        <div className="popover-head">
          <span className="popover-brand"><RoomMark /> Room</span><span className="gear" aria-hidden="true">⌘</span>
        </div>
        <section className="metric memory-metric">
          <div className="metric-title"><span><MemoryIcon />Memory</span><b>72%</b></div>
          <div className="bar"><i /></div><p className="metric-amount"><strong>18.4</strong> / 24 GB</p>
          <div className="metric-stats"><span>Pressure <b><i className="status-dot" />Normal</b></span><span>Swap <b>768 MB</b></span></div>
        </section>
        <section className="metric storage-metric">
          <div className="metric-title"><span><StorageIcon />Storage</span><b>68%</b></div>
          <div className="bar"><i /></div><p className="metric-amount"><strong>341</strong> / 512 GB</p>
          <div className="metric-stats"><span>Free <b>171 GB</b></span></div>
        </section>
        <section className="processes">
          <p className="section-label">Top Processes</p>
          <div><span>Chrome</span><b>3.2 GB</b></div><div><span>Cursor</span><b>2.4 GB</b></div><div><span>node</span><b>1.1 GB</b></div>
        </section>
        <div className="popover-actions"><span><RoomMark />Make Room</span><span>Processes <b>›</b></span></div>
      </div>
    </div>
  );
}

export default function Home() {
  return (
    <main>
      <nav className="nav wrap" aria-label="Main navigation">
        <a className="brand" href="#top" aria-label="Room home"><Image src="/room-app-icon.png" width={38} height={38} alt="" priority /><span>Room</span></a>
        <div className="nav-links"><a href="#features">Features</a><a href="#safety">Safety</a><a href={repoUrl}>GitHub</a></div>
        <a className="nav-cta" href={releaseUrl}>Download <span>↘</span></a>
      </nav>

      <section className="hero wrap" id="top">
        <div className="hero-copy">
          <div className="eyebrow"><span className="pulse" />Built for macOS · Open source</div>
          <h1>Know what’s full.<br /><em>Make room.</em></h1>
          <p className="hero-lede">A tiny menu bar app that shows when memory is <i>actually</i> tight and helps you safely clear space—only when you ask.</p>
          <div className="hero-actions"><a className="button primary" href={releaseUrl}>Download for macOS <span>↓</span></a><a className="button secondary" href={repoUrl}>View on GitHub <span>↗</span></a></div>
          <div className="hero-meta"><span>macOS 14+</span><i /><span>Apple Silicon + Intel</span><i /><span>MIT licensed</span></div>
        </div>
        <MenuPreview />
      </section>

      <section className="manifesto wrap">
        <p className="kicker">Quiet by design</p>
        <h2>Your Mac already manages memory.<br />Room helps you <em>understand it.</em></h2>
        <p>High RAM use isn’t automatically bad. Room reads macOS Memory Pressure—the signal that tells you whether your Mac genuinely needs breathing room.</p>
      </section>

      <section className="features wrap" id="features">
        <article className="feature feature-glance">
          <div className="feature-copy"><span className="index">01</span><h3>One glance.<br />That’s the point.</h3><p>Memory and storage stay visible in your menu bar, without a dashboard competing for your attention.</p></div>
          <div className="glance-visual"><div className="screen-top"><span>9:41</span><i /><i /><i /></div><div className="floating-chip"><MemoryIcon /><b>72</b><StorageIcon /><b>68</b></div><p>No labels. No graphs.<br />Just the numbers you need.</p></div>
        </article>
        <article className="feature feature-pressure">
          <div className="feature-copy"><span className="index">02</span><h3>Pressure,<br />not panic.</h3><p>Room separates “using memory” from “running out of memory,” so a healthy 90% doesn’t become a warning.</p></div>
          <div className="pressure-visual"><div className="pressure-reading"><strong>90%</strong><span>RAM used</span></div><div className="pressure-divider" /><div className="pressure-state"><span><i />Normal</span><b>No action needed</b></div></div>
        </article>
        <article className="feature feature-clean">
          <div className="feature-copy"><span className="index">03</span><h3>Clean up,<br />with a safety net.</h3><p>Find regenerable caches, logs, and developer files. Review every item before anything is removed.</p></div>
          <div className="review-card"><div className="review-head"><span>Make Room</span><b>Review</b></div><div className="review-row"><i className="check" /><span>Application Caches</span><b>8.4 GB</b></div><div className="review-row"><i className="check" /><span>Developer</span><b>6.2 GB</b></div><div className="review-row off"><i className="check" /><span>Old Logs</span><b>420 MB</b></div><div className="review-total"><span>Selected</span><strong>14.6 GB</strong></div></div>
        </article>
      </section>

      <section className="safety" id="safety"><div className="wrap safety-grid">
        <div className="safety-title"><RoomMark className="large-mark" /><p className="kicker">Safety is the feature</p><h2>Nothing happens<br />behind your back.</h2></div>
        <div className="principles"><article><span>01</span><div><h3>Review before removal</h3><p>Every cleanup runs through one confirmation flow with per-item controls.</p></div></article><article><span>02</span><div><h3>Protected by default</h3><p>System-critical processes can’t be quit. Running app caches are skipped.</p></div></article><article><span>03</span><div><h3>Completely local</h3><p>No account, analytics, telemetry, network requests, or auto-update service.</p></div></article></div>
      </div></section>

      <section className="install wrap" id="download">
        <div><p className="kicker">Make some room</p><h2>A lighter Mac<br />starts up here.</h2></div>
        <div className="install-box"><a className="button primary" href={releaseUrl}>Download Room <span>↓</span></a><div className="command" aria-label={`Terminal command: ${installCommand}`}><code>{installCommand}</code><span aria-hidden="true">⌘C</span></div><p>Free and open source. Built with SwiftUI.<br />Requires macOS Sonoma or later.</p></div>
      </section>

      <footer className="footer wrap"><a className="brand" href="#top"><Image src="/room-app-icon.png" width={34} height={34} alt="" /><span>Room</span></a><p>See what’s full. Make room.</p><div><a href={repoUrl}>GitHub ↗</a><a href={`${repoUrl}/blob/main/LICENSE`}>MIT License</a></div></footer>
    </main>
  );
}
