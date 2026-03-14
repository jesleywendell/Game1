// Validação cpf válido
export const cpfFormatValidator = (cpf: string): boolean => {
  return /^\d{3}\.\d{3}\.\d{3}-\d{2}$/.test(cpf)
}

export const cpfDigitValidator = (cpf: string): boolean => {
  const cleanCpf = cpf.replace(/\D/g, '')
  if (cleanCpf.length !== 11 || /^(\d)\1+$/.test(cleanCpf)) return false

  const validateDigit = (base: number): number => {
    let sum = 0
    for (let i = 0; i < base; i++) {
      sum += parseInt(cleanCpf.charAt(i)) * (base + 1 - i)
    }
    const remainder = sum % 11
    return remainder < 2 ? 0 : 11 - remainder
  }

  return validateDigit(9) === parseInt(cleanCpf[9]) && validateDigit(10) === parseInt(cleanCpf[10])
}

export const isValidCpf = (cpf: string): boolean => {
  return cpfFormatValidator(cpf) && cpfDigitValidator(cpf)
}

export const isValidCpfFormat = (cpf: string): boolean | string => {
  return cpfFormatValidator(cpf) || 'CPF deve estar no formato xxx.xxx.xxx-xx'
}

export const isValidCpfDigits = (cpf: string): boolean | string => {
  if (!cpfFormatValidator(cpf)) return true
  return cpfDigitValidator(cpf) || 'CPF inválido (dígitos verificadores incorretos)'
}

// valida se dd/mm/aaaa é uma data real e “coerente”
export const isValidDateBRStrict = (
  dateStr: string,
  opts: { minYear?: number; maxYear?: number; allowFuture?: boolean } = {}
): boolean => {
  if (!dateStr) return false
  const { minYear = 1900, maxYear = new Date().getFullYear(), allowFuture = false } = opts

  const m = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(dateStr)
  if (!m) return false

  const day = Number(m[1])
  const month = Number(m[2])
  const year = Number(m[3])

  if (month < 1 || month > 12) return false
  if (year < minYear || year > maxYear) return false

  const d = new Date(year, month - 1, day)
  const isSame =
    d.getFullYear() === year && d.getMonth() === month - 1 && d.getDate() === day
  if (!isSame) return false

  if (!allowFuture) {
    const today = new Date()
    // zera horas para comparar só a data
    today.setHours(0, 0, 0, 0)
    d.setHours(0, 0, 0, 0)
    if (d > today) return false
  }

  return true
}
