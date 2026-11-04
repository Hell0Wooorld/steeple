import { Link } from 'react-router-dom'
import type { Church } from '../types'
import { denominationName, sizeShort, sundayServices } from '../lib/data'
import { formatDistance } from '../lib/geo'

interface Props {
  church: Church
  distanceKm?: number
  selected?: boolean
  onSelect?: (id: string) => void
}

export function ChurchCard({ church, distanceKm, selected, onSelect }: Props) {
  const times = sundayServices(church).map((s) => s.time).join(' · ')
  return (
    <article className={`card${selected ? ' card-selected' : ''}`} id={`card-${church.id}`}>
      <button type="button" className="card-main" onClick={() => onSelect?.(church.id)}>
        <div className="card-head">
          <h3>{church.name}</h3>
          {distanceKm !== undefined && <span className="distance">{formatDistance(distanceKm)}</span>}
        </div>
        <div className="badges">
          <span className="badge badge-denom">{denominationName(church.denomination)}</span>
          <span className="badge">{sizeShort[church.size]}</span>
        </div>
        <p className="muted">
          {church.district} {church.dong} · {church.address}
        </p>
        <p className="muted">주일 예배 {times}</p>
      </button>
      <Link className="card-link" to={`/church/${church.id}`}>
        자세히 보기 →
      </Link>
    </article>
  )
}
