export type TEnderecoStatus = 'Ativo' | 'Inativo'

export interface IEndereco {
  tipo: string
  cep: string
  uf: string
  municipio: string
  logradouro: string
  bairro: string
  numero: string
  complemento?: string
  referencia?: string
  status?: TEnderecoStatus
  observacoes?: string
  beneficiario_id?: number
}
