<script setup lang="ts">
import { ref, watch, computed, onMounted } from 'vue'
import * as yup from 'yup'
import BaseButton from '@/components/buttons/BaseButton.vue'
import InputMapa from '@/components/fields/InputMapa.vue'
import BaseAlert from '@/components/messages/BaseAlert.vue'
import BaseSelect from '@/components/fields/BaseSelect.vue'
import { agendarViagemSchema, type TAgendarViagemForm } from '@/schemas/AgendamentoViagemSchema'
import { useCreateViagem } from '@/composables/viagens/useCreateViagem'
import type { IViagemRequest } from '@/types/models/IViagemRequest'
// import { useUserStore } from '@/stores/user'

// props com coords (vêm do mapa via view)
const props = defineProps<{
  prefillBeneficiario?: string
  pending?: boolean
  origemCoords?: [number, number] | undefined
  destinoCoords?: [number, number] | undefined
}>()

// mutation acopla API ao form
const { mutateAsync: createViagemMutation, isPending } = useCreateViagem()
// const userStore = useUserStore()

const form = ref<TAgendarViagemForm>({
  origem: '',
  destino: '',
  data: '',
  horario: '',
  beneficiario: props.prefillBeneficiario ?? '',
  motivo: '',
})

const errors = ref<Record<keyof TAgendarViagemForm, string>>({
  origem: '',
  destino: '',
  data: '',
  horario: '',
  beneficiario: '',
  motivo: '',
  observacoes: '',
})

// Alertas
const showAlert = ref(false)
const alertStatus = ref<'success' | 'danger' | 'info' | 'warning' | ''>('')
const alertMessage = ref('')

function showToast(status: 'success' | 'danger' | 'info' | 'warning', message: string) {
  alertStatus.value = status
  alertMessage.value = message
  showAlert.value = true
}

// horario temporario. vai vir do back
type Option = { label: string; value: string }
const horariosOptions = ref<Option[]>([])

function loadHorariosDisponiveis() {
  // mock simples por enquanto
  horariosOptions.value = [
    { label: '06:00', value: '06:00' },
    { label: '10:00', value: '10:00' },
    { label: '12:00', value: '12:00' },
    { label: '14:00', value: '14:00' },
    { label: '15:00', value: '15:00' },
    { label: '18:00', value: '18:00' },
  ]
}

onMounted(() => {
  loadHorariosDisponiveis()
})

const emit = defineEmits<{
  (e: 'update-origem', coords: [number, number] | undefined): void
  (e: 'update-destino', coords: [number, number] | undefined): void
  (e: 'ok'): void
  (e: 'focus-field', field: 'origem' | 'destino'): void
}>()

// setters expostos p/ o pai escrever nos campos
function setEnderecoOrigem(texto: string) {
  form.value.origem = texto
  errors.value.origem = ''
}
function setEnderecoDestino(texto: string) {
  form.value.destino = texto
  errors.value.destino = ''
}
defineExpose({ setEnderecoOrigem, setEnderecoDestino })

watch(
  () => props.prefillBeneficiario,
  (val) => {
    form.value.beneficiario = val ?? ''
    errors.value.beneficiario = ''
  },
  { immediate: true },
)

const isSubmitting = ref(false)
const isBusy = computed(() => isSubmitting.value || !!props.pending || isPending.value)

function isYupValidationError(e: unknown): e is yup.ValidationError {
  return e instanceof yup.ValidationError || (typeof e === 'object' && e !== null && 'inner' in e)
}

const motivosOptions = [
  { label: 'Saúde', value: 'saude' },
  { label: 'Trabalho', value: 'trabalho' },
  { label: 'Educação', value: 'educacao' },
  { label: 'Outros', value: 'outros' },
]

// Monta o campo de data e hora
function buildLocalIso(dateYMD: string, timeHM: string): string {
  const tzMinutes = -new Date().getTimezoneOffset()
  const sign = tzMinutes >= 0 ? '+' : '-'
  const abs = Math.abs(tzMinutes)
  const oh = String(Math.floor(abs / 60)).padStart(2, '0')
  const om = String(abs % 60).padStart(2, '0')
  return `${dateYMD}T${timeHM}:00${sign}${oh}:${om}`
}

const handleSubmit = async () => {
  showAlert.value = false
  isSubmitting.value = true
  ;(Object.keys(errors.value) as (keyof TAgendarViagemForm)[]).forEach(
    (k) => (errors.value[k] = ''),
  )

  try {
    await agendarViagemSchema.validate(form.value, { abortEarly: false })

    if (!props.origemCoords || !props.destinoCoords) {
      showToast('danger', 'Selecione origem e destino no mapa.')
      return
    }

    // 1) beneficiário (temporário: ID fixo enquanto o back não envia no token)
    const beneficiario_id = 4
    // quando o back enviar o id do usuário no token:
    // const beneficiario_id = Number(userStore.user?.id)
    // if (!Number.isFinite(beneficiario_id)) {
    //   showToast('danger', 'Identificador do beneficiário inválido.')
    //   return
    // }

    // 2) coordenadas obrigatórias
    if (!props.origemCoords || !props.destinoCoords) {
      showToast('danger', 'Selecione origem e destino no mapa.')
      return
    }
    const [oLat, oLng] = props.origemCoords
    const [dLat, dLng] = props.destinoCoords

    // 3) data+hora → ISO (UTC)
    const data_hora_agendada = buildLocalIso(form.value.data, form.value.horario)
    
    // 4) monta o payload conforme back
    const payload: IViagemRequest = {
      beneficiario_id,
      data_hora_agendada,
      xy_origem: `${oLat},${oLng}`,
      endereco_origem: form.value.origem,
      xy_destino: `${dLat},${dLng}`,
      endereco_destino: form.value.destino,
      motivo: form.value.motivo as IViagemRequest['motivo'],
      // observacoes: form.value.observacoes?.trim(), // se colocar o campo depois
    }

    await createViagemMutation(payload)
    showToast('success', 'Solicitação enviada com sucesso!')
    emit('ok')

    form.value = {
      origem: '',
      destino: '',
      data: '',
      horario: '',
      motivo: '',
      beneficiario: String(beneficiario_id),
      // observacoes: '', // quando existir no form
    }
  } catch (err: unknown) {
    if (isYupValidationError(err)) {
      const ve = err as yup.ValidationError
      for (const e of ve.inner) {
        if (e.path) errors.value[e.path as keyof TAgendarViagemForm] = e.message
      }
      const global = ve.inner.find((e) => !e.path)
      if (global?.message) showToast('danger', global.message)
    } else {
      const msg = err instanceof Error ? err.message : 'Falha ao solicitar a viagem.'
      showToast('danger', msg)
    }
  } finally {
    isSubmitting.value = false
  }
}

// datas disponiveis
function addDays(base: Date, days: number) {
  const d = new Date(base)
  d.setDate(d.getDate() + days)
  return d
}
function formatYYYYMMDD(d: Date) {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}
function formatDDMMYYYY(d: Date) {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${day}/${m}/${y}`
}

//  Gera as datas disponíveis conforme regra:
//  - Sex (5): D+1, D+2, D+3
//  - Sáb (6): D+1, D+2
//  - Dom (0): D+1
//  - Seg–Qui: D+1
const availableDateOptions = computed<Option[]>(() => {
  const today = new Date()
  const dow = today.getDay() // 0=Dom .. 6=Sáb

  const deltas =
    dow === 5
      ? [1, 2, 3] // sexta
      : dow === 6
        ? [1, 2] // sábado
        : [1] // domingo ou seg–qui

  return deltas.map((d) => {
    const date = addDays(today, d)
    return {
      label: formatDDMMYYYY(date), // o que aparece no select
      value: formatYYYYMMDD(date), // o que envia pro back (YYYY-MM-DD)
    }
  })
})
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <div class="flex flex-col items-center">
      <InputMapa
        v-model="form.destino"
        label="Para onde você vai?"
        placeholder="Digite o seu destino"
        @focus="emit('focus-field', 'destino')"
        @placeSelected="
          (place) => {
            form.destino = place?.formatted_address || form.destino
            const loc = place?.geometry?.location
            if (loc) {
              const coords: [number, number] = [loc.lat(), loc.lng()]
              emit('update-destino', coords)
            }
            errors.destino = ''
          }
        "
        :status="errors.destino ? 'danger' : ''"
        :message="errors.destino"
      />
      <InputMapa
        v-if="form.destino"
        v-model="form.origem"
        label="De onde você quer sair?"
        placeholder="Digite o local de partida"
        @focus="emit('focus-field', 'origem')"
        @placeSelected="
          (place) => {
            form.origem = place?.formatted_address || form.origem
            const loc = place?.geometry?.location
            if (loc) {
              const coords: [number, number] = [loc.lat(), loc.lng()]
              emit('update-origem', coords)
            }
            errors.origem = ''
          }
        "
        :status="errors.origem ? 'danger' : ''"
        :message="errors.origem"
      />

      <!-- Separador -->
      <div v-if="form.origem" class="w-full border-b border-gray-300 mb-2"></div>

      <BaseSelect
        v-if="form.origem"
        v-model="form.data"
        label="Data da Viagem"
        placeholder="Selecione a data"
        :options="availableDateOptions"
        required
        class="mb-3 w-full"
        icon="far fa-calendar-alt"
        :status="errors.data ? 'danger' : ''"
        :message="errors.data"
      />

      <BaseSelect
        v-if="form.data"
        v-model="form.horario"
        label="Horário da Viagem"
        placeholder="Selecione um horário"
        :options="horariosOptions"
        required
        icon="far fa-clock"
        class="mb-3 w-full"
        :status="errors.horario ? 'danger' : ''"
        :message="errors.horario"
      />

      <BaseSelect
        v-if="form.horario"
        v-model="form.motivo"
        label="Motivo da Viagem"
        :options="motivosOptions"
        placeholder="Selecione o motivo"
        icon="far fa-clipboard"
        required
        :status="errors.motivo ? 'danger' : ''"
        :message="errors.motivo"
      />

      <BaseButton
        v-if="form.motivo"
        type="submit"
        variant="primary"
        :disabled="isBusy"
        class="mt-2"
      >
        {{ isBusy ? 'Enviando…' : 'Solicitar Viagem' }}
      </BaseButton>
    </div>
  </form>

  <teleport to="body">
    <BaseAlert
      v-if="showAlert"
      :status="alertStatus"
      :message="alertMessage"
      @close="showAlert = false"
    />
  </teleport>
</template>
