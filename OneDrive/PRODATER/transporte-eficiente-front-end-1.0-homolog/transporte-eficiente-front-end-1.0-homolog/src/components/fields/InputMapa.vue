<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import { usePlacesService } from '@/composables/mapas/usePlacesService'

type Status = '' | 'success' | 'danger' | 'info' | 'warning'

const props = defineProps<{
  modelValue: string
  label: string
  placeholder: string
  status?: Status
  message?: string
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', v: string): void
  (e: 'placeSelected', place: google.maps.places.PlaceResult): void
  (e: 'focus'): void
}>()

const inputRef = ref<HTMLInputElement | null>(null)
// restrito so a cidade teresina(nada fora do retangulo)
const { predictions, loading, selectedPlace, onInput, selectPrediction } = usePlacesService(
  inputRef,
  {
    country: ['br'],
    language: 'pt-BR',
    restrictionBounds: {
      south: -5.25,
      west: -42.81, // ajustado para cortar Timon
      north: -4.95,
      east: -42.65,
    },
  },
)

watch(selectedPlace, (place) => {
  if (place?.formatted_address) {
    emit('update:modelValue', place.formatted_address)
    emit('placeSelected', place)
  }
})

// a cada digitação, atualiza v-model e pede previsões
function handleInput(e: Event) {
  const el = e.target as HTMLInputElement | null
  const val = el?.value ?? ''
  emit('update:modelValue', val)
  onInput(val)
}

const inputClasses = computed(() => {
  const classes = [
    'w-full',
    'text-sm',
    'rounded',
    'pl-10',
    'pr-3',
    'py-2',
    'mb-2',
    'border',
    'focus:outline-none',
    'focus:border-[3px]',
    'focus:border-[#a48900]',
  ]

  // borda por status
  switch (props.status) {
    case 'danger':
      classes.push('border-red-600 border-[2px]')
      break
    case 'success':
      classes.push('border-green-600')
      break
    case 'warning':
      classes.push('border-yellow-600')
      break
    case 'info':
      classes.push('border-blue-600')
      break
    default:
      classes.push('border-gray-500')
  }

  return classes.join(' ')
})

const feedbackColorClass = computed(() => {
  switch (props.status) {
    case 'danger':
      return 'text-red-600'
    case 'success':
      return 'text-green-600'
    case 'warning':
      return 'text-yellow-700'
    case 'info':
      return 'text-blue-600'
    default:
      return 'text-gray-500'
  }
})

const describedById = computed(() => (props.message ? 'inputmapa-feedback' : undefined))
</script>

<template>
  <div class="w-full mb-4 relative">
    <label class="block text-sm font-medium text-gray-700 mb-1">
      {{ label }}
    </label>

    <!-- ícone à esquerda -->
    <i class="fas fa-map-marker-alt absolute left-3 top-[35px] text-gray-400"></i>

    <input
      ref="inputRef"
      :value="modelValue"
      @input="handleInput"
      @focus="emit('focus')"   
      :class="inputClasses"
      :placeholder="placeholder"
      :aria-invalid="status === 'danger' ? 'true' : 'false'"
      :aria-describedby="describedById"
      autocomplete="off"
    />

    <!-- Dropdown de sugestões (agora controlado por nós, sem o widget legado) -->
    <ul
      v-if="predictions.length"
      class="absolute z-50 left-0 right-0 mt-1 bg-white border rounded shadow max-h-64 overflow-auto"
      role="listbox"
    >
      <li
        v-for="p in predictions"
        :key="p.place_id"
        class="px-3 py-2 text-sm hover:bg-gray-100 cursor-pointer"
        role="option"
        @click="selectPrediction(p)"
      >
        {{ p.description }}
      </li>
      <li v-if="loading" class="px-3 py-2 text-sm text-gray-500">Carregando…</li>
    </ul>

    <!-- feedback -->
    <small
      v-if="message"
      :id="describedById"
      class="text-sm italic text-white bg-[#e20000] p-1"
      :class="feedbackColorClass"
    >
      <i class="fas fa-times-circle" aria-hidden="true" v-if="status === 'danger'"></i>
      {{ message }}
    </small>
  </div>
</template>
