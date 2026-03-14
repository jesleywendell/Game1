<script setup lang="ts">
import { computed } from 'vue'

type Row = Record<string, unknown>

// Definição de coluna
type Column = {
  key: string
  label: string // título da coluna
  align?: 'left' | 'center' | 'right' // alinhamento do conteúdo
  headerAlign?: 'left' | 'center' | 'right' // alinhamento do cabeçalho
  width?: string // largura fixa (ex.: '150px', '20%')
  headerIcon?: string
  formatter?: (value: unknown, row: Row, index: number) => string | number
}

type Action = {
  key: string
  label?: string
  title?: string
  icon?: string
  disabled?: (row: Row) => boolean
}

const props = defineProps<{
  items: ReadonlyArray<Row>
  columns: ReadonlyArray<Column>

  page?: number
  pageSize?: number
  pageSizeOptions?: number[]
  totalItems?: number

  striped?: boolean
  condensed?: boolean
  loading?: boolean
  emptyText?: string

  actions?: Action[]
  actionsHeaderIcon?: string
  actionsHeaderLabel?: string

  showStatusStrip?: boolean
  statusKey?: string
  statusColorMap?: Record<string, string>
}>()

const emit = defineEmits<{
  (e: 'update:page', value: number): void
  (e: 'update:pageSize', value: number): void
  (e: 'row-click', row: Row, index: number): void
  (e: 'action', payload: { action: string; row: Row; index: number }): void
}>()

const page = computed({
  get: () => props.page ?? 1,
  set: (v: number) => emit('update:page', v),
})
const pageSize = computed({
  get: () => props.pageSize ?? 10,
  set: (v: number) => emit('update:pageSize', v),
})

const totalItems = computed(() => props.totalItems ?? props.items.length)
const totalPages = computed(() => Math.max(1, Math.ceil(totalItems.value / pageSize.value)))

// Itens exibidos na página atual
const pageItems = computed(() => {
  if (props.totalItems !== undefined && props.totalItems > props.items.length) {
    return props.items
  }
  const start = (page.value - 1) * pageSize.value
  return props.items.slice(start, start + pageSize.value)
})

function goTo(p: number) {
  if (p < 1) p = 1
  if (p > totalPages.value) p = totalPages.value
  page.value = p
}
function next() {
  goTo(page.value + 1)
}
function prev() {
  goTo(page.value - 1)
}

function handleRowClick(row: Row, idx: number) {
  emit('row-click', row, idx)
}
function onAction(actionKey: string, row: Row, idx: number) {
  emit('action', { action: actionKey, row, index: idx })
}

function getStatusClass(row: Row): string {
  const key = props.statusKey || 'status'
  const status = String((row as Row)[key] ?? '')
  const map = props.statusColorMap || {
    Agendada: 'bg-[--color-primary]',
    Cancelada: 'bg-[--color-error]',
    Executada: 'bg-[--color-secondary]',
  }
  return map[status] || 'bg-gray-300'
}
</script>

<template>
  <div class="br-table w-full border border-gray-200 rounded-md">
    <div class="overflow-x-auto">
      <table class="br-table w-full" :class="{ 'table-sm': condensed }">
        <thead>
          <tr>
            <!--coluna vazia-->
            <th v-if="showStatusStrip" class="p-0 w-1 bg-[--color-primary]"></th>
            <th
              v-for="col in columns"
              :key="col.key"
              :style="{ width: col.width || undefined }"
              :class="[
                'px-4 py-3 font-semibold text-white bg-[--color-primary] whitespace-nowrap',
                col.headerAlign ? `text-${col.headerAlign}` : 'text-center',
                'border-r border-gray-200 last:border-r-0',
              ]"
            >
              <slot :name="`header-${col.key}`" :label="col.label">
                <span class="inline-flex items-center justify-center gap-2">
                  <i v-if="col.headerIcon" :class="col.headerIcon" aria-hidden="true"></i>
                  <span>{{ col.label }}</span>
                </span>
              </slot>
            </th>

            <th
              v-if="actions?.length"
              class="px-4 py-3 font-semibold text-white bg-[--color-primary] text-center whitespace-nowrap"
            >
              <span class="inline-flex items-center justify-center gap-2">
                <i :class="props.actionsHeaderIcon || 'fas fa-cog'" aria-hidden="true"></i>
                <span>{{ props.actionsHeaderLabel || 'Ações' }}</span>
              </span>
            </th>
          </tr>
        </thead>

        <tbody>
          <tr v-if="loading">
            <td
              :colspan="columns.length + (actions?.length ? 1 : 0) + (showStatusStrip ? 1 : 0)"
              class="px-4 py-6 text-center"
            >
              Carregando…
            </td>
          </tr>

          <tr v-else-if="!pageItems.length">
            <td
              :colspan="columns.length + (actions?.length ? 1 : 0) + (showStatusStrip ? 1 : 0)"
              class="px-4 py-6 text-center"
            >
              {{ emptyText || 'Nenhum registro encontrado.' }}
            </td>
          </tr>

          <tr
            v-else
            v-for="(row, i) in pageItems"
            :key="i"
            :class="['hover:bg-[#eef3f7]', striped && i % 2 === 1 ? 'bg-[#f5f7f9]' : '']"
          >
          <!-- Coluna de status color -->
            <td v-if="showStatusStrip" class="p-0 w-1 border-b border-gray-200">
              <div :class="['h-full w-[5px]', getStatusClass(row)]" style="min-height: 64px"></div>
            </td>

            <td
              v-for="col in columns"
              :key="col.key"
              :class="[
                'px-4 py-3',
                'border-b border-gray-200 border-r last:border-r-0',
                col.align ? `text-${col.align}` : 'text-center',
              ]"
              @click="handleRowClick(row, i)"
            >
              <slot :name="`cell-${col.key}`" :row="row" :value="row[col.key]" :index="i">
                {{ col.formatter ? col.formatter(row[col.key], row, i) : (row[col.key] as any) }}
              </slot>
            </td>

            <td v-if="actions?.length" class="px-4 py-3 text-center border-b border-gray-200">
              <div class="flex items-center justify-center gap-3">
                <button
                  v-for="act in actions"
                  :key="act.key"
                  class="br-button circle small"
                  type="button"
                  :title="act.title || act.label"
                  :disabled="act.disabled?.(row)"
                  @click="onAction(act.key, row, i)"
                >
                  <i :class="act.icon || 'fas fa-ellipsis-h'" aria-hidden="true" />
                </button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Rodapé: Exibir X + paginação -->
    <div class="mt-3 flex items-center justify-between flex-wrap gap-2">
      <div class="flex items-center gap-2 ml-2 border-r border-gray-200 w-[100px]">
        <span class="text-sm">Exibir</span>
        <div class="br-select">
          <select
            class="br-input"
            :value="pageSize"
            @change="pageSize = Number(($event.target as HTMLSelectElement).value)"
          >
            <option v-for="s in pageSizeOptions || [5, 10, 50, 100]" :key="s" :value="s">
              {{ String(s).padStart(2, '0') }}
            </option>
          </select>
        </div>
      </div>
      <nav class="pagination-neutral flex items-center gap-2" aria-label="Paginação">
        <button
          class="br-button circle small"
          :disabled="page <= 1"
          @click="prev"
          aria-label="Anterior"
        >
          <i class="fas fa-chevron-left" aria-hidden="true"></i>
        </button>

        <button
          v-for="p in totalPages"
          :key="p"
          class="page-num"
          :class="{ active: p === page }"
          @click="goTo(p)"
          type="button"
        >
          {{ p }}
        </button>

        <button
          class="br-button circle small"
          :disabled="page >= totalPages"
          @click="next"
          aria-label="Próxima"
        >
          <i class="fas fa-chevron-right" aria-hidden="true"></i>
        </button>
      </nav>
    </div>
  </div>
</template>

<!--
//modelo de uso

<script>
const page = ref(1)
const pageSize = ref(4)

const viagens = ref([
  { codigo: 5580, origem: 'Prodater', destino: 'Teresina Shopping', dataHora: '08/08/25 - 10:00' },
  {
    codigo: 5580,
    origem: 'Encontro dos Rios',
    destino: 'Shopping Rio Poty',
    dataHora: '07/08/25 - 08:00',
  },
  {
    codigo: 5580,
    origem: 'Rua Chile 1167 Centro sul Teresina- PI',
    destino: 'Banco do Brasil',
    dataHora: '05/08/25 - 15:00',
  },
  { codigo: 5580, origem: 'iCev', destino: 'Teresina Shopping', dataHora: '04/08/25 - 14:00' },
  { codigo: 5580, origem: 'Local2', destino: 'Loja Shopping', dataHora: '04/08/25 - 14:00' },
  { codigo: 5580, origem: 'Local 3', destino: 'Poty Shopping', dataHora: '04/08/25 - 14:00' },
])

const columns = [
  { key: 'codigo', label: 'Código da Viagem', headerIcon: 'fas fa-hashtag', width: '180px'},
  { key: 'origemDestino', label: 'Origem  -  Destino', headerIcon: 'fas fa-route', headerAlign: 'center'  },
  { key: 'dataHora', label: 'Data - Hora', headerIcon: 'fas fa-calendar-alt', width: '180px' },
] as const

// mapeia dados para criar a coluna combinada "origemDestino"
const viagensCombinadas = computed(() =>
  viagens.value.map((v) => ({ ...v, origemDestino: `${v.origem}  -  ${v.destino}` })),
)

function onAction({ action, row }: { action: string; row: Record<string, unknown> }) {
  if (action === 'ver') console.log('ver', row)
  if (action === 'editar') console.log('editar', row)
}
</script>

<template>
  <h1>Tabela</h1>
    <BaseTable
      :items="viagensCombinadas"
      :columns="columns"
      v-model:page="page"
      v-model:pageSize="pageSize"
      :pageSizeOptions="[4, 8, 12]"
      :striped="true"
      :condensed="false"
      :actionsHeaderIcon="'fas fa-cog'"
      :actionsHeaderLabel="'Ações'"
      :actions="[
        { key: 'ver', icon: 'fas fa-eye', title: 'Ver' },
        { key: 'editar', icon: 'fas fa-pen', title: 'Editar' },
      ]"
      @action="onAction"
    />

-->
