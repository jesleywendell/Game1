import { ref, onMounted, type Ref } from 'vue'
import { Loader } from '@googlemaps/js-api-loader'

type Prediction = google.maps.places.AutocompletePrediction
type PlaceResult = google.maps.places.PlaceResult
type BoundsLiteral = { south: number; west: number; north: number; east: number }

type Options = {
  country?: string[] // default ['br']
  minLength?: number // default 3
  language?: string // default 'pt-BR'
  restrictionBounds?: BoundsLiteral // restringe estritamente à área
  biasCircle?: { center: { lat: number; lng: number }; radiusMeters: number } // dá peso
}

export function usePlacesService(inputRef: Ref<HTMLInputElement | null>, opts: Options = {}) {
  const predictions = ref<Prediction[]>([])
  const loading = ref(false)
  const selectedPlace = ref<PlaceResult | null>(null)

  const country = opts.country ?? ['br']
  const minLength = opts.minLength ?? 3
  const language = opts.language ?? 'pt-BR'

  let svc: google.maps.places.AutocompleteService | null = null
  let places: google.maps.places.PlacesService | null = null
  let session: google.maps.places.AutocompleteSessionToken | null = null

  onMounted(async () => {
    const loader = new Loader({
      apiKey: import.meta.env.VITE_GOOGLE_MAPS_API_KEY!,
      version: 'weekly',
      libraries: ['places'],
      language,
      region: 'BR',
    })
    await loader.load()

    svc = new google.maps.places.AutocompleteService()
    places = new google.maps.places.PlacesService(document.createElement('div'))
    session = new google.maps.places.AutocompleteSessionToken()
  })

  async function onInput(text: string) {
    selectedPlace.value = null
    if (!svc || text.trim().length < minLength) {
      predictions.value = []
      return
    }
    loading.value = true
    await new Promise<void>((resolve) => {
      const req: google.maps.places.AutocompletionRequest = {
        input: text,
        language,
        sessionToken: session!,
        componentRestrictions: { country },
        // types: ['geocode'], // opcional: só endereços
      }

      // prioridade: restriction (trava dentro do retângulo). senão, bias (prioriza perto).
      if (opts.restrictionBounds) {
        req.locationRestriction = opts.restrictionBounds
      } else if (opts.biasCircle) {
        req.locationBias = new google.maps.Circle({
          center: opts.biasCircle.center,
          radius: opts.biasCircle.radiusMeters,
        })
      }

      svc!.getPlacePredictions(req, (preds) => {
        predictions.value = preds ?? []
        loading.value = false
        resolve()
      })
    })
  }

  async function selectPrediction(pred: Prediction) {
    if (!places) return
    loading.value = true
    await new Promise<void>((resolve) => {
      places!.getDetails(
        {
          placeId: pred.place_id,
          language,
          sessionToken: session!,
          fields: ['formatted_address', 'geometry', 'place_id', 'address_components', 'name'],
        },
        (place, status) => {
          loading.value = false
          if (status === google.maps.places.PlacesServiceStatus.OK && place) {
            selectedPlace.value = place
            predictions.value = []
            // renova o token p/ nova sessão de autocomplete
            session = new google.maps.places.AutocompleteSessionToken()
          }
          resolve()
        },
      )
    })
  }

  return { predictions, loading, selectedPlace, onInput, selectPrediction }
}
