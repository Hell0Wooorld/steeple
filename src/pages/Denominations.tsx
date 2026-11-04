import { Link } from 'react-router-dom'
import { churches, denominations } from '../lib/data'

export function Denominations() {
  return (
    <div className="page">
      <h1>교단 안내</h1>
      <p className="lead">
        교단은 신앙의 뿌리와 교회 운영 방식이 비슷한 교회들의 모임입니다. 같은 교단이라도 예배 분위기와 교회 문화는
        교회마다 다를 수 있으니, 아래 소개는 큰 흐름을 이해하는 참고용으로 읽어 주세요.
      </p>

      <div className="stack">
        {denominations.map((d) => {
          const count = churches.filter((c) => c.denomination === d.id).length
          return (
            <section key={d.id} className="info-card" id={d.id}>
              <h2>
                {d.name} <small>{d.fullName}</small>
              </h2>
              <p className="muted">{d.tradition}</p>
              <p>{d.summary}</p>
              <ul className="bullets">
                {d.features.map((f) => (
                  <li key={f}>{f}</li>
                ))}
              </ul>
              <Link className="card-link" to={`/explore?denomination=${d.id}`}>
                예시 교회 {count}곳 보기 →
              </Link>
            </section>
          )
        })}
      </div>

      <p className="notice">
        위 소개는 일반적인 개요이며 교단의 공식 입장을 대신하지 않습니다. 정확한 내용은 각 교단 총회의 공식 자료를
        확인해 주세요.
      </p>
    </div>
  )
}
