import churchesJson from '../data/churches.json'
import denominationsJson from '../data/denominations.json'
import heresyJson from '../data/heresy-resolutions.json'
import type { Church, Denomination, HeresySection, Size, TimeBand } from '../types'

export const churches = churchesJson as Church[]
export const denominations = denominationsJson as Denomination[]
export const heresySections = heresyJson.denominations as HeresySection[]

export const denominationName = (id: string) =>
  denominations.find((d) => d.id === id)?.name ?? id

export const sizeLabels: Record<Size, string> = {
  small: '소형 (100명 미만)',
  medium: '중형 (100~499명)',
  large: '대형 (500명 이상)',
}

export const sizeShort: Record<Size, string> = {
  small: '소형',
  medium: '중형',
  large: '대형',
}

export const bandLabels: Record<TimeBand, string> = {
  morning: '오전 (12시 이전)',
  afternoon: '오후 (12~18시)',
  evening: '저녁 (18시 이후)',
}

export function bandOf(time: string): TimeBand {
  const hour = Number(time.split(':')[0])
  if (hour < 12) return 'morning'
  if (hour < 18) return 'afternoon'
  return 'evening'
}

export const sundayServices = (c: Church) => c.services.filter((s) => s.day === '주일')

export const districts = [...new Set(churches.map((c) => c.district))].sort((a, b) =>
  a.localeCompare(b, 'ko'),
)

export const dongsOf = (district: string) =>
  [...new Set(churches.filter((c) => c.district === district).map((c) => c.dong))].sort((a, b) =>
    a.localeCompare(b, 'ko'),
  )

export const findChurch = (id: string) => churches.find((c) => c.id === id)
