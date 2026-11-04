import type { Church, Size, TimeBand } from '../types'
import { bandOf, sundayServices } from './data'

export interface Filters {
  q: string
  district: string
  dong: string
  denominations: string[]
  bands: TimeBand[]
  sizes: Size[]
}

export const emptyFilters: Filters = {
  q: '',
  district: '',
  dong: '',
  denominations: [],
  bands: [],
  sizes: [],
}

export const activeFilterCount = (f: Filters) =>
  (f.q.trim() ? 1 : 0) +
  (f.district ? 1 : 0) +
  (f.dong ? 1 : 0) +
  f.denominations.length +
  f.bands.length +
  f.sizes.length

export function applyFilters(list: Church[], f: Filters): Church[] {
  const q = f.q.trim().toLowerCase()
  return list.filter((c) => {
    if (q && !`${c.name} ${c.address} ${c.dong} ${c.district}`.toLowerCase().includes(q)) return false
    if (f.district && c.district !== f.district) return false
    if (f.dong && c.dong !== f.dong) return false
    if (f.denominations.length && !f.denominations.includes(c.denomination)) return false
    if (f.sizes.length && !f.sizes.includes(c.size)) return false
    if (f.bands.length) {
      const bands = sundayServices(c).map((s) => bandOf(s.time))
      if (!f.bands.some((b) => bands.includes(b))) return false
    }
    return true
  })
}

export function toggle<T>(list: T[], value: T): T[] {
  return list.includes(value) ? list.filter((v) => v !== value) : [...list, value]
}
