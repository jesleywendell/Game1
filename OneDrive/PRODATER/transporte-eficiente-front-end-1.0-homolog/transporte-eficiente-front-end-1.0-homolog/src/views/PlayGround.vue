<script setup lang="ts">
import { ref, computed } from 'vue'
import { Plus, Eye } from 'lucide-vue-next'
import BaseButton from '@/components/buttons/BaseButton.vue'
import BaseInput from '@/components/fields/BaseInput.vue'
import BaseCheckbox from '@/components/fields/BaseCheckbox.vue'
import BaseRadio from '@/components/fields/BaseRadio.vue'
import BaseSwitch from '@/components/fields/BaseSwitch.vue'
import BaseAlert from '@/components/messages/BaseAlert.vue'
import MenuMobile from '@/components/menus/MenuMobile.vue'
import BaseTag from '@/components/messages/BaseTag.vue'
import DialogModal from '@/components/modais/DialogModal.vue'
import BaseCard from '@/components/cards/BaseCard.vue'
import SimpleFooter from '@/components/footer/SimpleFooter.vue'
import SimpleHeader from '@/components/header/SimpleHeader.vue'
import MenuFloat from '@/components/menus/MenuFloat.vue'
import BaseSelect from '@/components/fields/BaseSelect.vue'
import AcordionCard from '@/components/accordions/BaseAccordion.vue'
import BaseTable from '@/components/tables/BaseTable.vue'
//Menu mobile

const menuAberto = ref(false)

const toggleMenu = () => {
  menuAberto.value = true
}

// Variaveis de input
const nome = ref('')
const email = ref('')
const telefone = ref('')
const cpf = ref('')
const senha = ref('')
const informacao = ref('')
const aviso = ref('')

// Variaveis de checkbox
const checked = ref(false)
const checkedDefault = ref(true)
const checkedDisabled = ref(false)
const checkedSuccess = ref(false)
const checkedError = ref(false)
const checkedInfo = ref(false)
const checkedWarning = ref(false)

// variavel de radio
const radioSelecionado = ref('')

// Variavel de switch
const switchAtivo = ref(false)

// Variaveis para exibir alerta
const showSuccess = ref(true)
const showDanger = ref(true)
const showInfo = ref(true)
const showWarn = ref(true)

// Eventos para as tags
function handleTagClick() {
  console.log('Tag clicada')
}

function handleTagClose() {
  console.log('Fechou a tag')
}

const nomeTexto = 'Texto dinamico'

//Evento do modal dialog
const showDialog = ref(false)

// Eventos para card
const abrirMenu = () => {
  console.log('Menu clicado')
}
const acaoPrincipal = () => {
  console.log('Botão principal clicado')
}
const acaoIcone1 = () => {
  console.log('Ícone 1 clicado')
}
const acaoIcone2 = () => {
  console.log('Ícone 2 clicado')
}

// podem ser usado de forma dinamica
// const titulo = ref('Maria Amorim')
// const subtitulo = ref('UX Designer')
const imagemAvatar = ref('/imgs/LOGO_PMT_25.jpg')

// Variavel e estado do select
const estadosSelecionados = ref<string[]>([])
const estado = ref('')

const estados = [
  { label: 'Piauí', value: 'pi' },
  { label: 'Ceará', value: 'ce' },
  { label: 'Bahia', value: 'ba' },
]

// TABELA
const page = ref(1)
const pageSize = ref(5)

const viagens = ref([
  { codigo: 5580, origem: 'Prodater', destino: 'Teresina Shopping', dataHora: '08/08/25 - 10:00' },
  {
    codigo: 5580,
    origem: 'Encontro dos Rios',
    destino: 'Shopping Rio Poty',
    dataHora: '07/08/25 - 08:00',
  },
  {
    codigo: 5580,
    origem: 'Rua Chile 1167 Centro sul Teresina- PI',
    destino: 'Banco do Brasil',
    dataHora: '05/08/25 - 15:00',
  },
  { codigo: 5580, origem: 'iCev', destino: 'Teresina Shopping', dataHora: '04/08/25 - 14:00' },
  { codigo: 5580, origem: 'Local2', destino: 'Loja Shopping', dataHora: '04/08/25 - 14:00' },
  { codigo: 5580, origem: 'Local 3', destino: 'Poty Shopping', dataHora: '04/08/25 - 14:00' },
])

const columns = [
  { key: 'codigo', label: 'Código da Viagem', headerIcon: 'fas fa-hashtag', width: '180px' },
  {
    key: 'origemDestino',
    label: 'Origem  -  Destino',
    headerIcon: 'fas fa-route',
    headerAlign: 'center',
  },
  { key: 'dataHora', label: 'Data - Hora', headerIcon: 'fas fa-calendar-alt', width: '180px' },
] as const

// mapeia dados para criar a coluna combinada "origemDestino"
const viagensCombinadas = computed(() =>
  viagens.value.map((v) => ({ ...v, origemDestino: `${v.origem}  -  ${v.destino}` })),
)

function onAction({ action, row }: { action: string; row: Record<string, unknown> }) {
  if (action === 'ver') console.log('ver', row)
  if (action === 'editar') console.log('editar', row)
}
</script>

<template>
  <main>
    <SimpleHeader
      title="Transporte Eficiente"
      logoSrc="/imgs/LOGO_PMT_Colorida.svg"
      :links="[
        { label: 'Título I', to: '/playground', icon: 'fas fa-home' },
        { label: 'Título II', to: '/pagina2', icon: 'fas fa-user' },
        { label: 'Título III', to: '/pagina3', icon: 'fas fa-users' },
        {
          label: 'Site Externo',
          link: 'https://www.gov.br/ds/home',
          icon: 'fas fa-external-link-alt',
        },
      ]"
    />
    <hr />

    <h1>Menu Mobile</h1>
    <!-- Botão para abrir o menu mobile -->
    <button
      class="br-button small circle"
      type="button"
      aria-label="Menu"
      @click="
        () => {
          toggleMenu()
        }
      "
    >
      <i class="fas fa-bars" aria-hidden="true"></i>
    </button>

    <!-- Renderização do menu -->
    <MenuMobile
      v-if="menuAberto"
      @close="menuAberto = false"
      :menuItems="[
        {
          label: 'Início',
          icon: 'fas fa-home',
          to: '/playground',
        },
        {
          label: 'Saúde',
          icon: 'fas fa-heart',
          children: [
            { label: 'Cadastro beneficiario', to: '/cadastro-beneficiario' },
            { label: 'Agendamento', to: '/agendamento' },
          ],
        },
        {
          label: 'Serviços',
          icon: 'fas fa-database',
          children: [
            { label: 'Solicitar', to: '/solicitar' },
            { label: 'Agendar', to: '/agendar' },
          ],
        },
        {
          label: 'Configurações',
          icon: 'fas fa-cog',
          link: 'https://www.gov.br/ds/home',
        },
        {
          label: 'Fale Conosco',
          icon: 'fas fa-envelope',
          link: 'https://www.gov.br/ds/home',
        },
      ]"
    />
    <hr />

    <h1>Buttons</h1>
    <BaseButton variant="primary">CADASTRAR</BaseButton>
    <BaseButton variant="primary" :icon="Plus">CADASTRAR</BaseButton>
    <BaseButton variant="secondary">CADASTRAR</BaseButton>
    <BaseButton variant="secondary" :icon="Plus">CADASTRAR</BaseButton>
    <BaseButton variant="tertiary">CADASTRAR</BaseButton>
    <BaseButton variant="tertiary" :icon="Plus">CADASTRAR</BaseButton>
    <BaseButton variant="primary" :disabled="true" :icon="Plus">CADASTRAR</BaseButton>
    <BaseButton variant="primary" :loading="true" :icon="Plus">CADASTRAR</BaseButton>
    <hr />

    <h1>FAB Buttons</h1>
    <BaseButton class="bg-secondaryColor circle" :icon="Plus"></BaseButton>
    <hr />

    <h1>Inputs</h1>
    <BaseInput
      id="nome"
      label="Nome Completo"
      placeholder="Digite seu nome"
      type="text"
      v-model="nome"
      icon-left="fas fa-user"
    />

    <BaseInput
      id="senha"
      label="Senha"
      placeholder="Digite sua senha"
      type="password"
      v-model="senha"
      :icon="Eye"
    />

    <BaseInput id="cpf" label="CPF" placeholder="CPF" type="text" v-model="cpf" :disabled="true" />

    <BaseInput
      id="telefone"
      label="Telefone"
      type="text"
      v-model="telefone"
      status="success"
      message="Telefone validado com sucesso."
    />

    <BaseInput
      id="email"
      label="Email"
      type="text"
      v-model="email"
      status="danger"
      message="Email inválido."
    />

    <BaseInput
      id="info"
      label="Informação"
      type="text"
      v-model="informacao"
      status="info"
      message="Apenas números são permitidos."
    />

    <BaseInput
      id="aviso"
      label="Aviso"
      type="text"
      v-model="aviso"
      status="warning"
      message="Atenção ao preencher."
    />
    <hr />
    <h1>CheckBox</h1>

    <BaseCheckbox id="aceito" label="Aceito os termos de uso" v-model="checked" />

    <BaseCheckbox
      id="noticias"
      label="Quero receber novidades"
      v-model="checkedDefault"
      :value="true"
    />
    <BaseCheckbox
      id="desabilitado"
      label="Opção desabilitada"
      v-model="checkedDisabled"
      :disabled="true"
    />
    <BaseCheckbox
      id="confirmado"
      label="Cadastro confirmado"
      v-model="checkedSuccess"
      status="success"
      hint="Tudo certo!"
    />
    <BaseCheckbox
      id="erro"
      label="Precisa aceitar"
      v-model="checkedError"
      status="danger"
      hint="Você deve marcar esta opção."
    />
    <BaseCheckbox
      id="informativo"
      label="Informativo"
      v-model="checkedInfo"
      status="info"
      hint="Isso é apenas uma informação."
    />
    <BaseCheckbox
      id="atencao"
      label="Atenção"
      v-model="checkedWarning"
      status="warning"
      hint="Cuidado ao selecionar esta opção."
    />
    <hr />
    <h1>Radio Buttons</h1>
    <BaseRadio id="opcao1" name="grupo1" label="Opção 1" :value="'1'" v-model="radioSelecionado" />

    <BaseRadio
      id="opcao2"
      name="grupo1"
      label="Opção 2"
      :value="'2'"
      v-model="radioSelecionado"
      status="danger"
      hint="Mensagem genérica."
    />

    <!-- Status de sucesso -->
    <BaseRadio
      id="radio-success"
      name="grupo1"
      label="Opção OK"
      :value="'ok'"
      v-model="radioSelecionado"
      status="success"
      hint="Seleção válida"
    />
    <!-- Status de erro -->
    <BaseRadio
      id="radio-error"
      name="grupo1"
      label="Opção inválida"
      :value="'err'"
      v-model="radioSelecionado"
      status="danger"
      hint="Seleção obrigatória"
    />
    <!-- Status informativo -->
    <BaseRadio
      id="radio-info"
      name="grupo1"
      label="Mais informações"
      :value="'info'"
      v-model="radioSelecionado"
      status="info"
      hint="Use com cuidado"
    />
    <!-- Status de alerta -->
    <BaseRadio
      id="radio-warning"
      name="grupo1"
      label="Aviso importante"
      :value="'warn'"
      v-model="radioSelecionado"
      status="warning"
      hint="Verifique antes"
    />
    <hr />

    <h1>Switch</h1>

    <BaseSwitch
      id="switch1"
      label="Ativar notificações"
      v-model="switchAtivo"
      status="info"
      hint="Você pode ativar ou desativar quando quiser."
    />
    <hr />
    <h1>Alerts (aparece no topo)</h1>

    <!-- Mensagem de Sucesso -->
    <BaseAlert
      class="fixed space-y-2 top-4 right-4"
      v-if="showSuccess"
      status="success"
      message="Operação realizada com sucesso!"
      @close="showSuccess = false"
    />

    <!-- Mensagem de Erro -->
    <BaseAlert
      v-if="showDanger"
      status="danger"
      message="Ocorreu um erro ao processar sua solicitação."
      @close="showDanger = false"
    />

    <!-- Mensagem Informativa -->
    <BaseAlert
      v-if="showInfo"
      status="info"
      message="Este é um aviso informativo."
      @close="showInfo = false"
    />

    <!-- Mensagem de Atenção -->
    <BaseAlert
      v-if="showWarn"
      status="warning"
      message="Atenção: revise os campos obrigatórios."
      @close="showWarn = false"
    />
    <hr />

    <h1>Tags</h1>
    <BaseTag tagId="tag1" avatar="/imgs/LOGO_PMT_25.jpg" @click="handleTagClick"
      >Texto aqui
    </BaseTag>
    <BaseTag
      tagId="tag2"
      avatar="/imgs/LOGO_PMT_25.jpg"
      closable
      @click="handleTagClick"
      @close="handleTagClose"
      >Texto aqui</BaseTag
    >
    <BaseTag tagId="tag3" closable @close="handleTagClose">Texto aqui</BaseTag>
    <BaseTag tagId="tag4" icon="fas fa-car" closable @close="handleTagClose">Texto aqui</BaseTag>
    <BaseTag tagId="tag5" icon="fas fa-bus">Texto aqui</BaseTag>
    <BaseTag tagId="tag6">Texto aqui</BaseTag>
    <BaseTag tagId="tag-dinamica">{{ nomeTexto }}</BaseTag>
    <BaseTag icon="fas fa-car" tag-id="exemplo-tag" :is-disabled="true">Texto aqui</BaseTag>
    <hr />

    <h1>Modal Dealog</h1>
    <!-- Botao de abrir o modal dialog -->
    <BaseButton variant="primary" @click="showDialog = true">Abrir Diálogo</BaseButton>

    <!-- Exemplo colcoando conteudo externo no slot -->
    <DialogModal
      :show="showDialog"
      confirmText="Confirmar"
      title="Excluir item"
      titleIcon="fas fa-exclamation-triangle"
      :closable="true"
      :showCancel="true"
      @close="showDialog = false"
      @confirm="console.log('confirmado')"
    >
      <p class="text-sm">
        Você tem certeza que deseja excluir este item? Esta ação não pode ser desfeita.
      </p>

      <BaseInput id="motivo" label="Motivo" placeholder="Digite motivo" type="text" />
    </DialogModal>
    <hr />

    <h1>Card</h1>
    <BaseCard
      :avatar="imagemAvatar"
      title="Maria Amorim"
      subtitle="UX Designer"
      showMenuButton
      :showPrimaryButton="true"
      :showIconButtons="true"
      primaryButtonText="Salvar"
      secondaryIcon="fas fa-heart"
      tertiaryIcon="fas fa-share-alt"
      @clickMenu="abrirMenu"
      @clickPrimary="acaoPrincipal"
      @clickIcon1="acaoIcone1"
      @clickIcon2="acaoIcone2"
      :disabled="false"
    >
      <template #default>
        <p>
          Lorem ipsum dolor sit, amet consectetur adipisicing elit. Tempore perferendis nam porro
          atque ex at, numquam non optio ab eveniet error vel ad exercitationem, earum et fugiat
          recusandae harum? Assumenda.
        </p>
      </template>
    </BaseCard>
    <hr />

    <h1>Modal float</h1>
    <MenuFloat size="sm" position="top-left">
      <template #trigger="{ toggle }">
        <button @click="toggle" class="flex items-center gap-2 bg-gray-100 px-3 py-1 rounded-xl">
          Abrir Modal float
        </button>
      </template>

      <template #default>
        <RouterLink
          to="/"
          class="block px-4 py-3 text-gray-800 border-b border-gray-300 hover:bg-gray-100 cursor-pointer"
        >
          Home
        </RouterLink>
        <button
          class="block w-full text-left px-4 py-3 text-gray-800 border-b border-gray-300 hover:bg-gray-100 cursor-pointer"
          @click="console.log('Sair')"
        >
          Sair
        </button>
        <a
          class="block w-full text-left px-4 py-3 text-gray-800 border-b border-gray-300 hover:bg-gray-100 cursor-pointer"
          href="https://google.com.br"
        >
          Externo
        </a>
      </template>
    </MenuFloat>
    <hr />

    <h1>Select e select multiplo</h1>

    <BaseSelect label="Estado" v-model="estado" :options="estados" />

    <BaseSelect label="Estados" v-model="estadosSelecionados" :options="estados" multiple />

    <BaseSelect
      label="Estado"
      v-model="estado"
      :options="estados"
      status="danger"
      message="Campo obrigatório"
    />
    <hr />

    <h1>Acordeon</h1>
    <form>
      <AcordionCard title="Dados Pessoais">
        <BaseInput label="Nome Completo" type="text" placeholder="Digite o nome completo" />
        <BaseInput label="CPF" type="text" />
        <BaseInput label="Data de Nascimento" type="text" />
        <!-- Outros campos -->
      </AcordionCard>

      <AcordionCard title="Informações de Responsável">
        <BaseInput label="Tutor Responsável" type="text" />
        <BaseInput label="Nome Completo" type="text" placeholder="Digite o nome completo" />
        <!-- Outros campos -->
      </AcordionCard>

      <AcordionCard title="Situação e Observações">
        <BaseInput label="Nome Completo" type="text" placeholder="Digite o nome completo" />
        <BaseInput label="Observações" type="textarea" />
      </AcordionCard>

      <button type="submit" class="btn">Salvar</button>
    </form>
    <hr />

    <h1>Tabela</h1>

    <BaseTable
      :items="viagensCombinadas"
      :columns="columns"
      v-model:page="page"
      v-model:pageSize="pageSize"
      :pageSizeOptions="[5, 10, 50, 100]"
      :striped="true"
      :condensed="false"
      :actionsHeaderIcon="'fas fa-cog'"
      :actionsHeaderLabel="'Ações'"
      :actions="[
        { key: 'ver', icon: 'fas fa-eye', title: 'Ver' },
        { key: 'editar', icon: 'fas fa-pen', title: 'Editar' },
      ]"
      @action="onAction"
    />

    <br />
    <br />
    <br />
    <br />
    <br />
    <br />
    <br />
    <h1>Footer</h1>
    <SimpleFooter />
  </main>
</template>
