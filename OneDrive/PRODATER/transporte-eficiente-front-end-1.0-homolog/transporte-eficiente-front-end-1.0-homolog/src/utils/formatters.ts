import { maskCpf, maskTelefone } from './masks'

export const formatCpf = (value: string): string => {
  return maskCpf(value)
}

export const formatTelefone = (value: string): string => {
  return maskTelefone(value)
}

export const formatMoney = (e: Event) => {
  const input = e.target as HTMLInputElement
  const value = input.value.replace(/\D/g, '')
  if (!value) return (input.value = '')
  const numericValue = parseInt(value, 10) / 100
  input.value = numericValue.toLocaleString('pt-BR', {
    style: 'currency',
    currency: 'BRL',
    minimumFractionDigits: 2,
  })
}

export const formatDate = (value: string): string => {
  const onlyDigits = value.replace(/\D/g, '').slice(0, 8)
  if (onlyDigits.length <= 2) return onlyDigits
  else if (onlyDigits.length <= 4) return `${onlyDigits.slice(0, 2)}/${onlyDigits.slice(2)}`
  else return `${onlyDigits.slice(0, 2)}/${onlyDigits.slice(2, 4)}/${onlyDigits.slice(4)}`
}

export const formatCep = (value: string): string => {
  const digits = value.replace(/\D/g, '').slice(0, 8)
  if (digits.length <= 5) return digits
  return `${digits.slice(0, 5)}-${digits.slice(5, 8)}`
}
