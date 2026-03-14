// Função para remover todos os caracteres não numéricos de um CPF
export function cleanCpf(cpf: string): string {
  return cpf.replace(/\D/g, '')
}

// Função para remover todos os caracteres não numéricos de um telefone
export function cleanTelefone(telefone: string): string {
  return telefone.replace(/\D/g, '')
}

// Função para converter datas no formato dd/mm/yyyy para ISO yyyy-mm-dd
export function convertDate(date: string): string {
  const [day, month, year] = date.split('/')
  if (!day || !month || !year) return date // fallback se o formato estiver errado
  return `${year}-${month.padStart(2, '0')}-${day.padStart(2, '0')}`
}
