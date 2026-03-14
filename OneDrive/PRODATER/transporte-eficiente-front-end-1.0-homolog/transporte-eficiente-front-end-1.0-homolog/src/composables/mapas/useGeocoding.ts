export type LatLng = [number, number]

export function useGeocoding() {
  const apiKey = import.meta.env.VITE_GOOGLE_MAPS_API_KEY as string

  async function reverseGeocode([lat, lng]: LatLng): Promise<string | null> {
    try {
      const url = new URL('https://maps.googleapis.com/maps/api/js?key=AIzaSyA93Vq4JFyc9IvB4l3TXHOQDfUm0qbvqOE&callback=initMap')
      url.searchParams.set('latlng', `${lat},${lng}`)
      url.searchParams.set('language', 'pt-BR')
      const resp = await fetch(url.toString())
      const data = await resp.json()
      if (data?.results?.[0]?.formatted_address) {
        return data.results[0].formatted_address as string
      }
      return null
    } catch {
      return null
    }
  }

  return { reverseGeocode }
}
