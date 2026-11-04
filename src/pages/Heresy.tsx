import { denominationName, denominations, heresySections } from '../lib/data'

export function Heresy() {
  return (
    <div className="page">
      <h1>이단 바로 알기</h1>
      <p className="lead">
        교단 총회가 공식적으로 결의한 내용을 <strong>출처와 함께</strong> 정리하는 공간입니다. 현재는 자료를 준비 중이며,
        확인된 자료만 순서대로 게재합니다.
      </p>

      <section className="info-card">
        <h2>게재 원칙</h2>
        <ul className="bullets">
          <li>각 교단 총회가 공식 절차로 결의한 내용만 싣습니다.</li>
          <li>모든 항목에 총회명·문서명 등 확인 가능한 출처를 함께 표시합니다.</li>
          <li>교단마다 판단이 다를 수 있으므로 교단별로 나누어 보여 줍니다.</li>
          <li>
            <strong>스티플은 개별 교회에 이단 여부를 표시하거나 판단하지 않습니다.</strong> 교회 목록과 상세 화면에는
            이런 표시가 없습니다.
          </li>
        </ul>
      </section>

      <div className="stack">
        {denominations.map((d) => {
          const section = heresySections.find((s) => s.denominationId === d.id)
          const published = section?.status === 'published' && section.entries.length > 0
          return (
            <section key={d.id} className="info-card">
              <h2>{denominationName(d.id)}</h2>
              <p className="muted">{d.fullName}</p>
              {published ? (
                <table className="table">
                  <thead>
                    <tr>
                      <th>연도</th>
                      <th>대상</th>
                      <th>결의 내용</th>
                      <th>출처</th>
                    </tr>
                  </thead>
                  <tbody>
                    {section!.entries.map((e) => (
                      <tr key={`${e.year}-${e.target}`}>
                        <td>{e.year}</td>
                        <td>{e.target}</td>
                        <td>{e.summary}</td>
                        <td>
                          {e.sourceUrl ? (
                            <a href={e.sourceUrl} target="_blank" rel="noopener noreferrer">
                              {e.sourceName}
                            </a>
                          ) : (
                            e.sourceName
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              ) : (
                <p className="placeholder">자료 준비 중</p>
              )}
            </section>
          )
        })}
      </div>
    </div>
  )
}
