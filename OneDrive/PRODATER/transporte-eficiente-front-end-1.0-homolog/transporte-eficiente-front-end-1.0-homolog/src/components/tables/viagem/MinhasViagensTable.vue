<script setup lang="ts">
import { computed, ref, toRef } from 'vue'
import BaseTable from '@/components/tables/BaseTable.vue'
import ViagemCard from '@/components/cards/ViagemCard.vue'
import { useListViagens, type TabelaViagemRow } from '@/composables/viagens/useListViagens'
import type { ViagemCardItem } from '@/components/cards/ViagemCard.vue'

type ActionKey = 'ver' | 'editar'

type BaseTableActionPayload = {
  action: string
  row: unknown
  index: number
}

const props = defineProps<{
  beneficiarioId?: number
  initialPageSize?: number
}>()

const emit = defineEmits<{
  (
    e: 'action',
    payload: { action: ActionKey; row: TabelaViagemRow | ViagemCardItem; index: number },
  ): void
}>()

const page = ref(1)
const pageSize = ref(props.initialPageSize ?? 10)

const { rows, items, totalItems, isLoading } = useListViagens({
  page,
  pageSize,
  beneficiarioId: toRef(props, 'beneficiarioId'),
})

// colunas da tabela (desktop)
const columns = [
  {
    key: 'dataHora',
    label: 'Data - Hora',
    headerIcon: 'fas fa-calendar-alt',
    width: '180px',
    align: 'center',
  },
  {
    key: 'origemDestino',
    label: 'Origem  -  Destino',
    headerIcon: 'fas fa-route',
    headerAlign: 'center',
  },
] as const

type Status = NonNullable<ViagemCardItem['status']>
function toStatus(s: unknown): Status {
  return s === 'Agendada' || s === 'Cancelada' || s === 'Executada' ? s : 'Agendada'
}

// map para os cards
const cardItems = computed<ViagemCardItem[]>(() =>
  items.value.map((v) => ({
    id: v.id,
    origem: v.endereco_origem,
    destino: v.endereco_destino,
    dataHora: new Date(v.data_hora_agendada).toLocaleString('pt-BR', {
      hour: '2-digit',
      minute: '2-digit',
      day: '2-digit',
      month: '2-digit',
      year: '2-digit',
    }),
    status: toStatus((v as unknown as { status?: unknown }).status),
    _raw: v,
  })),
)

function onActionTable(payload: BaseTableActionPayload) {
  const act: ActionKey =
    payload.action === 'ver' || payload.action === 'editar' ? payload.action : 'ver'
  const row = payload.row as TabelaViagemRow
  emit('action', { action: act, row, index: payload.index })
}

function onActionCard(payload: { action: ActionKey; row: ViagemCardItem; index?: number }) {
  emit('action', { action: payload.action, row: payload.row, index: payload.index ?? 0 })
}
</script>

<template>
  <!-- DESKTOP -->
  <div class="hidden md:block">
    <BaseTable
      :items="rows"
      :columns="columns"
      v-model:page="page"
      v-model:pageSize="pageSize"
      :totalItems="totalItems"
      :pageSizeOptions="[10, 20, 50]"
      :striped="true"
      :condensed="false"
      :loading="isLoading"
      :showStatusStrip="true"
      statusKey="status"
      :statusColorMap="{
        Agendada: 'bg-[--color-primary]',
        Cancelada: 'bg-[--color-error]',
        Executada: 'bg-[--color-secondary]',
      }"
      :actions="[
        { key: 'ver', icon: 'fas fa-eye', title: 'Ver' },
        { key: 'editar', icon: 'fas fa-pen', title: 'Editar' },
      ]"
      @action="onActionTable"
    />
  </div>

  <!-- MOBILE  -->
  <div class="grid gap-3 md:hidden">
    <div class="md:hidden">
      <ViagemCard
        :items="cardItems"
        :showActions="true"
        v-model:page="page"
        v-model:pageSize="pageSize"
        :totalItems="totalItems ?? 0"
        :pageSizeOptions="[5, 10, 20]"
        @action="onActionCard"
      />
    </div>
  </div>
</template>
