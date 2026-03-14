<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { LMap, LTileLayer, LMarker, LPolyline, LControlZoom } from '@vue-leaflet/vue-leaflet'
import type { DragEndEvent, Marker, LeafletMouseEvent } from 'leaflet'

import { useRotaOSRM } from '@/composables/mapas/useRotaOSRM'
import { useGeocoding } from '@/composables/mapas/useGeocoding'

const props = defineProps<{
  origemCoords?: [number, number]
  destinoCoords?: [number, number]
}>()

const emit = defineEmits<{
  (e: 'origem-dragged', value: [number, number]): void
  (e: 'destino-dragged', value: [number, number]): void
  (e: 'origem-address', value: string): void
  (e: 'destino-address', value: string): void
  (e: 'map-click', coords: [number, number]): void
  (e: 'map-click-address', payload: { coords: [number, number]; address: string }): void
  (
    e: 'route-info',
    v: { coords: [number, number][]; distanceText?: string; durationText?: string },
  ): void
  (e: 'route-error', msg: string): void
}>()

// Serviços
const { computeRoute } = useRotaOSRM()
const { reverseGeocode } = useGeocoding()

// (GOOGLE ROUTES) — deixar pronto para quando liberar
// Basta trocar os imports acima por:
// import { useRotaGoogle } from '@/composables/mapas/useRotaGoogle'
// const { computeRoute } = useRotaGoogle()

// Estado interno do mapa
const defaultCenter: [number, number] = [-5.0892, -42.8019]
const center = computed<[number, number]>(() => props.origemCoords ?? defaultCenter)
const zoom = ref(13)

const isRouting = ref(false)
const rotaCoords = ref<[number, number][]>([])
const distanciaText = ref('')
const duracaoText = ref('')

// Enquadra o mapa quando houver os dois pontos
const bounds = computed<[[number, number], [number, number]] | undefined>(() => {
  if (props.origemCoords && props.destinoCoords) {
    return [props.origemCoords, props.destinoCoords]
  }
  return undefined
})

// Endereço ao clicar no mapa
async function onMapClick(e: LeafletMouseEvent) {
  const coords: [number, number] = [e.latlng.lat, e.latlng.lng]
  emit('map-click', coords)

  const addr = await reverseGeocode(coords)
  if (addr) {
    emit('map-click-address', { coords, address: addr })
  }
}

// Cálculo de rota (agora aqui dentro)
watch(
  () => [props.origemCoords, props.destinoCoords] as const,
  async ([o, d]) => {
    if (!o || !d) {
      rotaCoords.value = []
      distanciaText.value = ''
      duracaoText.value = ''
      return
    }

    try {
      isRouting.value = true
      const res = await computeRoute(o, d)
      rotaCoords.value = res.coords
      distanciaText.value = res.distanceText ?? ''
      duracaoText.value = res.durationText ?? ''
      emit('route-info', {
        coords: rotaCoords.value,
        distanceText: distanciaText.value,
        durationText: duracaoText.value,
      })
    } catch {
      rotaCoords.value = []
      distanciaText.value = ''
      duracaoText.value = ''
      emit('route-error', 'Falha ao calcular rota.')
    } finally {
      isRouting.value = false
    }
  },
  { immediate: false },
)

// Drag handlers (com reverse geocode p/ preencher inputs)
async function onOrigemDragEnd(e: DragEndEvent) {
  const marker = e.target as Marker
  const { lat, lng } = marker.getLatLng()
  const coords: [number, number] = [lat, lng]
  emit('origem-dragged', coords)
  const addr = await reverseGeocode(coords)
  if (addr) emit('origem-address', addr)
}

async function onDestinoDragEnd(e: DragEndEvent) {
  const marker = e.target as Marker
  const { lat, lng } = marker.getLatLng()
  const coords: [number, number] = [lat, lng]
  emit('destino-dragged', coords)
  const addr = await reverseGeocode(coords)
  if (addr) emit('destino-address', addr)
}
</script>

<template>
  <div class="relative w-full h-full">
    <LMap
      :zoom="zoom"
      :center="center"
      :bounds="bounds"
      :max-zoom="16"
      :options="{ zoomControl: false, tap: false }"
      @click="onMapClick"
    >
      <LTileLayer
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        attribution="&copy; OpenStreetMap contributors"
      />

      <!-- Controle de zoom -->
      <LControlZoom position="bottomright" />

      <!-- Marcador da origem (arrastável) -->
      <LMarker
        v-if="origemCoords"
        :lat-lng="origemCoords"
        :draggable="true"
        @dragend="onOrigemDragEnd"
      />
      <!-- Marcador do destino (arrastável) -->
      <LMarker
        v-if="destinoCoords"
        :lat-lng="destinoCoords"
        :draggable="true"
        @dragend="onDestinoDragEnd"
      />

      <!-- Linha da rota -->
      <LPolyline
        v-if="rotaCoords.length"
        :lat-lngs="rotaCoords"
        :weight="5"
        :color="'#1976d2'"
        :opacity="0.9"
      />
    </LMap>

    <!-- Overlay de loading da rota -->
    <div
      v-if="isRouting"
      class="absolute inset-0 bg-white/20 backdrop-blur-[1px] flex items-center justify-center z-[1000]"
    >
      <div class="br-loading medium">
        <div class="loading"></div>
      </div>
    </div>
  </div>
</template>
