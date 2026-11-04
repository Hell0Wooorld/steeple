import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { LogoMark } from '../components/Logo'
import { churches, districts } from '../lib/data'

export function Home() {
  const [q, setQ] = useState('')
  const navigate = useNavigate()

  const search = (e: React.FormEvent) => {
    e.preventDefault()
    navigate(`/explore?q=${encodeURIComponent(q.trim())}`)
  }

  return (
    <div className="home">
      <section className="hero">
        <LogoMark size={64} />
        <h1>
          방황하는 발걸음에,
          <br />
          건강한 교회로 가는 이정표
        </h1>
        <p className="hero-sub">
          이사 오셨나요? 교회를 처음 찾으시나요? 교회를 옮기려 하시나요?
          <br />
          멀리서도 보이는 첨탑처럼, 스티플이 가까운 교회를 안내해 드립니다.
        </p>

        <form className="search" onSubmit={search} role="search">
          <input
            type="search"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="동네 또는 교회 이름 (예: 화명동)"
            aria-label="교회 검색"
          />
          <button type="submit" className="btn btn-primary">
            검색
          </button>
        </form>

        <div className="hero-actions">
          <Link className="btn btn-accent" to="/explore?nearby=1">
            📍 내 주변 교회 찾기
          </Link>
          <Link className="btn btn-ghost" to="/explore">
            지도에서 보기
          </Link>
        </div>
      </section>

      <section className="section">
        <h2>지역으로 찾기</h2>
        <div className="chips">
          {districts.map((d) => (
            <Link key={d} className="chip" to={`/explore?district=${encodeURIComponent(d)}`}>
              {d}
            </Link>
          ))}
        </div>
        <p className="muted">현재 부산 지역 예시 교회 {churches.length}곳이 등록되어 있습니다.</p>
      </section>

      <section className="section grid-2">
        <Link className="info-card" to="/denominations">
          <h3>교단이 궁금하신가요?</h3>
          <p>예장통합, 예장합동, 기감, 기성, 기침, 기장 등 주요 교단을 짧게 소개합니다.</p>
        </Link>
        <Link className="info-card" to="/heresy">
          <h3>이단 바로 알기</h3>
          <p>교단 총회의 공식 결의를 출처와 함께 정리하는 공간입니다. (자료 준비 중)</p>
        </Link>
      </section>
    </div>
  )
}
