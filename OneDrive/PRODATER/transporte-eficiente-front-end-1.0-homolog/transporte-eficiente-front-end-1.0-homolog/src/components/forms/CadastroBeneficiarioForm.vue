<script setup lang="ts">
import { ref, watch } from 'vue'
import AcordionCard from '@/components/accordions/BaseAccordion.vue'
import BaseInput from '@/components/fields/BaseInput.vue'
import BaseSelect from '@/components/fields/BaseSelect.vue'
import BaseButton from '@/components/buttons/BaseButton.vue'
import BaseAlert from '../messages/BaseAlert.vue'
import FormGridLayout from '@/layouts/FormGrid.layout.vue'
import { BeneficiarioSchema } from '../../schemas/BeneficiarioSchema'
import { useCreateBeneficiario } from '@/composables/beneficiarios/useCreateBeneficiario'
import { EnderecoSchema } from '@/schemas/EnderecoSchema'
import { useCreateEndereco } from '@/composables/enderecos/useCreateEndereco'
import { formatCpf, formatTelefone, formatDate, formatCep } from '@/utils/formatters'
import { cleanCpf, cleanTelefone, convertDate } from '@/utils/cleans'

const form = ref({
  cpf: '',
  codigo: '',
  nome: '',
  nascimento: '',
  fone: '',
  fone2: '',
  cep: '',
  uf: '',
  municipio: '',
  bairro: '',
  logradouro: '',
  numero: '',
  complemento: '',
  tipo: 'Residencial',
  tutor: '',
  tutor_cpf: '',
  tutor_parentesco: '',
  necessita_acompanhante: false,
})

const errors = ref<Record<string, string>>({})
const showSuccess = ref(false)
const showError = ref(false)
const errorMessage = ref('')

// inicia o hook de criação de beneficiário
const { mutateAsync: createBeneficiarioMutation } = useCreateBeneficiario()
const { mutateAsync: createEnderecoMutation } = useCreateEndereco()

const acompanhanteOptions = [
  { label: 'Sim', value: true },
  { label: 'Não', value: false },
]

const parentescoOptions = [
  { label: 'Pai', value: 'Pai' },
  { label: 'Mãe', value: 'Mãe' },
  { label: 'Avô/Avó', value: 'Avô/Avó' },
  { label: 'Responsável Legal', value: 'Responsável Legal' },
  { label: 'Outro', value: 'Outro' },
]

const handleCpfInput = (e: Event) => {
  const input = e.target as HTMLInputElement
  form.value.cpf = formatCpf(input.value)
}
const handleCpfTutorInput = (e: Event) => {
  const input = e.target as HTMLInputElement
  form.value.tutor_cpf = formatCpf(input.value)
}
const handleTelefoneInput = (e: Event) => {
  const input = e.target as HTMLInputElement
  form.value.fone = formatTelefone(input.value)
}

const handleTelefone2Input = (e: Event) => {
  const input = e.target as HTMLInputElement
  form.value.fone2 = formatTelefone(input.value)
}

const handleDateInput = (e: Event) => {
  const input = e.target as HTMLInputElement
  form.value.nascimento = formatDate(input.value)
}

const handleCepInput = (e: Event) => {
  const input = e.target as HTMLInputElement
  form.value.cep = formatCep(input.value)
}

watch(
  () => form.value.necessita_acompanhante,
  (precisa) => {
    if (!precisa) {
      form.value.tutor = ''
      form.value.tutor_cpf = ''
      form.value.tutor_parentesco = ''
      errors.value.tutor = ''
      errors.value.tutor_cpf = ''
      errors.value.tutor_parentesco = ''
    }
  },
)

const handleSubmit = async () => {
  errors.value = {}
  showSuccess.value = false
  showError.value = false
  errorMessage.value = ''

  try {
    await BeneficiarioSchema.validate(form.value, { abortEarly: false })
    await EnderecoSchema.validate(form.value, { abortEarly: false })

    const beneficiarioPayload = {
      cpf: cleanCpf(form.value.cpf),
      codigo: form.value.codigo,
      nome: form.value.nome,
      nascimento: convertDate(form.value.nascimento),
      fone: cleanTelefone(form.value.fone),
      fone2: cleanTelefone(form.value.fone2),
      necessita_acompanhante: form.value.necessita_acompanhante,
      tutor: form.value.necessita_acompanhante ? form.value.tutor : undefined,
      tutor_parentesco: form.value.necessita_acompanhante ? form.value.tutor_parentesco : undefined,
      tutor_cpf: form.value.necessita_acompanhante ? cleanCpf(form.value.tutor_cpf) : undefined,
    }

    const enderecoPayload = {
      cep: form.value.cep,
      uf: form.value.uf,
      municipio: form.value.municipio,
      bairro: form.value.bairro,
      logradouro: form.value.logradouro,
      numero: form.value.numero,
      complemento: form.value.complemento || undefined,
      tipo: form.value.tipo,
    }

    await createBeneficiarioMutation(beneficiarioPayload)
    await createEnderecoMutation(enderecoPayload )

    showSuccess.value = true

    form.value = {
      cpf: '',
      tutor_cpf: '',
      codigo: '',
      nome: '',
      nascimento: '',
      fone: '',
      fone2: '',
      cep: '',
      uf: '',
      municipio: '',
      bairro: '',
      tipo: '',
      logradouro: '',
      numero: '',
      complemento: '',
      necessita_acompanhante: false,
      tutor: '',
      tutor_parentesco: '',
    }
  } catch (err: unknown) {
    if (err && typeof err === 'object' && 'inner' in (err as Record<string, unknown>)) {
      const validationError = err as { inner: { path: string; message: string }[] }
      validationError.inner.forEach((e) => {
        if (e.path) errors.value[e.path] = e.message
      })
      return
    }
    console.error('Erro durante submit:', err)
    errorMessage.value = (err as Error)?.message || 'Erro ao cadastrar beneficiário/endereço.'
    showError.value = true
  }
}
</script>

<template>
  <form @submit.prevent="handleSubmit">
    <AcordionCard title="Dados Pessoais">
      <FormGridLayout :cols="3">
        <BaseInput
          v-model="form.cpf"
          id="cpf"
          label="CPF"
          required
          description="Informe o CPF do beneficiário."
          placeholder="000.000.000-00"
          type="text"
          @input="handleCpfInput"
          :status="errors.cpf ? 'danger' : ''"
          :message="errors.cpf"
          icon-left="far fa-address-card "
        />
        <BaseInput
          v-model="form.codigo"
          id="codigo"
          label="Código do Cadastro Antigo"
          required
          description="Código usado em sistemas anteriores.."
          placeholder="Ex: 123456789"
          type="text"
          :status="errors.codigo ? 'danger' : ''"
          :message="errors.codigo"
          icon-left="far fa-user"
        />
        <BaseInput
          v-model="form.nome"
          id="nome"
          label="Nome Completo"
          required
          description="Nome civil do beneficiário.."
          placeholder="Digite o nome completo"
          type="text"
          :status="errors.nome ? 'danger' : ''"
          :message="errors.nome"
          icon-left="far fa-user"
        />
        <BaseInput
          v-model="form.nascimento"
          id="nascimento"
          label="Data de Nascimento"
          required
          description="Data de nascimento do beneficiário.."
          placeholder="dd/mm/aaaa"
          type="text"
          @input="handleDateInput"
          :status="errors.nascimento ? 'danger' : ''"
          :message="errors.nascimento"
          icon-left="far fa-calendar-alt"
        />
        <BaseInput
          v-model="form.fone"
          id="fone"
          label="Telefone"
          required
          description="Telefone principal para contato."
          placeholder="(xx) xxxxx-xxxx"
          type="text"
          @input="handleTelefoneInput"
          :status="errors.fone ? 'danger' : ''"
          :message="errors.fone"
          icon-left="fas fa-mobile-alt"
        />
        <BaseInput
          v-model="form.fone2"
          id="fone2"
          label="Telefone 2"
          description="Telefone secundário para contato."
          placeholder="(xx) xxxxx-xxxx"
          type="text"
          @input="handleTelefone2Input"
          :status="errors.fone2 ? 'danger' : ''"
          :message="errors.fone2"
          icon-left="fas fa-mobile-alt"
        />
      </FormGridLayout>
    </AcordionCard>

    <AcordionCard title="Sendereço">
      <FormGridLayout :cols="4">
        <BaseInput
          v-model="form.cep"
          id="cep"
          label="CEP"
          required
          description="Informe o CEP do seu endereço."
          type="text"
          @input="handleCepInput"
          placeholder="Ex: 64000-000"
          icon-left="fas fa-map-marker-alt"
          :status="errors.cep ? 'danger' : ''"
          :message="errors.cep"
        />
        <BaseInput
          v-model="form.uf"
          id="uf"
          label="Estado"
          required
          description="Informe o Estado onde mora."
          type="text"
          placeholder="Ex: Piauí"
          icon-left="fas fa-map-marker-alt"
          :status="errors.uf ? 'danger' : ''"
          :message="errors.uf"
        />
        <BaseInput
          v-model="form.municipio"
          id="municipio"
          label="Cidade"
          required
          description="Informe a municipio onde mora."
          type="text"
          placeholder="Ex: Teresina"
          icon-left="fas fa-map-marker-alt"
          :status="errors.municipio ? 'danger' : ''"
          :message="errors.municipio"
        />
        <BaseInput
          v-model="form.bairro"
          id="bairro"
          label="Bairro"
          required
          description="Informe o nome do bairro onde mora.."
          type="text"
          placeholder="Ex: Centro"
          icon-left="fas fa-map-marker-alt"
          :status="errors.bairro ? 'danger' : ''"
          :message="errors.bairro"
        />
        <BaseInput
          v-model="form.logradouro"
          id="logradouro"
          label="Logradouro"
          required
          description="Informe a rua e número da sua residência."
          type="text"
          placeholder="Ex: Av. Frei Serafim, nº 1234"
          icon-left="fas fa-map-marker-alt"
          :status="errors.logradouro ? 'danger' : ''"
          :message="errors.logradouro"
        />
        <BaseInput
          v-model="form.numero"
          id="numero"
          label="Numero"
          required
          description="Informe o número da sua residência."
          type="text"
          placeholder="Ex: 999"
          icon-left="fas fa-map-marker-alt"
          :status="errors.numero ? 'danger' : ''"
          :message="errors.numero"
        />
        <BaseInput
          v-model="form.complemento"
          id="complemento"
          label="Complemento"
          description="Informe um complemento  do seu endereço."
          type="text"
          placeholder="Ex: Próximo ao shopping"
          icon-left="fas fa-map-marker-alt"
        />
      </FormGridLayout>
    </AcordionCard>

    <AcordionCard title="Informações do Responsável">
      <FormGridLayout :cols="3">
        <BaseSelect
          v-model="form.necessita_acompanhante"
          label="Necessita de Acompanhante?"
          required
          description="O beneficiário precisa do acompanhante?."
          placeholder="Selecione uma opção"
          :options="acompanhanteOptions"
          :status="errors.necessita_acompanhante ? 'danger' : ''"
          :message="errors.necessita_acompanhante"
          icon-left="fas fa-mobile-alt"
        />
        <BaseInput
          v-model="form.tutor"
          id="aconpanhante"
          label="Tutor Responsável"
          required
          :disabled="!form.necessita_acompanhante"
          description="Pessoa responsável pelo beneficiário."
          placeholder="Digite o nome do tutor"
          type="text"
          :status="errors.tutor ? 'danger' : ''"
          :message="errors.tutor"
          icon-left="far fa-user"
        />
        <BaseInput
          v-model="form.tutor_cpf"
          id="tutor_cpf"
          label="CPF"
          required
          :disabled="!form.necessita_acompanhante"
          description="Informe o CPF do responsável."
          placeholder="000.000.000-00"
          type="text"
          @input="handleCpfTutorInput"
          :status="errors.tutor_cpf ? 'danger' : ''"
          :message="errors.tutor_cpf"
          icon-left="far fa-address-card "
        />
        <BaseSelect
          v-model="form.tutor_parentesco"
          label="Parentesco"
          required
          :disabled="!form.necessita_acompanhante"
          description="Parentesco do tutor com o beneficiário."
          placeholder="Selecione o grau"
          :options="parentescoOptions"
          :status="errors.tutor_parentesco ? 'danger' : ''"
          :message="errors.tutor_parentesco"
          icon-left="fas fa-mobile-alt"
        />
      </FormGridLayout>
    </AcordionCard>

    <div class="flex justify-end">
      <BaseButton type="submit" variant="primary">Salvar</BaseButton>
    </div>
  </form>

  <BaseAlert
    v-if="showSuccess"
    status="success"
    message="Beneficiário cadastrado com sucesso!"
    @close="showSuccess = false"
  />
  <BaseAlert v-if="showError" status="danger" :message="errorMessage" @close="showError = false" />
</template>
