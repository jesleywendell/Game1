import { computed, ref, watch, type Ref } from 'vue'
import { useQuery, keepPreviousData } from '@tanstack/vue-query'
import type { IViagem, StatusViagem } from '@/types/models/IViagem'
import {
  listViagens,
  type ListViagensParams,
  type ListResponse,
} from '@/services/api/viagens/listViagens'

function formatBrDateTime(iso: string): string {
  const d = new Date(iso)
  const dd = String(d.getDate()).padStart(2, '0')
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const yy = String(d.getFullYear()).slice(-2)
  const hh = String(d.getHours()).padStart(2, '0')
  const mi = String(d.getMinutes()).padStart(2, '0')
  return `${dd}/${mm}/${yy} - ${hh}:${mi}`
}

export interface TabelaViagemRow extends Record<string, unknown> {
  codigo: number
  origemDestino: string
  dataHora: string
  status: StatusViagem
  _raw: IViagem
}

export function useListViagens(opts: {
  page: Ref<number>
  pageSize: Ref<number>
  beneficiarioId?: Ref<number | undefined>
}) {
  const query = useQuery<ListResponse>({
    queryKey: [
      'viagens',
      () => opts.page.value,
      () => opts.pageSize.value,
      () => opts.beneficiarioId?.value,
    ],
    queryFn: async () => {
      const skip = (opts.page.value - 1) * opts.pageSize.value
      const limit = opts.pageSize.value + 1
      const params: ListViagensParams = {
        skip,
        limit,
        beneficiario_id: opts.beneficiarioId?.value,
      }
      return await listViagens(params)
    },
    placeholderData: keepPreviousData,
  })

  // Lista ORDENADA por data/hora mais recente primeiro
  const ordered = computed<IViagem[]>(() => {
    const arr = (query.data.value ?? []).slice()
    arr.sort(
      (a, b) =>
        new Date(b.data_hora_agendada).getTime() - new Date(a.data_hora_agendada).getTime(),
    )
    return arr
  })

  const hasNext = computed<boolean>(() => ordered.value.length > opts.pageSize.value)

  // Itens exibidos na página (já ordenados)
  const pagedItems = computed<IViagem[]>(() => ordered.value.slice(0, opts.pageSize.value))

  const currentTotalItems = computed<number>(() => {
    return (
      (opts.page.value - 1) * opts.pageSize.value +
      pagedItems.value.length +
      (hasNext.value ? 1 : 0)
    )
  })

  const lastStableTotalItems = ref(0)
  watch(
    [() => query.isFetching.value, currentTotalItems],
    ([fetching]) => {
      if (!fetching) {
        lastStableTotalItems.value = currentTotalItems.value
      }
    },
    { immediate: true },
  )

  const totalItems = computed<number>(() => {
    return query.isFetching.value ? lastStableTotalItems.value : currentTotalItems.value
  })

  const rows = computed<ReadonlyArray<TabelaViagemRow>>(() =>
    pagedItems.value.map((v) => ({
      codigo: v.id,
      origemDestino: `${v.endereco_origem}  -  ${v.endereco_destino}`,
      dataHora: formatBrDateTime(v.data_hora_agendada),
      status: v.status,
      _raw: v,
    })),
  )

  return {
    rows,
    items: pagedItems,   // use nos cards mobile
    totalItems,          // número estável p/ paginação
    isLoading: query.isLoading,
    isFetching: query.isFetching,
    refetch: query.refetch,
  }
}
