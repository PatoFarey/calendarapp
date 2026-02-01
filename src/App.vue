<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { supabase, type Calendar } from './lib/supabase'
import AuthForm from './components/AuthForm.vue'
import CalendarList from './components/CalendarList.vue'
import CalendarView from './components/CalendarView.vue'
import ShareCalendar from './components/ShareCalendar.vue'
import PublicCalendarView from './components/PublicCalendarView.vue'

const showLogin = ref(false)
const user = ref<any>(null)
const loading = ref(true)
const selectedCalendar = ref<Calendar | null>(null)
const showShareModal = ref(false)
const publicCalendarId = ref<string | null>(null)

const syncFromHash = () => {
  showLogin.value = window.location.hash === '#login'
}

const openLogin = () => {
  showLogin.value = true
  if (window.location.hash !== '#login') {
    history.replaceState(null, '', '#login')
  }
}

const closeLogin = () => {
  showLogin.value = false
  if (window.location.hash === '#login') {
    history.replaceState(null, '', window.location.pathname + window.location.search)
  }
}

const checkAuth = async () => {
  loading.value = true
  const { data: { user: currentUser } } = await supabase.auth.getUser()
  user.value = currentUser
  loading.value = false
}

const handleAuthenticated = async () => {
  await checkAuth()
  closeLogin()
}

const handleSignOut = async () => {
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

  syncFromHash()
  window.addEventListener('hashchange', syncFromHash)

  if (!publicCalendarId.value) {
    supabase.auth.onAuthStateChange(() => {
      checkAuth()
    })
  }
})

onBeforeUnmount(() => {
  window.removeEventListener('hashchange', syncFromHash)
})

watch(user, value => {
  if (value) {
    closeLogin()
  }
})
</script>

<template>
  <div class="page">
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
        <div v-if="user" class="app-shell">
          <header class="app-header">
            <div class="container app-header-inner">
              <div class="logo">CalendarioSimple</div>
              <div class="app-header-actions">
                <span class="user-email">{{ user.email }}</span>
                <button class="btn btn-ghost" @click="handleSignOut">Salir</button>
              </div>
            </div>
          </header>

          <main class="app-main container">
            <CalendarList
              v-if="!selectedCalendar"
              @select-calendar="handleSelectCalendar"
            />
            <CalendarView
              v-else
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
        </div>

        <div v-else-if="showLogin" class="login-page">
          <div class="container login-page-inner">
            <a class="btn btn-ghost" href="#" @click.prevent="closeLogin">Volver</a>
            <AuthForm @authenticated="handleAuthenticated" />
          </div>
        </div>

        <div v-else>
          <header class="site-header">
            <div class="container header-inner">
              <div class="logo">CalendarioSimple</div>
              <nav class="nav">
                <a href="#como-funciona">Cómo funciona</a>
                <a href="#casos">Casos</a>
                <a href="#faq">FAQ</a>
              </nav>
              <div class="header-actions">
                <a class="btn btn-ghost" href="#login" @click.prevent="openLogin">Login</a>
     
              </div>
            </div>
          </header>

          <main>
            <section class="hero">
              <div class="container hero-grid">
                <div class="hero-copy">
                  <span class="eyebrow">Simple. Rápido. Público.</span>
                  <h1>Tu calendario, listo en minutos.</h1>
                  <p>
                    Creá un calendario simple, publicalo y compartí el link con tu grupo.
                  </p>
                  <div class="hero-actions">
                    <a class="btn btn-primary btn-lg" href="#login">Crear calendario</a>
                 
                  </div>
                  <div class="microcopy">Sin registro para ver. Comparte y listo.</div>
                </div>

                <div id="ejemplo" class="hero-preview">
                  <div class="preview-card">
                    <div class="preview-head">
                      <div>
                        <h3>Calendario del equipo</h3>
                        <span>Última actualización: hoy</span>
                      </div>
                      <span class="chip">Público</span>
                    </div>
                    <div class="preview-grid">
                      <div class="event-card">
                        <strong>Martes 20:00</strong>
                        <span>Entrenamiento general</span>
                      </div>
                      <div class="event-card">
                        <strong>Jueves 19:30</strong>
                        <span>Reunión de logística</span>
                      </div>
                      <div class="event-card">
                        <strong>Sábado 09:00</strong>
                        <span>Partido amistoso</span>
                      </div>
                    </div>
                    <div class="mini-calendar">
                      <div class="mini-header">
                        <span>Oct</span>
                        <span>2026</span>
                      </div>
                      <div class="mini-days">
                        <span>L</span><span>M</span><span>X</span><span>J</span><span>V</span><span>S</span><span>D</span>
                      </div>
                      <div class="mini-grid">
                        <span class="dim">28</span><span class="dim">29</span><span class="dim">30</span>
                        <span>1</span><span>2</span><span>3</span><span>4</span>
                        <span>5</span><span class="active">6</span><span>7</span><span>8</span><span>9</span><span>10</span><span>11</span>
                        <span>12</span><span>13</span><span>14</span><span>15</span><span>16</span><span>17</span><span>18</span>
                      </div>
                    </div>
                  </div>
                  <div class="preview-glow"></div>
                </div>
              </div>
            </section>

            <section id="como-funciona" class="section how">
              <div class="container">
                <div class="section-title">
                  <h2>Cómo funciona</h2>
                  <p>Una secuencia corta. Sin vueltas.</p>
                </div>
                <div class="steps">
                  <div class="step-card">
                    <div class="step-number">1</div>
                    <h3>Crea</h3>
                    <p>Elege nombre y agregás eventos.</p>
                  </div>
                  <div class="step-card">
                    <div class="step-number">2</div>
                    <h3>Publica</h3>
                    <p>Tu calendario queda en una URL pública.</p>
                  </div>
                  <div class="step-card">
                    <div class="step-number">3</div>
                    <h3>Comparte</h3>
                    <p>Enviá el link al grupo. Todos ven siempre la última versión.</p>
                  </div>
                </div>
              </div>
            </section>

            <section id="casos" class="section use-cases">
              <div class="container">
                <div class="section-title">
                  <h2>Casos de uso</h2>
                  <p>Ideal para coordinar personas, turnos o eventos.</p>
                </div>
                <div class="card-grid">
                  <div class="use-card">Eventos de la familia</div>
                  <div class="use-card">Turnos del equipo</div>
                  <div class="use-card">Entrenamientos / clases</div>
                  <div class="use-card">Guardias / rotaciones</div>
                  <div class="use-card">Voluntariado</div>
                  <div class="use-card">Calendario de un evento</div>
                </div>
              </div>
            </section>

            <section class="section features">
              <div class="container features-grid">
                <div>
                  <div class="section-title">
                    <h2>Todo lo esencial</h2>
                    <p>Sin funciones de más. Solo lo que necesitás.</p>
                  </div>
                  <ul class="feature-list">
                    <li>Link público</li>
                    <li>Edición rápida</li>
                    <li>Vista clara</li>
                    <li>Funciona en celular</li>
                    <li>Sin fricción</li>
                  </ul>
                </div>
                <div class="feature-panel">
                  <h3>Lo compartes una vez</h3>
                  <p>El link es siempre el mismo. Cada cambio se actualiza al instante.</p>
                  <a class="btn btn-primary" href="#login">Crear calendario</a>
                </div>
              </div>
            </section>

            <section id="faq" class="section faq">
              <div class="container">
                <div class="section-title">
                  <h2>Preguntas frecuentes</h2>
                  <p>Si no está acá, nos escribís y listo.</p>
                </div>
                <div class="faq-grid">
                  <details>
                    <summary>¿Es gratis?</summary>
                    <p>Sí. Podés crear y compartir sin costo.</p>
                  </details>
                  <details>
                    <summary>¿Necesito cuenta?</summary>
                    <p>No para ver. Para crear, podés hacerlo en segundos.</p>
                  </details>
                  <details>
                    <summary>¿Quién puede ver el calendario?</summary>
                    <p>Cualquiera que tenga el link público.</p>
                  </details>
                  <details>
                    <summary>¿Puedo editar después de publicar?</summary>
                    <p>Claro. Se actualiza automáticamente.</p>
                  </details>
                  <details>
                    <summary>¿Puedo tener varios calendarios?</summary>
                    <p>Sí. Creá uno por grupo o evento.</p>
                  </details>
                </div>
              </div>
            </section>

            <section class="section cta">
              <div class="container cta-box">
                <div>
                  <h2>Crea tu calendario hoy</h2>
                  <p>Tu grupo lo ve al instante. Vos seguís editando cuando quieras.</p>
                </div>
                <div class="cta-actions">
                  <a class="btn btn-primary btn-lg" href="#login">Crear calendario</a>
 
                </div>
              </div>
            </section>
          </main>

          <footer class="footer">
            <div class="container footer-inner">
              <div>
                <div class="logo">CalendarioSimple</div>
                <p>Calendarios simples para gente real.</p>
              </div>
              <div class="footer-links">
                <a href="#como-funciona">Cómo funciona</a>
                <a href="#casos">Casos</a>
                <a href="#faq">FAQ</a>
                <a href="#login">Crear calendario</a>
              </div>
            </div>
          </footer>
        </div>
      </template>
    </template>
  </div>
</template>

<style>
@import url('https://fonts.googleapis.com/css2?family=Manrope:wght@300;400;600;700;800&display=swap');

:root {
  --bg: #f6f4ff;
  --bg-alt: #fff4e6;
  --bg-gradient: linear-gradient(120deg, #fff2e7, #f5f3ff);
  --surface: #ffffff;
  --surface-2: #f8f9ff;
  --surface-3: #f1f3ff;
  --surface-1: #ffffff;
  --surface-solid: #ffffff;
  --text: #1a1c2b;
  --text-muted: #5b5f76;
  --text-muted-strong: #6b7280;
  --text-faint: #9aa1b6;
  --primary: #ff6b3d;
  --primary-strong: #ff4e1e;
  --primary-hover: #ff4e1e;
  --accent: #6c5ce7;
  --shadow: 0 20px 40px rgba(31, 38, 135, 0.12);
  --radius: 18px;
  --border: rgba(0, 0, 0, 0.08);
  --border-strong: rgba(0, 0, 0, 0.12);
  --danger: #ef4444;
  --danger-bg: rgba(239, 68, 68, 0.12);
  --danger-bg-hover: rgba(239, 68, 68, 0.18);
  --accent-bg: rgba(108, 92, 231, 0.12);
  --accent-bg-strong: rgba(108, 92, 231, 0.18);
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

html {
  scroll-behavior: smooth;
}

body {
  font-family: 'Manrope', system-ui, sans-serif;
  color: var(--text);
  background: radial-gradient(circle at top left, var(--bg-alt), transparent 55%),
    radial-gradient(circle at 20% 60%, #e9f2ff, transparent 50%),
    linear-gradient(180deg, var(--bg), #ffffff 55%);
  min-height: 100vh;
}

a {
  color: inherit;
  text-decoration: none;
}

.container {
  width: min(1100px, 92%);
  margin: 0 auto;
}

.loading-screen {
  min-height: 100vh;
  display: grid;
  place-items: center;
  gap: 1rem;
}

.loader {
  width: 44px;
  height: 44px;
  border-radius: 50%;
  border: 3px solid rgba(0, 0, 0, 0.1);
  border-top-color: var(--primary);
  animation: spin 1s linear infinite;
}

.app-shell {
  min-height: 100vh;
}

.app-header {
  position: sticky;
  top: 0;
  z-index: 8;
  background: rgba(255, 255, 255, 0.9);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid var(--border);
}

.app-header-inner {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.2rem 0;
  gap: 1rem;
}

.app-header-actions {
  display: flex;
  align-items: center;
  gap: 0.8rem;
}

.user-email {
  font-weight: 600;
  color: var(--text-muted);
}

.app-main {
  padding: 2rem 0 3.5rem;
}

.site-header {
  position: sticky;
  top: 0;
  z-index: 10;
  background: rgba(255, 255, 255, 0.88);
  backdrop-filter: blur(12px);
  border-bottom: 1px solid rgba(0, 0, 0, 0.06);
}

.header-inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1.2rem 0;
  gap: 1rem;
}

.logo {
  font-weight: 800;
  font-size: 1.2rem;
  letter-spacing: -0.02em;
}

.nav {
  display: flex;
  gap: 1.4rem;
  font-weight: 600;
  color: var(--text-muted);
}

.nav a:hover {
  color: var(--text);
}

.header-actions {
  display: flex;
  gap: 0.8rem;
  align-items: center;
}

.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 0.65rem 1.1rem;
  border-radius: 999px;
  border: 1px solid transparent;
  font-weight: 600;
  transition: transform 0.2s ease, box-shadow 0.2s ease, background 0.2s ease;
}

.btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 12px 24px rgba(0, 0, 0, 0.08);
}

.btn-primary {
  background: var(--primary);
  color: #fff;
}

.btn-primary:hover {
  background: var(--primary-strong);
}

.btn-ghost {
  background: rgba(255, 255, 255, 0.7);
  border-color: rgba(0, 0, 0, 0.08);
}

.btn-lg {
  padding: 0.85rem 1.5rem;
  font-size: 1rem;
}

.hero {
  padding: 5rem 0 4rem;
}

.hero-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  align-items: center;
  gap: 3rem;
}

.hero-copy h1 {
  font-size: clamp(2.4rem, 4vw, 3.6rem);
  line-height: 1.05;
  margin: 0.8rem 0 1rem;
}

.hero-copy p {
  font-size: 1.1rem;
  color: var(--text-muted);
}

.eyebrow {
  display: inline-block;
  padding: 0.3rem 0.9rem;
  background: rgba(108, 92, 231, 0.12);
  color: var(--accent);
  border-radius: 999px;
  font-weight: 700;
  font-size: 0.85rem;
}

.hero-actions {
  display: flex;
  gap: 1rem;
  margin: 1.8rem 0 1rem;
  flex-wrap: wrap;
}

.microcopy {
  font-weight: 600;
  color: var(--text-muted);
}

.hero-preview {
  position: relative;
}

.preview-card {
  background: var(--surface);
  border-radius: var(--radius);
  padding: 1.6rem;
  box-shadow: var(--shadow);
  display: flex;
  flex-direction: column;
  gap: 1.2rem;
  position: relative;
  z-index: 1;
  animation: float 6s ease-in-out infinite;
}

.preview-glow {
  position: absolute;
  inset: -20px;
  background: radial-gradient(circle, rgba(255, 107, 61, 0.25), transparent 70%);
  filter: blur(20px);
  z-index: 0;
}

.preview-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
}

.preview-head h3 {
  font-size: 1.15rem;
}

.preview-head span {
  color: var(--text-muted);
  font-size: 0.9rem;
}

.chip {
  background: rgba(255, 107, 61, 0.15);
  color: var(--primary-strong);
  padding: 0.3rem 0.8rem;
  border-radius: 999px;
  font-weight: 700;
  font-size: 0.8rem;
}

.preview-grid {
  display: grid;
  gap: 0.8rem;
}

.event-card {
  background: var(--surface-2);
  border-radius: 12px;
  padding: 0.8rem 1rem;
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
  border: 1px solid rgba(0, 0, 0, 0.06);
}

.event-card span {
  color: var(--text-muted);
}

.mini-calendar {
  background: #0f172a;
  color: #fff;
  padding: 1rem;
  border-radius: 14px;
}

.mini-header {
  display: flex;
  justify-content: space-between;
  font-weight: 700;
  margin-bottom: 0.6rem;
}

.mini-days,
.mini-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.3rem;
  font-size: 0.7rem;
  text-align: center;
}

.mini-grid span {
  padding: 0.35rem 0;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.08);
}

.mini-grid .active {
  background: var(--primary);
  font-weight: 700;
}

.mini-grid .dim {
  opacity: 0.4;
}

.section {
  padding: 4.5rem 0;
}

.section-title h2 {
  font-size: clamp(2rem, 3vw, 2.6rem);
  margin-bottom: 0.5rem;
}

.section-title p {
  color: var(--text-muted);
  font-weight: 600;
}

.steps {
  margin-top: 2.4rem;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 1.4rem;
}

.step-card {
  padding: 1.6rem;
  border-radius: var(--radius);
  background: var(--surface);
  box-shadow: var(--shadow);
  display: grid;
  gap: 0.6rem;
}

.step-number {
  width: 42px;
  height: 42px;
  border-radius: 14px;
  background: rgba(108, 92, 231, 0.18);
  display: grid;
  place-items: center;
  font-weight: 800;
  color: var(--accent);
}

.card-grid {
  margin-top: 2.2rem;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 1rem;
}

.use-card {
  padding: 1.2rem 1.4rem;
  border-radius: 16px;
  background: var(--surface);
  box-shadow: 0 12px 30px rgba(31, 38, 135, 0.08);
  font-weight: 600;
}

.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 2rem;
  align-items: center;
}

.feature-list {
  list-style: none;
  display: grid;
  gap: 0.8rem;
  margin-top: 1.6rem;
  font-weight: 600;
}

.feature-list li::before {
  content: '✓';
  margin-right: 0.6rem;
  color: var(--accent);
}

.feature-panel {
  background: linear-gradient(135deg, #fff, #f2edff);
  border-radius: var(--radius);
  padding: 2rem;
  box-shadow: var(--shadow);
  display: grid;
  gap: 1rem;
}

.faq-grid {
  margin-top: 2rem;
  display: grid;
  gap: 1rem;
}

details {
  background: var(--surface);
  border-radius: 14px;
  padding: 1rem 1.2rem;
  box-shadow: var(--shadow);
}

summary {
  cursor: pointer;
  font-weight: 700;
}

details p {
  margin-top: 0.8rem;
  color: var(--text-muted);
}

.cta {
  padding-bottom: 5.5rem;
}

.cta-box {
  background: linear-gradient(120deg, #fff2e7, #f5f3ff);
  border-radius: 22px;
  padding: 2.5rem;
  display: grid;
  gap: 1.6rem;
  align-items: center;
  box-shadow: var(--shadow);
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
}

.cta-actions {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
}

.footer {
  padding: 2.5rem 0 3.5rem;
}

.footer-inner {
  display: flex;
  justify-content: space-between;
  gap: 2rem;
  flex-wrap: wrap;
  color: var(--text-muted);
}

.footer-links {
  display: flex;
  gap: 1.4rem;
  flex-wrap: wrap;
  font-weight: 600;
}

.login-page {
  min-height: 100vh;
  display: grid;
  place-items: center;
  padding: 2rem 0 3rem;
}

.login-page-inner {
  display: grid;
  gap: 1.5rem;
  width: min(520px, 92%);
}

.login-page .auth-container {
  min-height: auto;
  padding: 0;
}

.login-page .auth-card {
  background: var(--surface);
  border: 1px solid var(--border);
}

@keyframes float {
  0%,
  100% {
    transform: translateY(0px);
  }
  50% {
    transform: translateY(-8px);
  }
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

@media (max-width: 900px) {
  .nav {
    display: none;
  }
  .header-inner {
    flex-wrap: wrap;
  }
}

@media (max-width: 600px) {
  .header-actions {
    width: 100%;
    justify-content: flex-start;
  }
  .hero {
    padding-top: 3.5rem;
  }
  .btn-lg {
    width: 100%;
  }
}
</style>
