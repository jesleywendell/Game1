<script setup lang="ts">
import SimpleHeader from '@/components/header/SimpleHeader.vue'
import SimpleFooter from '@/components/footer/SimpleFooter.vue'
import HomeLayout from '@/layouts/HomeLayout.vue'
import HomeAccordion from '@/components/accordions/SobreAccordion.vue'

const items = [
  {
    id: 'objetivo',
    title: 'Objetivo',
    content:
      'Garantir deslocamentos com segurança e qualidade para pessoas com deficiência, priorizando autonomia e inclusão.',
  },
  {
    id: 'requisitos',
    title: 'Requisitos Necessários',
    content:
      'Cadastro aprovado no sistema, documento de identificação e dados de contato atualizados. Outras orientações serão exibidas durante o processo.',
  },
  {
    id: 'publico',
    title: 'Público - Alvo',
    content:
      'Pessoas com deficiência residentes no município que necessitem de transporte acessível para atividades essenciais.',
  },
]
</script>

<template>
  <HomeLayout>
    <!-- HEADER no slot nomeado -->
    <template #header>
      <SimpleHeader
        title="Transporte Eficiente"
        logoSrc="/imgs/LOGO_PMT_Colorida.svg"
        :links="[
          {
            label: 'Cadastro Beneficiário',
            to: '/cadastro-beneficiario',
            icon: 'fas fa-user-plus',
          },
          { label: 'Agendar viagens', to: '/agendar-viagem', icon: 'fas fa-route' },
          { label: 'Minhas viagens', to: '/minhas-viagens', icon: 'fas fa-list' },
        ]"
      />
    </template>

    <!-- CONTEÚDO principal (slot padrão) -->
    <div class="p-4 lg:p-6">
      <div class="mx-auto max-w-7xl grid gap-8 lg:gap-12 lg:grid-cols-12 items-center">
        <!-- Coluna esquerda -->
        <section class="lg:col-span-5">
          <h2 class="text-[26px] text-gray-700 font-light mb-3">
            Seja Bem Vindo ao Transporte Eficiente!
          </h2>
          <p class="text-gray-700 font-semibold tracking-wide gap-y-2 leading-relaxed mb-6">
            Sistema que oferece às pessoas com deficiência a possibilidade de solicitar transporte
            acessível da Prefeitura de forma prática, rápida e segura, promovendo mobilidade na
            cidade, inclusão social e mais autonomia no dia a dia.
          </p>

          <HomeAccordion :items="items" />
        </section>

        <!-- Coluna direita -->
        <aside class="flex justify-center lg:justify-end lg:col-span-7">
          <img
            src="/imgs/homebanner.png"
            alt="Ilustração do Transporte Eficiente com veículo acessível"
            class="w-full h-auto max-w-2xl drop-shadow-sm select-none"
            draggable="false"
          />
        </aside>
      </div>
    </div>

    <!-- FOOTER no slot nomeado -->
    <template #footer>
      <SimpleFooter />
    </template>
  </HomeLayout>
</template>
