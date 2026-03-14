<script setup lang="ts">
import DefaultLayout from '@/layouts/DefaultLayout.vue'
import MinhasViagensTable from '@/components/tables/viagem/MinhasViagensTable.vue'

import { useViagemActions } from '@/composables/viagens/useViagemActions'

const { handleTableAction } = useViagemActions()
</script>

<template>
  <Suspense>
    <template #default>
      <DefaultLayout
        title="Transporte Eficiente"
        logoSrc="/imgs/LOGO_PMT_Colorida.svg"
        :links="[
          { label: 'Agendar viagens', to: '/agendar-viagem', icon: 'fas fa-route' },
          {
            label: 'Cadastro beneficiário',
            to: '/cadastro-beneficiario',
            icon: 'fas fa-user-plus',
          },
        ]"
      >
        <template #header-title>Minhas Viagens</template>

        <section>
          <MinhasViagensTable @action="handleTableAction" />
        </section>
      </DefaultLayout>
    </template>

    <template #fallback>
      <div>Carregando...</div>
    </template>
  </Suspense>
</template>
