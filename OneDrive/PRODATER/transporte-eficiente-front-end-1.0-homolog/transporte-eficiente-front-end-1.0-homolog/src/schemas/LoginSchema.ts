import * as yup from 'yup'

export const loginSchema = yup.object({
  username: yup.string().required('Campo obrigatório.'),
  password: yup.string().required('Campo obrigatório.'),
  checked: yup
    .boolean()
    .oneOf([true], 'Campo obrigatório.')
})
