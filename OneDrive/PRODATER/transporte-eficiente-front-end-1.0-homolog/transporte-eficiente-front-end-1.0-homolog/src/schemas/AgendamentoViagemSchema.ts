import * as yup from 'yup'

export type TAgendarViagemForm = {
  origem: string
  destino: string
  data: string
  horario: string
  beneficiario?: string
  motivo: '' | 'saude' | 'trabalho' | 'educacao' | 'outros'
  observacoes?: string
}

// data/tempo (usar horário local)
function toLocalDateOnly(d: Date): { y: number; m: number; day: number } {
  return { y: d.getFullYear(), m: d.getMonth(), day: d.getDate() }
}

function formatYYYYMMDD(d: Date): string {
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

function parseDateYMD(dateStr: string): Date | null {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) return null
  const [y, m, d] = dateStr.split('-').map(Number)
  const dt = new Date(y, (m ?? 1) - 1, d ?? 1, 12, 0, 0, 0) // 12:00 p/ evitar fuso alterar dia
  if (Number.isNaN(dt.getTime())) return null
  const { y: yy, m: mm, day } = toLocalDateOnly(dt)
  if (yy !== y || mm !== m - 1 || day !== d) return null
  return dt
}

//  Regra da data permitida:
//  Se HOJE for sexta (getDay() === 5): pode sábado (+1), domingo (+2) ou segunda (+3)
//  Senão: somente amanhã (+1)

function isAllowedDate(dateStr: string): boolean {
  const target = parseDateYMD(dateStr)
  if (!target) return false

  const today = new Date()
  const todayStr = formatYYYYMMDD(today)
  const todayMid = parseDateYMD(todayStr)! // normaliza para comparar só a data
  const dow = todayMid.getDay() // 0=domingo ... 6=sábado

  const allowed = new Set<string>()
  const plus = (days: number) => {
    const d = new Date(todayMid)
    d.setDate(d.getDate() + days)
    return formatYYYYMMDD(d)
  }

  if (dow === 5) {
    // sexta: sábado, domingo, segunda
    allowed.add(plus(1))
    allowed.add(plus(2))
    allowed.add(plus(3))
  } else if (dow === 6) {
    // sábado: domingo, segunda
    allowed.add(plus(1))
    allowed.add(plus(2))
  } else if (dow === 0) {
    // domingo: apenas segunda
    allowed.add(plus(1))
  } else {
    // seg–qui: apenas amanhã
    allowed.add(plus(1))
  }

  return allowed.has(formatYYYYMMDD(target))
}

export const agendarViagemSchema: yup.ObjectSchema<TAgendarViagemForm> = yup.object({
  origem: yup.string().trim().required('Partida é obrigatória'),
  destino: yup.string().trim().required('Destino é obrigatório'),
  data: yup
    .string()
    .required('Data obrigatória')
    .matches(/^\d{4}-\d{2}-\d{2}$/, 'Data inválida')
    .test('data-permitida', 'Escolha uma data disponivel.', (value) =>
      value ? isAllowedDate(value) : false,
    ),
  horario: yup.string().trim().required('Horário obrigatório'),
  beneficiario: yup.string().optional(),
  motivo: yup
    .string()
    .oneOf(['saude', 'trabalho', 'educacao', 'outros'], 'Motivo inválido')
    .required('Motivo é obrigatório'),
  observacoes: yup.string().max(500).optional(),
})
