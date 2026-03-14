export interface IBeneficiario {
  id?: number
  cpf: string
  codigo: string
  nome: string
  nascimento: string
  fone: string
  fone2?: string

  contato_sos_nm?: string
  contato_sos_fone?: string
  contato_sos2_nm?: string
  contato_sos2_fone?: string

  necessita_acompanhante: boolean
  tutor_cpf?: string
  tutor?: string
  tutor_parentesco?: string

  observacoes?: string
  status?: string
}
