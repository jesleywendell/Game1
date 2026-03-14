import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '@/views/HomeView.vue'
import PlayGround from '@/views/PlayGround.vue'
import CadastroBeneficiario from '@/views/beneficiario/CadastroBeneficiario.vue'
import AgendarViagem from '@/views/viagens/AgendamentoViagem.vue'
import MinhasViagens from '@/views/viagens/MinhasViagens.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'home',
      component: HomeView,
    },
    {
      path: '/playground',
      name: 'playground',
      component: PlayGround,
    },
    {
      path: '/cadastro-beneficiario',
      name: 'cadastro-beneficiario',
      component: CadastroBeneficiario,
      meta: { requiresAuth: true },
    },
    {
      path: '/agendar-viagem',
      name: 'agendar-viagem',
      component: AgendarViagem,
      meta: { requiresAuth: true },
    },
    {
      path: '/minhas-viagens',
      name: 'minhas-viagens',
      component: MinhasViagens,
      meta: { requiresAuth: true },
    },
  ],
})

export default router
