import { useCallback, useEffect, useMemo, useState } from 'react'
import { useSearchParams } from 'react-router-dom'
import { MapView } from '../components/MapView'
import { ChurchCard } from '../components/ChurchCard'
import { FilterPanel } from '../components/FilterPanel'
import { churches, denominations, districts } from '../lib/data'
import { activeFilterCount, applyFilters, emptyFilters, type Filters } from '../lib/filters'
import { distanceKm, type LatLng } from '../lib/geo'

type GeoState = 'idle' | 'loading' | 'ok' | 'error'

export function Explore() {
  const [params] = useSearchParams()
  const initialDistrict = params.get('district') ?? ''
  const initialDenomination = params.get('denomination') ?? ''

  const [filters, setFilters] = useState<Filters>({
    ...emptyFilters,
    q: params.get('q') ?? '',
    district: districts.includes(initialDistrict) ? initialDistrict : '',
    denominations: denominations.some((d) => d.id === initialDenomination) ? [initialDenomination] : [],
  })
  const [showFilters, setShowFilters] = useState(false)
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [userPos, setUserPos] = useState<LatLng | null>(null)
  const [geoState, setGeoState] = useState<GeoState>('idle')
  const [geoMessage, setGeoMessage] = useState('')

  const locate = useCallback(() => {
    if (!('geolocation' in navigator)) {
      setGeoState('error')
      setGeoMessage('이 브라우저는 위치 기능을 지원하지 않습니다.')
      return
    }
    setGeoState('loading')
    setGeoMessage('')
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setUserPos({ lat: pos.coords.latitude, lng: pos.coords.longitude })
        setGeoState('ok')
      },
      (err) => {
        setGeoState('error')
        setGeoMessage(
          err.code === err.PERMISSION_DENIED
            ? '위치 권한이 거부되었습니다. 브라우저 설정에서 위치 접근을 허용해 주세요.'
            : '현재 위치를 가져오지 못했습니다. 잠시 후 다시 시도해 주세요.',
        )
      },
      { enableHighAccuracy: false, timeout: 10000, maximumAge: 60000 },
    )
  }, [])

  useEffect(() => {
    if (params.get('nearby') === '1') locate()
    // 처음 진입할 때만 실행
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const list = useMemo(() => {
    const filtered = applyFilters(churches, filters).map((church) => ({
      church,
      km: userPos ? distanceKm(userPos, church) : undefined,
    }))
    filtered.sort((a, b) =>
      userPos ? (a.km ?? 0) - (b.km ?? 0) : a.church.name.localeCompare(b.church.name, 'ko'),
    )
    return filtered
  }, [filters, userPos])

  const mapChurches = useMemo(() => list.map((i) => i.church), [list])

  const select = useCallback((id: string) => {
    setSelectedId(id)
    document.getElementById(`card-${id}`)?.scrollIntoView({ block: 'nearest', behavior: 'smooth' })
  }, [])

  const count = activeFilterCount(filters)

  return (
    <div className="explore">
      <div className="explore-map">
        <MapView churches={mapChurches} selectedId={selectedId} onSelect={select} userPos={userPos} />
      </div>

      <div className="explore-list">
        <div className="toolbar">
          <input
            type="search"
            value={filters.q}
            onChange={(e) => setFilters({ ...filters, q: e.target.value })}
            placeholder="교회 이름, 동네 검색"
            aria-label="교회 검색"
          />
          <div className="toolbar-row">
            <button
              type="button"
              className={`btn ${showFilters ? 'btn-primary' : 'btn-ghost'}`}
              aria-expanded={showFilters}
              onClick={() => setShowFilters(!showFilters)}
            >
              필터{count > 0 ? ` (${count})` : ''}
            </button>
            <button type="button" className="btn btn-accent" onClick={locate} disabled={geoState === 'loading'}>
              {geoState === 'loading' ? '위치 확인 중…' : '📍 내 주변 교회'}
            </button>
          </div>
          {geoState === 'error' && (
            <p className="notice notice-warn" role="alert">
              {geoMessage}
            </p>
          )}
          {geoState === 'ok' && (
            <p className="notice">현재 위치를 기준으로 가까운 순서로 정렬했습니다.</p>
          )}
          {showFilters && <FilterPanel filters={filters} onChange={setFilters} />}
        </div>

        <p className="result-count" aria-live="polite">
          교회 {list.length}곳
        </p>

        {list.length === 0 ? (
          <div className="empty">
            <p>조건에 맞는 교회가 없습니다.</p>
            <button type="button" className="btn btn-ghost" onClick={() => setFilters(emptyFilters)}>
              필터 초기화
            </button>
          </div>
        ) : (
          <div className="cards">
            {list.map(({ church, km }) => (
              <ChurchCard
                key={church.id}
                church={church}
                distanceKm={km}
                selected={church.id === selectedId}
                onSelect={select}
              />
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
