import type { TabelaViagemRow } from './useListViagens'
import type { ViagemCardItem } from '@/components/cards/ViagemCard.vue'

export type ActionKey = 'ver' | 'editar'
type Row = TabelaViagemRow | ViagemCardItem
type MaybeWithId = { id?: unknown }

function extractId(row: Row): number | null {
  if ('id' in row && typeof row.id === 'number') return row.id
  if ('_raw' in row) {
    const raw = (row as ViagemCardItem)._raw as MaybeWithId
    if (typeof raw?.id === 'number') return raw.id
  }
  return null
}

export function useViagemActions() {
  function handleTableAction(payload: { action: ActionKey; row: Row; index?: number }) {
    const id = extractId(payload.row)
    if (!id) {
      console.warn('Ação ignorada: linha sem id', payload.row)
      return
    }

    switch (payload.action) {
      case 'ver':
        console.log('VER viagem', id, payload.row)
        break
      case 'editar':
        console.log('EDITAR viagem', id, payload.row)
        break
    }
  }

  return { handleTableAction }
}
