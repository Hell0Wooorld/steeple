import { NavLink, Outlet } from 'react-router-dom'
import { Logo } from './Logo'

const links = [
  { to: '/', label: '홈', end: true },
  { to: '/explore', label: '교회 찾기' },
  { to: '/denominations', label: '교단 안내' },
  { to: '/heresy', label: '이단 바로 알기' },
]

export function Layout() {
  return (
    <div className="app">
      <header className="site-header">
        <NavLink to="/" className="brand" aria-label="스티플 홈">
          <Logo size={34} />
        </NavLink>
        <nav className="main-nav" aria-label="주요 메뉴">
          {links.map((l) => (
            <NavLink key={l.to} to={l.to} end={l.end} className={({ isActive }) => (isActive ? 'active' : '')}>
              {l.label}
            </NavLink>
          ))}
        </nav>
      </header>
      <main>
        <Outlet />
      </main>
      <footer className="site-footer">
        <p>
          현재 화면의 교회 정보는 <strong>가상의 예시 데이터</strong>입니다. 실제 교회와 무관합니다.
        </p>
        <p className="muted">© Steeple · 지도 © OpenStreetMap contributors</p>
      </footer>
    </div>
  )
}
