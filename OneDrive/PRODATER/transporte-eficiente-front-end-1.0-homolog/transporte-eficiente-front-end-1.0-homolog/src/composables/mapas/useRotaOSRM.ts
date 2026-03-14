// src/composables/mapas/useRotaOSRM.ts
export type LatLng = [number, number]

type ComputeRouteResult = {
  coords: LatLng[]
  distanceText?: string
  durationText?: string
}

export function useRotaOSRM() {
  async function computeRoute(origem: LatLng, destino: LatLng): Promise<ComputeRouteResult> {
    // OSRM recebe como {lon},{lat}
    const url = new URL(
      `https://router.project-osrm.org/route/v1/driving/${origem[1]},${origem[0]};${destino[1]},${destino[0]}`
    )
    url.searchParams.set('overview', 'full')
    url.searchParams.set('geometries', 'geojson')  // evita precisar decodificar polyline
    url.searchParams.set('alternatives', 'false')
    url.searchParams.set('steps', 'false')

    const resp = await fetch(url.toString())
    if (!resp.ok) {
      const text = await resp.text().catch(() => '')
      throw new Error(`OSRM error: ${resp.status} ${text}`)
    }

    const data = await resp.json()
    const route = data?.routes?.[0]
    if (!route?.geometry?.coordinates?.length) {
      return { coords: [] }
    }

    // GeoJSON vem como [lon, lat]; convertemos para [lat, lon]
    const coords: LatLng[] = route.geometry.coordinates.map(
      (c: [number, number]) => [c[1], c[0]]
    )

    const dist: number | undefined = route.distance
    const dur: number | undefined = route.duration

    return {
      coords,
      distanceText: typeof dist === 'number' ? `${Math.round(dist / 1000)} km` : undefined,
      durationText: typeof dur === 'number' ? formatDuration(dur) : undefined,
    }
  }

  function formatDuration(seconds: number): string {
    const h = Math.floor(seconds / 3600)
    const m = Math.round((seconds % 3600) / 60)
    return h > 0 ? `${h}h ${m}min` : `${m} min`
  }

  return { computeRoute }
}
