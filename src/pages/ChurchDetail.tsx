import { useMemo } from 'react'
import { Link, useParams } from 'react-router-dom'
import { MapView } from '../components/MapView'
import { denominationName, findChurch, sizeLabels } from '../lib/data'
import { NotFound } from './NotFound'

export function ChurchDetail() {
  const { id } = useParams()
  const church = id ? findChurch(id) : undefined
  const single = useMemo(() => (church ? [church] : []), [church])

  if (!church) return <NotFound />

  const osm = `https://www.openstreetmap.org/?mlat=${church.lat}&mlon=${church.lng}#map=17/${church.lat}/${church.lng}`

  return (
    <article className="detail">
      <Link to="/explore" className="back">
        ← 목록으로
      </Link>
      <h1>{church.name}</h1>
      <div className="badges">
        <span className="badge badge-denom">{denominationName(church.denomination)}</span>
        <span className="badge">{sizeLabels[church.size]}</span>
      </div>

      <p className="intro">{church.intro}</p>

      <MapView churches={single} className="map map-small" />
      <p>
        <a className="btn btn-ghost" href={osm} target="_blank" rel="noopener noreferrer">
          지도 크게 보기 / 길찾기
        </a>
      </p>

      <section className="section">
        <h2>기본 정보</h2>
        <dl className="facts">
          <dt>교단</dt>
          <dd>{denominationName(church.denomination)}</dd>
          <dt>주소</dt>
          <dd>{church.address}</dd>
          <dt>담임목사</dt>
          <dd>{church.pastor} 목사</dd>
          <dt>교회 규모</dt>
          <dd>
            {sizeLabels[church.size]} · 주일 출석 약 {church.attendance}명
          </dd>
          {church.phone && (
            <>
              <dt>연락처</dt>
              <dd>
                <a href={`tel:${church.phone}`}>{church.phone}</a>
              </dd>
            </>
          )}
          {church.website && (
            <>
              <dt>홈페이지</dt>
              <dd>
                <a href={church.website} target="_blank" rel="noopener noreferrer">
                  {church.website.replace(/^https?:\/\//, '')}
                </a>
              </dd>
            </>
          )}
        </dl>
      </section>

      <section className="section">
        <h2>예배 시간</h2>
        <table className="table">
          <thead>
            <tr>
              <th>예배</th>
              <th>요일</th>
              <th>시간</th>
            </tr>
          </thead>
          <tbody>
            {church.services.map((s) => (
              <tr key={`${s.name}-${s.time}`}>
                <td>{s.name}</td>
                <td>{s.day}</td>
                <td>{s.time}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section className="section">
        <h2>부서</h2>
        <div className="chips">
          {church.departments.map((d) => (
            <span key={d} className="chip chip-static">
              {d}
            </span>
          ))}
        </div>
      </section>

      <p className="notice">이 정보는 가상의 예시 데이터입니다. 실제 방문 전에는 반드시 교회에 직접 확인해 주세요.</p>
    </article>
  )
}
