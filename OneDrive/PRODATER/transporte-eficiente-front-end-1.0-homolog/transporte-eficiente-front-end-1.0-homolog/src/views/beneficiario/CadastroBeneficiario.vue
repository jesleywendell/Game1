<script setup lang="ts">
import CadastroBeneficiarioForm from '@/components/forms/CadastroBeneficiarioForm.vue'
import DefaultLayout from '@/layouts/DefaultLayout.vue'
</script>

<template>
  <Suspense>
    <template #default>
      <!-- Definindo os items do header dinamicamente -->
      <DefaultLayout
        title="Transporte Eficiente"
        logoSrc="/imgs/LOGO_PMT_Colorida.svg"
        :links="[
          { label: 'Agendar viagens', to: '/agendar-viagem', icon: 'fas fa-route' },
          { label: 'Minhas viagens', to: '/minhas-viagens', icon: 'fas fa-list' },
        ]"
      >
        <template #header-title>Cadastro de Beneficiário</template>

        <CadastroBeneficiarioForm />
      </DefaultLayout>
    </template>
    <template #fallback>
      <div>Carregando...</div>
    </template>
  </Suspense>
</template>
