<script setup lang="ts">
import GovBrButton from '@/components/buttons/ButtonGovBr.vue'
import BaseInput from '../fields/BaseInput.vue'
import BaseCheckbox from '../fields/BaseCheckbox.vue'
import BaseButton from '../buttons/BaseButton.vue'
import BaseAlert from '@/components/messages/BaseAlert.vue'

import { useLogin } from '@/composables/auth/useLogin'

const {
  username,
  password,
  checked,
  errors,
  isLoading,
  showAlertError,
  errorMessage,
  handleLogin,
} = useLogin()
</script>

<template>
  <div class="px-6 pb-6 w-full max-w-md mx-auto bg-white rounded shadow">
    <header class="mb-2 text-center">
      <h2 class="text-xl font-bold mb-2">Acesso ao Sistema</h2>
      <div class="flex justify-center">
        <GovBrButton class="w-full rounded-xl" />
      </div>
      <div class="my-3 flex items-center justify-center text-gray-400">
        <span class="border-t border-gray-300 w-1/2"></span>
        <span class="px-3">ou</span>
        <span class="border-t border-gray-300 w-1/2"></span>
      </div>
    </header>

    <main class="space-y-3">
      <BaseInput
        id="username"
        label="Usuario"
        placeholder="Ex. seuemail@email.com"
        type="text"
        description="Digite seu nome de usuario."
        v-model="username"
        icon-left="fas fa-user text-sm"
        :status="errors.username ? 'danger' : ''"
        :message="errors.username"
      />

      <BaseInput
        id="password"
        label="Senha"
        type="password"
        placeholder="Digite sua senha"
        description="Digite a sua senha de segurança."
        v-model="password"
        icon-left="fas fa-lock"
        :status="errors.password ? 'danger' : ''"
        :message="errors.password"
      />
      <BaseCheckbox
        id="aceito"
        label="Declaro que li e concordo com e condições de Termos de Uso"
        v-model="checked"
        class="text-xs mt-4"
        :status="errors.checked ? 'danger' : ''"
        :hint="errors.checked"
      />
      <div class="flex justify-between gap-2">
        <BaseButton variant="secondary" class="text-xs h-6 w-full">Esqueci a senha</BaseButton>
        <BaseButton
          variant="primary"
          class="text-xs h-6 w-full"
          @click="handleLogin"
          :loading="isLoading"
          :disabled="isLoading"
        >
          Entrar
        </BaseButton>
      </div>

      <BaseAlert
        v-if="showAlertError"
        status="danger"
        :message="errorMessage"
        @close="showAlertError = false"
        class="mb-4"
      />
    </main>

    <footer class="mt-4 text-center text-blue-700 space-y-2">
      <div><a href="#" class="text-xs underline">Não tem acesso? Criar Conta</a></div>
      <div><a href="#" class="text-xs underline">Política de Privacidade</a></div>
      <div><a href="#" class="text-xs underline">Termos de Uso</a></div>
    </footer>
  </div>
</template>
