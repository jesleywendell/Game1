export const maskCpf = (value: string): string => {
  const cpfDigits = value.replace(/\D/g, '').slice(0, 11)
  return cpfDigits.replace(
    /(\d{3})(\d{3})(\d{3})(\d{0,2})/,
    (_, p1, p2, p3, p4) => `${p1}.${p2}.${p3}${p4 ? '-' + p4 : ''}`,
  )
}

export const maskTelefone = (value: string): string => {
  const digits = value.replace(/\D/g, '').slice(0, 11)
  if (digits.length <= 2) return digits
  if (digits.length <= 6) return `(${digits.slice(0, 2)}) ${digits.slice(2)}`
  if (digits.length <= 10) return `(${digits.slice(0, 2)}) ${digits.slice(2, 6)}-${digits.slice(6)}`
  return `(${digits.slice(0, 2)}) ${digits.slice(2, 7)}-${digits.slice(7)}`
}
