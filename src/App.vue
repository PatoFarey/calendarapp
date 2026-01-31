<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase, type Calendar } from './lib/supabase'
import AuthForm from './components/AuthForm.vue'
import CalendarList from './components/CalendarList.vue'
import CalendarView from './components/CalendarView.vue'
import ShareCalendar from './components/ShareCalendar.vue'
import PublicCalendarView from './components/PublicCalendarView.vue'

const user = ref<any>(null)
const loading = ref(true)
const selectedCalendar = ref<Calendar | null>(null)
const showShareModal = ref(false)
const isDayTheme = ref(false)
const userMenuOpen = ref(false)
const publicCalendarId = ref<string | null>(null)

const applyThemeClass = () => {
  document.body.classList.toggle('theme-day', isDayTheme.value)
}

const toggleTheme = () => {
  isDayTheme.value = !isDayTheme.value
  localStorage.setItem('theme', isDayTheme.value ? 'day' : 'dark')
  applyThemeClass()
}

const toggleUserMenu = () => {
  userMenuOpen.value = !userMenuOpen.value
}

const closeUserMenu = () => {
  userMenuOpen.value = false
}

const checkAuth = async () => {
  loading.value = true
  const { data: { user: currentUser } } = await supabase.auth.getUser()
  user.value = currentUser
  loading.value = false
}

const handleAuthenticated = async () => {
  await checkAuth()
}

const handleSignOut = async () => {
  closeUserMenu()
  await supabase.auth.signOut()
  user.value = null
  selectedCalendar.value = null
}

const handleSelectCalendar = (calendar: Calendar) => {
  selectedCalendar.value = calendar
}

const handleBack = () => {
  selectedCalendar.value = null
  showShareModal.value = false
}

const handleShare = () => {
  showShareModal.value = true
}

onMounted(() => {
  const params = new URLSearchParams(window.location.search)
  publicCalendarId.value = params.get('public')

  if (publicCalendarId.value) {
    loading.value = false
  } else {
    checkAuth()
  }

  const storedTheme = localStorage.getItem('theme')
  isDayTheme.value = storedTheme === 'day'
  applyThemeClass()

  if (!publicCalendarId.value) {
    supabase.auth.onAuthStateChange(() => {
      (async () => {
        await checkAuth()
      })()
    })
  }
})
</script>

<template>
  <div class="app">
    <div v-if="loading" class="loading-screen">
      <div class="loader"></div>
      <p>Cargando...</p>
    </div>

    <template v-else>
      <PublicCalendarView
        v-if="publicCalendarId"
        :calendar-id="publicCalendarId"
      />

      <template v-else>
        <header v-if="user" class="app-header">
          <h1>📅 Mis Calendarios</h1>
          <div class="user-info">
            <div class="user-menu" :class="{ open: userMenuOpen }">
              <a href="#" class="btn-user" @click.prevent="toggleUserMenu">
                {{ user.email }}
              </a>
              <div class="user-dropdown">
                <button @click="toggleTheme(); closeUserMenu()" class="btn-menu-item">
                  {{ isDayTheme ? 'Tema oscuro' : 'Tema día' }}
                </button>
                <button @click="handleSignOut" class="btn-menu-item danger">Salir</button>
              </div>
            </div>
          </div>
        </header>

        <main class="app-main">
          <AuthForm
            v-if="!user"
            @authenticated="handleAuthenticated"
          />

          <CalendarList
            v-else-if="!selectedCalendar"
            @select-calendar="handleSelectCalendar"
          />

          <CalendarView
            v-else-if="selectedCalendar"
            :calendar="selectedCalendar"
            @back="handleBack"
            @share="handleShare"
          />
        </main>

      <ShareCalendar
        v-if="showShareModal && selectedCalendar"
        :calendar="selectedCalendar"
        @close="showShareModal = false"
        @updated="value => { if (selectedCalendar) selectedCalendar.is_public = value }"
      />
      </template>
    </template>
  </div>
</template>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  background: var(--bg-gradient);
  color: var(--text);
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen',
    'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Source Sans Pro',
    sans-serif;
}

#app {
  min-height: 100vh;
}

.app {
  min-height: 100vh;
}

.loading-screen {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  gap: 1rem;
}

.loader {
  width: 48px;
  height: 48px;
  border: 4px solid var(--surface-3);
  border-top-color: var(--primary);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.app-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem 2rem;
  background: var(--surface-1);
  border-bottom: 1px solid var(--border);
}

.app-header h1 {
  font-size: 1.8rem;
  font-weight: 700;
}

.user-info {
  display: flex;
  align-items: center;
  gap: 1rem;
  background: var(--surface-1);
  border: 1px solid var(--border);
  padding: 0.35rem 0.6rem;
  border-radius: 999px;
}

.btn-signout {
  padding: 0.5rem 1rem;
  border-radius: 6px;
  border: 1px solid var(--border-strong);
  background: var(--surface-2);
  color: inherit;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 0.9rem;
}

.btn-signout:hover {
  background: var(--surface-3);
}

.user-menu {
  position: relative;
}

.btn-user {
  color: var(--text-muted-strong);
  text-decoration: underline;
  cursor: pointer;
}

.btn-user:hover {
  color: var(--text);
}

.user-dropdown {
  position: absolute;
  right: 0;
  top: calc(100% + 0.5rem);
  min-width: 180px;
  background: var(--surface-solid);
  border: 1px solid var(--border);
  border-radius: 10px;
  padding: 0.5rem;
  display: none;
  z-index: 10;
}

.user-menu.open .user-dropdown {
  display: block;
}

.btn-menu-item {
  width: 100%;
  text-align: left;
  padding: 0.5rem 0.75rem;
  border: none;
  background: transparent;
  color: inherit;
  cursor: pointer;
  border-radius: 6px;
}

.btn-menu-item:hover {
  background: var(--surface-2);
}

.btn-menu-item.danger {
  color: var(--danger);
}

.btn-menu-item.danger:hover {
  background: var(--danger-bg);
}

.app-main {
  min-height: calc(100vh - 81px);
}
</style>


