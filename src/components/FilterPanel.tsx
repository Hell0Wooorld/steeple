import type { Filters } from '../lib/filters'
import { emptyFilters, toggle } from '../lib/filters'
import { bandLabels, denominations, districts, dongsOf, sizeLabels } from '../lib/data'
import type { Size, TimeBand } from '../types'

interface Props {
  filters: Filters
  onChange: (f: Filters) => void
}

export function FilterPanel({ filters, onChange }: Props) {
  const set = (patch: Partial<Filters>) => onChange({ ...filters, ...patch })
  const dongs = filters.district ? dongsOf(filters.district) : []

  return (
    <div className="filters">
      <div className="field-row">
        <label>
          <span>구 / 군</span>
          <select value={filters.district} onChange={(e) => set({ district: e.target.value, dong: '' })}>
            <option value="">전체</option>
            {districts.map((d) => (
              <option key={d} value={d}>
                {d}
              </option>
            ))}
          </select>
        </label>
        <label>
          <span>동</span>
          <select value={filters.dong} disabled={!filters.district} onChange={(e) => set({ dong: e.target.value })}>
            <option value="">{filters.district ? '전체' : '구를 먼저 선택'}</option>
            {dongs.map((d) => (
              <option key={d} value={d}>
                {d}
              </option>
            ))}
          </select>
        </label>
      </div>

      <fieldset>
        <legend>교단</legend>
        <div className="chips">
          {denominations.map((d) => (
            <button
              key={d.id}
              type="button"
              className={`chip${filters.denominations.includes(d.id) ? ' chip-on' : ''}`}
              aria-pressed={filters.denominations.includes(d.id)}
              onClick={() => set({ denominations: toggle(filters.denominations, d.id) })}
            >
              {d.name}
            </button>
          ))}
        </div>
      </fieldset>

      <fieldset>
        <legend>주일 예배 시간대</legend>
        <div className="chips">
          {(Object.keys(bandLabels) as TimeBand[]).map((b) => (
            <button
              key={b}
              type="button"
              className={`chip${filters.bands.includes(b) ? ' chip-on' : ''}`}
              aria-pressed={filters.bands.includes(b)}
              onClick={() => set({ bands: toggle(filters.bands, b) })}
            >
              {bandLabels[b]}
            </button>
          ))}
        </div>
      </fieldset>

      <fieldset>
        <legend>교회 규모</legend>
        <div className="chips">
          {(Object.keys(sizeLabels) as Size[]).map((s) => (
            <button
              key={s}
              type="button"
              className={`chip${filters.sizes.includes(s) ? ' chip-on' : ''}`}
              aria-pressed={filters.sizes.includes(s)}
              onClick={() => set({ sizes: toggle(filters.sizes, s) })}
            >
              {sizeLabels[s]}
            </button>
          ))}
        </div>
      </fieldset>

      <button type="button" className="btn btn-ghost" onClick={() => onChange(emptyFilters)}>
        필터 초기화
      </button>
    </div>
  )
}
