export type StatusViagem = 'Agendada' | 'Cancelada' | 'Executada'

export interface IViagem {
  id: number
  status: StatusViagem
  observacoes: string | null
  created: string
  updated: string
  deleted: string | null
  user_id: string
  beneficiario_id: number
  data_hora_agendada: string
  xy_origem: string
  endereco_origem: string
  xy_destino: string
  endereco_destino: string
}
