<script setup lang="ts">
import { computed } from 'vue'

type Status = 'Agendada' | 'Cancelada' | 'Executada'

export type ViagemCardItem = {
  id: number
  origem: string
  destino: string
  dataHora: string
  status?: Status
  _raw?: unknown
}

const props = defineProps<{
  items: ViagemCardItem[]
  showActions?: boolean

  /** paginação controlada de fora (server-side) */
  page: number
  pageSize: number
  totalItems: number
  pageSizeOptions?: number[]
}>()

const emit = defineEmits<{
  (e: 'action', payload: { action: 'ver' | 'editar'; row: ViagemCardItem }): void
  (e: 'update:page', v: number): void
  (e: 'update:pageSize', v: number): void
}>()

const sizeOptions = computed(() => props.pageSizeOptions ?? [10, 20, 50])
const totalPages = computed(() => Math.max(1, Math.ceil((props.totalItems || 0) / (props.pageSize || 1))))

function prevPage() {
  emit('update:page', Math.max(1, props.page - 1))
}
function nextPage() {
  emit('update:page', Math.min(totalPages.value, props.page + 1))
}

function stripColor(s?: Status) {
  return (
    {
      Agendada: 'bg-[--color-primary]',
      Cancelada: 'bg-[--color-error]',
      Executada: 'bg-[--color-secondary]',
    }[s ?? 'Agendada'] || 'bg-[--color-primary]'
  )
}
</script>

<template>
  <div class="grid gap-3">
    <!-- cards da página-->
    <article
      v-for="card in items"
      :key="card.id"
      class="relative flex gap-3 rounded-br-lg rounded-tr-lg border border-gray-200 shadow-sm pr-3 py-3 overflow-hidden"
    >
      <!-- borda colorida lateral -->
      <div class="absolute inset-y-0 left-0 w-[8px]" :class="stripColor(card.status)"></div>

      <div class="w-full pl-4 grid grid-cols-[1fr,auto] gap-4">
        <div class="min-w-0">
          <div class="mb-3">
            <span class="text-[12px] tracking-[.2em] text-gray-700 font-semibold whitespace-nowrap">
              {{ card.dataHora.toUpperCase() }}
            </span>
          </div>

          <div class="space-y-2 text-[15px] text-gray-900">
            <div class="flex items-center gap-2">
              <i class="fas fa-location-arrow text-gray-600"></i>
              <span class="truncate">{{ card.origem }}</span>
            </div>
            <div class="flex items-center gap-2">
              <i class="fas fa-location-dot text-gray-600"></i>
              <span class="truncate">{{ card.destino }}</span>
            </div>
          </div>
        </div>

        <div class="flex flex-col justify-between items-end self-stretch min-w-[110px]">
          <div class="text-center leading-none"></div>

          <div v-if="showActions" class="flex items-center mt-4">
            <button
              class="br-button circle !h-8 !w-8 !p-0"
              type="button"
              title="Ver"
              aria-label="Ver"
              @click="emit('action', { action: 'ver', row: card })"
            >
              <i class="fas fa-eye" aria-hidden="true"></i>
            </button>
            <button
              class="br-button circle !h-8 !w-8 !p-0"
              type="button"
              title="Editar"
              aria-label="Editar"
              @click="emit('action', { action: 'editar', row: card })"
            >
              <i class="fas fa-pen" aria-hidden="true"></i>
            </button>
          </div>
        </div>
      </div>
    </article>

    <div class="flex items-center justify-between mt-2">
      <div class="flex items-center gap-2">
        <span class="text-sm text-gray-700">Exibir</span>
        <select
          class="br-input text-sm border rounded px-2 py-1"
          :value="pageSize"
          @change="emit('update:pageSize', Number(($event.target as HTMLSelectElement).value))"
        >
          <option v-for="n in sizeOptions" :key="n" :value="n">{{ n }}</option>
        </select>
      </div>

      <div class="flex items-center gap-2">
        <button
          class="br-button circle small"
          type="button"
          :disabled="page <= 1"
          @click="prevPage"
          aria-label="Página anterior"
        >
          <i class="fas fa-angle-left" aria-hidden="true"></i>
        </button>

        <span class="text-sm text-gray-700">{{ page }} / {{ totalPages }}</span>

        <button
          class="br-button circle small"
          type="button"
          :disabled="page >= totalPages"
          @click="nextPage"
          aria-label="Próxima página"
        >
          <i class="fas fa-angle-right" aria-hidden="true"></i>
        </button>
      </div>
    </div>

    <p v-if="!items?.length" class="text-sm text-gray-600">Nenhum registro.</p>
  </div>
</template>
