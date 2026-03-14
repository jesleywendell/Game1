import * as yup from 'yup'
import { cepRegex } from '@/utils/constants/regex'

export const EnderecoSchema = yup.object({
  tipo: yup
    .string()
    .oneOf(['Residencial', 'Comercial', 'Outro'], 'Tipo inválido')
    .required('Tipo do endereço obrigatório'),
  cep: yup
    .string()
    .trim()
    .matches(cepRegex, { message: 'CEP inválido', excludeEmptyString: true })
    .required('CEP obrigatório'),
  uf: yup.string().required('Estado obrigatório'),
  municipio: yup.string().required('Cidade obrigatória'),
  bairro: yup.string().required('Bairro obrigatório'),
  logradouro: yup.string().required('Logradouro obrigatório'),
  numero: yup.string().required('Número obrigatório'),
  complemento: yup.string().notRequired(),
})
