export interface IViagemRequest {
  beneficiario_id: number
  data_hora_agendada: string
  xy_origem: string
  endereco_origem: string
  xy_destino: string
  endereco_destino: string
  status?: 'Agendada'
  observacoes?: string
  motivo: 'saude' | 'trabalho' | 'educacao' | 'outros'
}

export interface IViagemResponse {
  id: string
  mensagem?: string
}
