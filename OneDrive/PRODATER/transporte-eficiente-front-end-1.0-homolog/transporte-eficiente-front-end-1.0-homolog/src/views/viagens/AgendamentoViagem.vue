<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import DefaultLayout from '@/layouts/DefaultLayout.vue'
import AgendarViagemForm from '@/components/forms/AgendarViagemForm.vue'
import MapaInterativo from '@/components/mapas/MapaInterativo.vue'
import BaseAlert from '@/components/messages/BaseAlert.vue'
import { useUserStore } from '@/stores/user'
import BottomSheet from '@/components/buttons/BottomSheet.vue'

const userStore = useUserStore()

const origemCoords = ref<[number, number] | undefined>(undefined)
const destinoCoords = ref<[number, number] | undefined>(undefined)

const sheetOpen = ref(true)

// detectar viewport < lg
const isSmall = ref(false)
onMounted(() => {
  const mql = window.matchMedia('(max-width: 1023px)')
  const update = () => (isSmall.value = mql.matches)
  update()
  mql.addEventListener('change', update)
  onUnmounted(() => mql.removeEventListener('change', update))
})

// dados de rota
const distanciaText = ref('')
const duracaoText = ref('')
const routeErrorOpen = ref(false)
const routeErrorMsg = ref('')

// ref do form p/ preencher endereços quando arrasta pin
const formRef = ref<InstanceType<typeof AgendarViagemForm> | null>(null)

// id do beneficiário (por enquanto sub)
const beneficiarioId = computed<string>(() => userStore.user?.sub ?? '')

// QUAL CAMPO ESTÁ FOCADO NO FORM?
const activeField = ref<'origem' | 'destino' | null>(null)
function onFocusField(field: 'origem' | 'destino') {
  activeField.value = field
}

// vindo do form (autocomplete -> pins)
function atualizarOrigem(coords: [number, number] | undefined) {
  origemCoords.value = coords
}
function atualizarDestino(coords: [number, number] | undefined) {
  destinoCoords.value = coords
}

// vindo do mapa
function onRouteInfo(payload: {
  coords: [number, number][]
  distanceText?: string
  durationText?: string
}) {
  distanciaText.value = payload.distanceText ?? ''
  duracaoText.value = payload.durationText ?? ''
}
function onRouteError(msg: string) {
  routeErrorMsg.value = msg
  routeErrorOpen.value = true
}
function onOrigemDragged(coords: [number, number]) {
  origemCoords.value = coords
}
function onDestinoDragged(coords: [number, number]) {
  destinoCoords.value = coords
}
function onOrigemAddress(addr: string) {
  formRef.value?.setEnderecoOrigem(addr)
}
function onDestinoAddress(addr: string) {
  formRef.value?.setEnderecoDestino(addr)
}


// CLIQUE NO MAPA COM ENDEREÇO (reverse geocode feito no filho)
function onMapClickAddress(payload: { coords: [number, number]; address: string }) {
  const { coords, address } = payload

  // Se o usuário focou um campo explicitamente, respeita
  if (activeField.value === 'destino') {
    destinoCoords.value = coords
    formRef.value?.setEnderecoDestino(address)
    return
  }
  if (activeField.value === 'origem') {
    origemCoords.value = coords
    formRef.value?.setEnderecoOrigem(address)
    return
  }

  // Sem foco explícito: 1º destino vazio → destino; depois origem
  if (!destinoCoords.value) {
    destinoCoords.value = coords
    formRef.value?.setEnderecoDestino(address)
  } else if (!origemCoords.value) {
    origemCoords.value = coords
    formRef.value?.setEnderecoOrigem(address)
  } else {
    // ambos já preenchidos: por padrão sobrescreve o destino
    destinoCoords.value = coords
    formRef.value?.setEnderecoDestino(address)
  }
}
</script>

<template>
  <Suspense>
    <template #default>
      <DefaultLayout
        title="Transporte Eficiente"
        logoSrc="/imgs/LOGO_PMT_Colorida.svg"
        :links="[
          {
            label: 'Cadastro beneficiário',
            to: '/cadastro-beneficiario',
            icon: 'fas fa-user-plus',
          },
          { label: 'Minhas Viagens', to: '/minhas-viagens', icon: 'fas fa-list' },
        ]"
      >
        <template #items-modal-float>
          <button
            class="block w-full text-left px-4 py-3 text-gray-800 border-b border-gray-300 hover:bg-gray-100 cursor-pointer"
          >
            Minhas Viagens
          </button>
        </template>

        <template #header-title>Agendamento de Viagens</template>

        <div class="relative w-full h-[500px] sm:h-[520px] md:h-[560px] lg:h-[620px]">
          <!-- Painel distância/duração -->
          <div
            v-if="distanciaText || duracaoText"
            class="absolute top-2 right-2 z-10 bg-[#ffffffd6] shadow rounded p-3 text-sm"
          >
            <div v-if="distanciaText">
              Distância: <strong>{{ distanciaText }}</strong>
            </div>
            <div v-if="duracaoText">
              Duração: <strong>{{ duracaoText }}</strong>
            </div>
          </div>

          <!-- Mapa -->
          <div class="absolute inset-0 z-0">
            <MapaInterativo
              :origem-coords="origemCoords"
              :destino-coords="destinoCoords"
              @route-info="onRouteInfo"
              @route-error="onRouteError"
              @origem-dragged="onOrigemDragged"
              @destino-dragged="onDestinoDragged"
              @origem-address="onOrigemAddress"
              @destino-address="onDestinoAddress"
              @map-click-address="onMapClickAddress"
            />
          </div>

          <!-- Form desktop -->
          <div
            class="hidden lg:block absolute top-4 left-4 z-10 bg-white shadow-lg rounded-lg p-6 w-[360px] opacity-[.95]"
          >
            <AgendarViagemForm
              ref="formRef"
              :prefill-beneficiario="String(beneficiarioId || '')"
              :pending="false"
              :origem-coords="origemCoords"
              :destino-coords="destinoCoords"
              @update-origem="atualizarOrigem"
              @update-destino="atualizarDestino"
              @focus-field="onFocusField"
            />
          </div>

          <!-- Form mobile -->
          <BottomSheet
            v-if="isSmall"
            v-model="sheetOpen"
            height="72vh"
            :peek="42"
            :overlay="true"
            :closeOnOverlay="true"
            class="lg:hidden"
          >
            <AgendarViagemForm
              ref="formRef"
              :prefill-beneficiario="String(beneficiarioId || '')"
              :pending="false"
              :origem-coords="origemCoords"
              :destino-coords="destinoCoords"
              @update-origem="atualizarOrigem"
              @update-destino="atualizarDestino"
              @focus-field="onFocusField"
            />
          </BottomSheet>
        </div>

        <BaseAlert
          v-if="routeErrorOpen"
          status="danger"
          :message="routeErrorMsg"
          @close="routeErrorOpen = false"
        />
      </DefaultLayout>
    </template>

    <template #fallback>
      <div>Carregando...</div>
    </template>
  </Suspense>
</template>
