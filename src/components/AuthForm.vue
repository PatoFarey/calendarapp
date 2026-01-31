<script setup lang="ts">
import { ref } from 'vue'
import { supabase } from '../lib/supabase'

const emit = defineEmits<{
  (e: 'authenticated'): void
}>()

const isLogin = ref(true)
const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

const handleSubmit = async () => {
  error.value = ''
  loading.value = true

  try {
    if (isLogin.value) {
      const { error: signInError } = await supabase.auth.signInWithPassword({
        email: email.value,
        password: password.value,
      })

      if (signInError) throw signInError
      emit('authenticated')
    } else {
      const { error: signUpError } = await supabase.auth.signUp({
        email: email.value,
        password: password.value,
      })

      if (signUpError) throw signUpError
      emit('authenticated')
    }
  } catch (err: any) {
    error.value = err.message || 'Ha ocurrido un error'
  } finally {
    loading.value = false
  }
}

const toggleMode = () => {
  isLogin.value = !isLogin.value
  error.value = ''
}
</script>

<template>
  <div class="auth-container">
    <div class="auth-card">
      <h2>{{ isLogin ? 'Iniciar Sesión' : 'Registrarse' }}</h2>

      <form @submit.prevent="handleSubmit">
        <div class="form-group">
          <label for="email">Email</label>
          <input
            id="email"
            v-model="email"
            type="email"
            placeholder="tu@email.com"
            required
          />
        </div>

        <div class="form-group">
          <label for="password">Contraseña</label>
          <input
            id="password"
            v-model="password"
            type="password"
            placeholder="••••••••"
            required
          />
        </div>

        <button type="submit" :disabled="loading" class="btn-primary">
          {{ loading ? 'Cargando...' : (isLogin ? 'Entrar' : 'Registrarse') }}
        </button>

        <p v-if="error" class="error">{{ error }}</p>
      </form>

      <button @click="toggleMode" class="btn-link">
        {{ isLogin ? '¿No tienes cuenta? Regístrate' : '¿Ya tienes cuenta? Inicia sesión' }}
      </button>
    </div>
  </div>
</template>

<style scoped>
.auth-container {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
}

.auth-card {
  background: var(--surface-2);
  border-radius: 16px;
  padding: 2rem;
  width: 100%;
  max-width: 400px;
  backdrop-filter: blur(10px);
  border: 1px solid var(--border);
}

h2 {
  margin-bottom: 1.5rem;
  text-align: center;
  font-size: 1.8rem;
}

.form-group {
  margin-bottom: 1rem;
}

label {
  display: block;
  margin-bottom: 0.5rem;
  font-weight: 500;
}

input {
  width: 100%;
  padding: 0.75rem;
  border-radius: 8px;
  border: 1px solid var(--border-strong);
  background: var(--surface-2);
  color: inherit;
  font-size: 1rem;
  box-sizing: border-box;
}

input:focus {
  outline: none;
  border-color: var(--primary);
}

.btn-primary {
  width: 100%;
  padding: 0.75rem;
  border-radius: 8px;
  border: none;
  background: var(--primary);
  color: white;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
  margin-top: 0.5rem;
}

.btn-primary:hover:not(:disabled) {
  background: var(--primary-hover);
}

.btn-primary:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-link {
  width: 100%;
  padding: 0.75rem;
  border: none;
  background: transparent;
  color: var(--primary);
  cursor: pointer;
  margin-top: 1rem;
  font-size: 0.9rem;
}

.btn-link:hover {
  text-decoration: underline;
}

.error {
  color: var(--danger);
  margin-top: 1rem;
  text-align: center;
  font-size: 0.9rem;
}
</style>



