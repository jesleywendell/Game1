import * as yup from 'yup'
import { cpfRegex, phoneRegex, dateBRRegex } from '@/utils/constants/regex'
import { isValidCpf, isValidDateBRStrict } from '@/utils/validators'

export const BeneficiarioSchema = yup.object({
  // Identificação do beneficiário
  cpf: yup
    .string()
    .trim()
    .matches(cpfRegex, { message: 'CPF inválido (formato)', excludeEmptyString: true })
    .test('cpf-valido', 'CPF inválido (dígitos incorretos)', (val) => !val || isValidCpf(val))
    .required('CPF obrigatório'),
  nome: yup.string().required('Nome obrigatório'),
  codigo: yup.string().required('Código obrigatório'),
  nascimento: yup
    .string()
    .required('Data obrigatória')
    .matches(dateBRRegex, { message: 'Data inválida (use dd/mm/aaaa)', excludeEmptyString: true })
    .test('data-real', 'Data inválida', (val) => !val || isValidDateBRStrict(val)),

  // Contatos
  fone: yup.string().matches(phoneRegex, 'Telefone inválido').required('Telefone obrigatório'),
  fone2: yup
    .string()
    .matches(phoneRegex, { message: 'Telefone inválido', excludeEmptyString: true })
    .notRequired(),
  // Responsável
  necessita_acompanhante: yup.boolean().required('Campo obrigatório'),
  tutor: yup.string().when('necessita_acompanhante', {
    is: true,
    then: (s) => s.required('Tutor obrigatório'),
    otherwise: (s) => s.optional().strip(),
  }),
  tutor_parentesco: yup.string().when('necessita_acompanhante', {
    is: true,
    then: (s) => s.required('Parentesco obrigatório'),
    otherwise: (s) => s.optional().strip(),
  }),
  tutor_cpf: yup
    .string()
    .trim()
    .matches(cpfRegex, { message: 'CPF inválido (formato)', excludeEmptyString: true })
    .test('cpf-valido', 'CPF inválido (dígitos incorretos)', (val) => !val || isValidCpf(val))
    .when('necessita_acompanhante', {
      is: true,
      then: (s) => s.required('CPF do tutor obrigatório'),
      otherwise: (s) => s.optional().strip(),
    }),
})
