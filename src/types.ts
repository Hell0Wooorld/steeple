export type Size = 'small' | 'medium' | 'large'
export type TimeBand = 'morning' | 'afternoon' | 'evening'

export interface Service {
  name: string
  day: string
  time: string // "HH:MM" (24시간)
}

export interface Church {
  id: string
  name: string
  denomination: string // denominations.json 의 id
  address: string
  district: string // 구/군
  dong: string
  lat: number
  lng: number
  pastor: string
  size: Size
  attendance: number // 주일 출석 (대략)
  services: Service[]
  departments: string[]
  website?: string
  phone?: string
  intro: string
}

export interface Denomination {
  id: string
  name: string
  fullName: string
  tradition: string
  summary: string
  features: string[]
}

export interface HeresyEntry {
  year: number
  target: string // 결의 대상 단체명
  summary: string // 결의 내용 요약
  sourceName: string // 총회명 + 문서명
  sourceUrl?: string
}

export interface HeresySection {
  denominationId: string
  status: 'preparing' | 'published'
  entries: HeresyEntry[]
}
