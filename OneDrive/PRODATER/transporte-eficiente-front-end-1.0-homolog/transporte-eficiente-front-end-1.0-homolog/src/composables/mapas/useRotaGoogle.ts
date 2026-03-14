import { decodePolyline } from '@/utils/decodePolyline'
export type LatLng = [number, number]

type ComputeRouteResult = {
  coords: LatLng[]
  distanceText?: string
  durationText?: string
}

export function useRotaGoogle() {
  const apiKey = import.meta.env.VITE_GOOGLE_MAPS_API_KEY as string

  async function computeRoute(origem: LatLng, destino: LatLng): Promise<ComputeRouteResult> {
    const url = 'https://routes.googleapis.com/directions/v2:computeRoutes'

    const body = {
      origin:   { location: { latLng: { latitude: origem[0],  longitude: origem[1]  } } },
      destination:{ location: { latLng: { latitude: destino[0], longitude: destino[1] } } },
      travelMode: 'DRIVE',
      polylineEncoding: 'ENCODED_POLYLINE'
    }

    // FieldMask é obrigatório na Routes API v2
    const headers = {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask': [
        'routes.polyline.encodedPolyline',
        'routes.distanceMeters',
        'routes.duration'
      ].join(',')
    }

    const resp = await fetch(url, { method: 'POST', headers, body: JSON.stringify(body) })

    if (!resp.ok) {
      const err = await resp.text().catch(() => '')
      throw new Error(`Routes API error: ${resp.status} ${err}`)
    }

    const data = await resp.json()

    const route = data?.routes?.[0]
    if (!route?.polyline?.encodedPolyline) {
      return { coords: [] }
    }

    const coords = decodePolyline(route.polyline.encodedPolyline)

    // textos simples (opcional)
    const distanceText = route.distanceMeters ? `${Math.round(route.distanceMeters / 1000)} km` : undefined
    const durationText = route.duration ? route.duration.replace('s', 's') : undefined

    return { coords, distanceText, durationText }
  }

  return { computeRoute }
}
