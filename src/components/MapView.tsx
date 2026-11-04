import { useEffect, useRef } from 'react'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'
import type { Church } from '../types'
import type { LatLng } from '../lib/geo'
import { denominationName } from '../lib/data'

interface Props {
  churches: Church[]
  selectedId?: string | null
  onSelect?: (id: string) => void
  userPos?: LatLng | null
  /** 상세 페이지처럼 한 곳만 보여줄 때 */
  zoom?: number
  className?: string
}

const escapeHtml = (s: string) =>
  s.replace(/[&<>"']/g, (ch) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[ch]!)

const pinIcon = (selected: boolean) =>
  L.divIcon({
    className: `pin${selected ? ' pin-selected' : ''}`,
    html: `<svg viewBox="0 0 32 40" width="${selected ? 36 : 30}" height="${selected ? 45 : 38}" aria-hidden="true">
      <path d="M16 39C16 39 3 24 3 14a13 13 0 0 1 26 0c0 10-13 25-13 25z" fill="${selected ? '#c9892b' : '#1f3a5f'}" stroke="#fff" stroke-width="2"/>
      <path d="M16 6v8M12.5 9.5h7" stroke="#fff" stroke-width="2.2" stroke-linecap="round"/>
      <path d="M16 14l5 9h-10z" fill="#fff"/>
    </svg>`,
    iconSize: selected ? [36, 45] : [30, 38],
    iconAnchor: selected ? [18, 45] : [15, 38],
    popupAnchor: [0, -36],
  })

export function MapView({ churches, selectedId, onSelect, userPos, zoom, className }: Props) {
  const containerRef = useRef<HTMLDivElement>(null)
  const mapRef = useRef<L.Map | null>(null)
  const markersRef = useRef<Map<string, L.Marker>>(new Map())
  const layerRef = useRef<L.LayerGroup | null>(null)
  const userMarkerRef = useRef<L.CircleMarker | null>(null)
  const onSelectRef = useRef(onSelect)
  onSelectRef.current = onSelect

  // 지도 초기화 (한 번만)
  useEffect(() => {
    if (!containerRef.current || mapRef.current) return
    const map = L.map(containerRef.current, { zoomControl: true }).setView([35.18, 129.05], 12)
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    }).addTo(map)
    layerRef.current = L.layerGroup().addTo(map)
    mapRef.current = map

    const observer = new ResizeObserver(() => map.invalidateSize())
    observer.observe(containerRef.current)
    return () => {
      observer.disconnect()
      map.remove()
      mapRef.current = null
      markersRef.current.clear()
    }
  }, [])

  // 핀 갱신
  useEffect(() => {
    const map = mapRef.current
    const layer = layerRef.current
    if (!map || !layer) return
    layer.clearLayers()
    markersRef.current.clear()

    churches.forEach((c) => {
      const marker = L.marker([c.lat, c.lng], { icon: pinIcon(false), title: c.name })
      marker.bindPopup(
        `<div class="popup"><strong>${escapeHtml(c.name)}</strong><br/>${escapeHtml(
          denominationName(c.denomination),
        )} · ${escapeHtml(c.dong)}<br/><a href="#/church/${encodeURIComponent(c.id)}">자세히 보기</a></div>`,
      )
      marker.on('click', () => onSelectRef.current?.(c.id))
      marker.addTo(layer)
      markersRef.current.set(c.id, marker)
    })

    if (churches.length === 1) {
      map.setView([churches[0].lat, churches[0].lng], zoom ?? 16)
    } else if (churches.length > 1) {
      const bounds = L.latLngBounds(churches.map((c) => [c.lat, c.lng] as [number, number]))
      map.fitBounds(bounds, { padding: [40, 40], maxZoom: 15 })
    }
  }, [churches, zoom])

  // 선택 강조
  useEffect(() => {
    markersRef.current.forEach((marker, id) => {
      const selected = id === selectedId
      marker.setIcon(pinIcon(selected))
      marker.setZIndexOffset(selected ? 1000 : 0)
    })
    const map = mapRef.current
    const marker = selectedId ? markersRef.current.get(selectedId) : undefined
    if (map && marker) {
      map.setView(marker.getLatLng(), Math.max(map.getZoom(), 15), { animate: true })
      marker.openPopup()
    }
  }, [selectedId, churches])

  // 내 위치 표시
  useEffect(() => {
    const map = mapRef.current
    if (!map) return
    userMarkerRef.current?.remove()
    userMarkerRef.current = null
    if (userPos) {
      userMarkerRef.current = L.circleMarker([userPos.lat, userPos.lng], {
        radius: 8,
        color: '#fff',
        weight: 3,
        fillColor: '#2f7de1',
        fillOpacity: 1,
      })
        .bindTooltip('내 위치')
        .addTo(map)
    }
  }, [userPos])

  return <div ref={containerRef} className={className ?? 'map'} role="application" aria-label="교회 지도" />
}
