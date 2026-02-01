<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase, type Calendar, type Booking } from '../lib/supabase'

const props = defineProps<{
  calendarId: string
}>()

const calendar = ref<Calendar | null>(null)
const bookings = ref<Booking[]>([])
const loading = ref(true)
const errorMessage = ref('')
const viewMode = ref<'month' | 'week' | 'list'>('month')
const currentWeek = ref<Date[]>([])
const weekStart = ref(new Date())
const currentMonth = ref(new Date())
const currentMonthDates = ref<Date[]>([])
const listMonth = ref(new Date())
const selectedDate = ref(new Date())
const showDayModal = ref(false)

const formatMonthTitle = (date: Date) => {
  return date.toLocaleDateString('es-ES', { month: 'long', year: 'numeric' })
}

const formatTime = (date: string) => {
  return new Date(date).toLocaleTimeString('es-ES', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

const formatDate = (date: string) => {
  return new Date(date).toLocaleDateString('es-ES', {
    day: 'numeric',
    month: 'short'
  })
}

const formatDateFromDate = (date: Date) => {
  return date.toLocaleDateString('es-ES', {
    day: 'numeric',
    month: 'short'
  })
}

const goToApp = () => {
  window.location.href = `${window.location.origin}/`
}

const getWeekDates = (startDate: Date) => {
  const dates = []
  const start = new Date(startDate)
  const day = start.getDay()
  const diff = (day + 6) % 7
  start.setDate(start.getDate() - diff)

  for (let i = 0; i < 7; i++) {
    const date = new Date(start)
    date.setDate(start.getDate() + i)
    dates.push(date)
  }

  return dates
}

const getMonthDates = (dateInMonth: Date) => {
  const dates = []
  const start = new Date(dateInMonth.getFullYear(), dateInMonth.getMonth(), 1)
  const day = start.getDay()
  const diff = (day + 6) % 7
  start.setDate(start.getDate() - diff)

  for (let i = 0; i < 42; i++) {
    const date = new Date(start)
    date.setDate(start.getDate() + i)
    dates.push(date)
  }

  return dates
}

const isSameMonth = (date: Date) => {
  return date.getMonth() === currentMonth.value.getMonth() &&
    date.getFullYear() === currentMonth.value.getFullYear()
}

const bookingsForDate = (date: Date) => {
  const dayDate = new Date(date.getFullYear(), date.getMonth(), date.getDate())

  return bookings.value.filter(b => {
    const startDate = new Date(b.start_time)
    const endDate = new Date(b.end_time)
    const startDateOnly = new Date(startDate.getFullYear(), startDate.getMonth(), startDate.getDate())
    const endDateOnly = new Date(endDate.getFullYear(), endDate.getMonth(), endDate.getDate())

    return dayDate >= startDateOnly && dayDate <= endDateOnly
  }).sort((a, b) => new Date(a.start_time).getTime() - new Date(b.start_time).getTime())
}

const bookingsForMonth = (month: Date) => {
  return bookings.value.filter(b => {
    const startDate = new Date(b.start_time)
    return startDate.getMonth() === month.getMonth() && startDate.getFullYear() === month.getFullYear()
  })
}

const handleDayClick = (day: Date) => {
  selectedDate.value = new Date(day)
  if (bookingsForDate(day).length > 0) {
    showDayModal.value = true
  }
}

const closeDayModal = () => {
  showDayModal.value = false
}

const previousWeek = () => {
  weekStart.value = new Date(weekStart.value.setDate(weekStart.value.getDate() - 7))
  currentWeek.value = getWeekDates(weekStart.value)
}

const nextWeek = () => {
  weekStart.value = new Date(weekStart.value.setDate(weekStart.value.getDate() + 7))
  currentWeek.value = getWeekDates(weekStart.value)
}

const previousMonth = () => {
  currentMonth.value = new Date(currentMonth.value.getFullYear(), currentMonth.value.getMonth() - 1, 1)
  currentMonthDates.value = getMonthDates(currentMonth.value)
}

const nextMonth = () => {
  currentMonth.value = new Date(currentMonth.value.getFullYear(), currentMonth.value.getMonth() + 1, 1)
  currentMonthDates.value = getMonthDates(currentMonth.value)
}

const previousListMonth = () => {
  listMonth.value = new Date(listMonth.value.getFullYear(), listMonth.value.getMonth() - 1, 1)
}

const nextListMonth = () => {
  listMonth.value = new Date(listMonth.value.getFullYear(), listMonth.value.getMonth() + 1, 1)
}

const loadCalendar = async () => {
  const { data, error } = await supabase
    .from('calendars')
    .select('*')
    .eq('id', props.calendarId)
    .maybeSingle()

  if (error) throw error
  calendar.value = data
}

const loadBookings = async () => {
  const { data, error } = await supabase
    .from('bookings')
    .select('*')
    .eq('calendar_id', props.calendarId)
    .order('start_time', { ascending: true })

  if (error) throw error
  bookings.value = data || []
}

onMounted(async () => {
  loading.value = true
  try {
    await loadCalendar()
    if (!calendar.value) {
      errorMessage.value = 'Calendario no disponible'
      return
    }
    await loadBookings()
    currentMonthDates.value = getMonthDates(currentMonth.value)
    currentWeek.value = getWeekDates(weekStart.value)
  } catch (error) {
    console.error('Error loading public calendar:', error)
    errorMessage.value = 'No se pudo cargar el calendario'
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="public-calendar">
    <div class="public-header">
      <h3>{{ calendar?.name || 'Calendario' }}</h3>
    </div>

    <div v-if="viewMode === 'week'" class="week-navigation">
      <div class="nav-buttons">
        <button @click="previousWeek" class="btn-nav">←</button>
        <h3>Semana del {{ formatDate(currentWeek[0]?.toISOString()) }}</h3>
        <button @click="nextWeek" class="btn-nav">→</button>
      </div>
      <div class="view-toggle">
        <button
          class="btn-toggle"
          :class="{ active: String(viewMode) === 'month' }"
          @click="viewMode = 'month'"
        >
          Mes
        </button>
        <button
          class="btn-toggle"
          :class="{ active: String(viewMode) === 'week' }"
          @click="viewMode = 'week'"
        >
          Semana
        </button>
        <button
          class="btn-toggle"
          :class="{ active: String(viewMode) === 'list' }"
          @click="viewMode = 'list'"
        >
          Lista
        </button>
      </div>
    </div>

    <div v-else-if="viewMode === 'month'" class="month-navigation">
      <div class="nav-buttons">
        <button @click="previousMonth" class="btn-nav">←</button>
        <h3>{{ formatMonthTitle(currentMonth) }}</h3>
        <button @click="nextMonth" class="btn-nav">→</button>
      </div>
      <div class="view-toggle">
        <button
          class="btn-toggle"
          :class="{ active: String(viewMode) === 'month' }"
          @click="viewMode = 'month'"
        >
          Mes
        </button>
        <button
          class="btn-toggle"
          :class="{ active: String(viewMode) === 'week' }"
          @click="viewMode = 'week'"
        >
          Semana
        </button>
        <button
          class="btn-toggle"
          :class="{ active: String(viewMode) === 'list' }"
          @click="viewMode = 'list'"
        >
          Lista
        </button>
      </div>
    </div>

    <div v-else-if="viewMode === 'list'" class="list-navigation">
      <div class="nav-buttons">
        <button @click="previousListMonth" class="btn-nav">←</button>
        <h3>{{ formatMonthTitle(listMonth) }}</h3>
        <button @click="nextListMonth" class="btn-nav">→</button>
      </div>
      <div class="view-toggle">
        <button
          class="btn-toggle"
          :class="{ active: String(viewMode) === 'month' }"
          @click="viewMode = 'month'"
        >
          Mes
        </button>
        <button
          class="btn-toggle"
          :class="{ active: String(viewMode) === 'week' }"
          @click="viewMode = 'week'"
        >
          Semana
        </button>
        <button
          class="btn-toggle"
          :class="{ active: String(viewMode) === 'list' }"
          @click="viewMode = 'list'"
        >
          Lista
        </button>
      </div>
    </div>

    <div v-if="loading" class="loading">Cargando calendario...</div>
    <div v-else-if="errorMessage" class="loading">{{ errorMessage }}</div>

    <div v-else-if="viewMode === 'week'" class="week-view">
      <div
        v-for="(day, index) in currentWeek"
        :key="index"
        class="day-column"
      >
        <div class="day-header">
          <div class="day-name">{{ day.toLocaleDateString('es-ES', { weekday: 'short' }) }}</div>
          <div class="day-number">{{ day.getDate() }}</div>
        </div>
        <div class="day-bookings">
          <div
            v-for="booking in bookingsForDate(day)"
            :key="booking.id"
            class="booking-item-week"
            :style="{ borderLeftColor: calendar?.color }"
          >
            <div class="booking-time">
              {{ formatTime(booking.start_time) }} - {{ formatTime(booking.end_time) }}
            </div>
            <div class="booking-title">{{ booking.title }}</div>
            <div v-if="booking.description" class="booking-description">
              {{ booking.description }}
            </div>
          </div>
          <div v-if="bookingsForDate(day).length === 0" class="no-bookings">
            Sin eventos
          </div>
        </div>
      </div>
    </div>

    <div v-else-if="viewMode === 'month'" class="month-view">
      <div class="month-header">
        <div class="month-header-cell" v-for="day in ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom']" :key="day">
          {{ day }}
        </div>
      </div>
      <div class="month-grid">
        <div v-for="(day, index) in currentMonthDates" :key="index" class="month-day" :class="{
          'is-other-month': !isSameMonth(day),
          'has-bookings': bookingsForDate(day).length > 0
        }" @click="handleDayClick(day)">
          <div class="month-day-number">{{ day.getDate() }}</div>
          <div class="month-day-count">
            <span v-if="bookingsForDate(day).length > 0">
              {{ bookingsForDate(day).length }} eventos
            </span>
            <span v-else class="month-day-empty">Sin eventos</span>
          </div>
        </div>
      </div>
    </div>

    <div v-else-if="viewMode === 'list'" class="list-view">
      <div v-if="bookingsForMonth(listMonth).length === 0" class="no-bookings">
        No hay eventos en este mes
      </div>
      <div v-else class="list-container">
        <div
          v-for="booking in bookingsForMonth(listMonth)"
          :key="booking.id"
          class="list-item"
          :style="{ borderLeftColor: calendar?.color }"
        >
          <div class="list-item-header">
            <div class="list-item-date">
              <div class="list-date-day">
                {{ formatDate(booking.start_time) }}
                <span v-if="formatDate(booking.start_time) !== formatDate(booking.end_time)">
                  - {{ formatDate(booking.end_time) }}
                </span>
              </div>
              <div class="list-date-time">
                {{ formatTime(booking.start_time) }} - {{ formatTime(booking.end_time) }}
              </div>
            </div>
            <div class="list-item-content">
              <div class="list-item-title">{{ booking.title }}</div>
              <div v-if="booking.description" class="list-item-description">
                {{ booking.description }}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>

  <div class="public-footer">
    <button @click="goToApp" class="btn-cta">Crea tu propio calendario</button>
  </div>

  <div v-if="showDayModal" class="day-modal">
    <div class="day-modal-backdrop" @click="closeDayModal"></div>
    <div class="day-modal-content">
      <div class="day-modal-header">
        <h4>Eventos del {{ formatDateFromDate(selectedDate) }}</h4>
        <button class="btn-close" @click="closeDayModal">✖</button>
      </div>
      <div v-if="bookingsForDate(selectedDate).length === 0" class="loading">
        Sin eventos
      </div>
      <div v-for="booking in bookingsForDate(selectedDate)" :key="booking.id" class="booking-item">
        <div class="booking-time">
          {{ formatTime(booking.start_time) }} - {{ formatTime(booking.end_time) }}
        </div>
        <div class="booking-title">{{ booking.title }}</div>
        <div v-if="booking.description" class="booking-description">
          {{ booking.description }}
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.public-calendar {
  padding: 1.5rem;
  max-width: 1200px;
  margin: 0 auto;
}

.public-header {
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 1rem;
  gap: 1rem;
  flex-wrap: wrap;
}

.public-header h2 {
  margin: 0;
  font-size: 2rem;
}

.btn-cta {
  padding: 0.6rem 1.1rem;
  border-radius: 999px;
  border: 1px solid var(--border-strong);
  background: var(--primary);
  color: white;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-cta:hover {
  background: var(--primary-hover);
}

.month-navigation {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 2rem;
  margin-bottom: 1.5rem;
  position: relative;
}

.month-navigation h3 {
  margin: 0;
  font-size: 1.2rem;
  text-transform: capitalize;
}

.week-navigation {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 2rem;
  margin-bottom: 1.5rem;
  position: relative;
}

.week-navigation h3 {
  margin: 0;
  font-size: 1.2rem;
}

.list-navigation {
  display: flex;
  align-items: center;
  justify-content: flex-start;
  gap: 2rem;
  margin-bottom: 1.5rem;
  position: relative;
}

.list-navigation h3 {
  margin: 0;
  font-size: 1.2rem;
  text-transform: capitalize;
}

.list-navigation .view-toggle,
.month-navigation .view-toggle,
.week-navigation .view-toggle {
  margin-left: auto;
}

.nav-buttons {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.nav-buttons h3 {
  margin: 0 0.5rem;
}

.view-toggle {
  display: inline-flex;
  border: 1px solid var(--border-strong);
  border-radius: 8px;
  overflow: hidden;
}

.btn-toggle {
  padding: 0.6rem 1rem;
  border: none;
  background: transparent;
  color: inherit;
  cursor: pointer;
  font-weight: 600;
  transition: background 0.2s;
}

.btn-toggle.active {
  background: var(--accent-bg-strong);
  color: var(--primary);
}

.btn-nav {
  padding: 0.5rem 1rem;
  border-radius: 8px;
  border: 1px solid var(--border-strong);
  background: var(--surface-2);
  color: inherit;
  cursor: pointer;
  transition: all 0.2s;
  font-size: 1.2rem;
}

.btn-nav:hover {
  background: var(--surface-3);
}

.loading {
  text-align: center;
  padding: 2rem;
  color: var(--text-muted);
}

.month-view {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.month-header {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.5rem;
}

.month-header-cell {
  text-align: center;
  font-size: 0.8rem;
  text-transform: uppercase;
  color: var(--text-muted);
  font-weight: 600;
}

.month-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.5rem;
}

.month-day {
  background: var(--surface-1);
  border-radius: 8px;
  padding: 0.75rem;
  border: 1px solid var(--border);
  min-height: 110px;
}

.month-day.is-other-month {
  opacity: 0.45;
}

.month-day.has-bookings {
  background: var(--danger-bg);
  border-color: var(--danger);
}

.month-day-number {
  font-weight: 700;
  margin-bottom: 0.5rem;
}

.month-day-count {
  font-size: 0.85rem;
  color: var(--text-muted-strong);
}

.month-day-empty {
  color: var(--text-faint);
}

.week-view {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 0.5rem;
  min-height: 500px;
}

.day-column {
  background: var(--surface-1);
  border-radius: 8px;
  padding: 0.75rem;
  border: 1px solid var(--border);
  display: flex;
  flex-direction: column;
}

.day-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.75rem;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid var(--border);
}

.day-name {
  font-weight: 700;
  text-transform: uppercase;
  font-size: 0.75rem;
  color: var(--text-muted);
}

.day-number {
  font-weight: 700;
  font-size: 1.2rem;
}

.day-bookings {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  flex: 1;
}

.booking-item-week {
  background: var(--surface-2);
  border-radius: 6px;
  padding: 0.6rem;
  margin-bottom: 0.25rem;
  border-left: 3px solid;
  position: relative;
}

.booking-item-week .booking-time {
  font-size: 0.75rem;
  color: var(--text-muted);
  margin-bottom: 0.25rem;
}

.booking-item-week .booking-title {
  font-weight: 600;
  font-size: 0.85rem;
  margin-bottom: 0.25rem;
}

.booking-item-week .booking-description {
  font-size: 0.75rem;
  color: var(--text-muted);
  margin-top: 0.25rem;
}

.no-bookings {
  color: var(--text-faint);
  font-size: 0.85rem;
  text-align: center;
  padding: 1rem;
}

.list-view {
  display: flex;
  flex-direction: column;
}

.list-container {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.list-item {
  background: var(--surface-1);
  border: 1px solid var(--border);
  border-left: 4px solid;
  border-radius: 8px;
  padding: 1rem;
  transition: background 0.2s;
}

.list-item:hover {
  background: var(--surface-2);
}

.list-item-header {
  display: flex;
  gap: 1.5rem;
  align-items: center;
}

.list-item-date {
  display: flex;
  flex-direction: column;
  gap: 0.25rem;
  min-width: 120px;
}

.list-date-day {
  font-weight: 700;
  font-size: 0.95rem;
  color: var(--text);
}

.list-date-time {
  font-size: 0.85rem;
  color: var(--text-muted);
}

.list-item-content {
  flex: 1;
}

.list-item-title {
  font-weight: 600;
  font-size: 1rem;
  margin-bottom: 0.25rem;
}

.list-item-description {
  font-size: 0.9rem;
  color: var(--text-muted);
  margin-top: 0.25rem;
}

.day-modal {
  position: fixed;
  inset: 0;
  z-index: 1200;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
}

.day-modal-backdrop {
  position: absolute;
  inset: 0;
  background: var(--bg-gradient);
}

.day-modal-content {
  position: relative;
  width: 100%;
  max-width: 640px;
  max-height: 85vh;
  overflow-y: auto;
  background: var(--surface-solid);
  border: 1px solid var(--border);
  border-radius: 14px;
  padding: 1.25rem;
  z-index: 1;
}

.day-modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  margin-bottom: 1rem;
}

.day-modal-header h4 {
  margin: 0;
  font-size: 1rem;
}

.day-modal-header .btn-close {
  border: none;
  background: transparent;
  color: var(--text);
  cursor: pointer;
  font-size: 1.1rem;
}

.booking-item {
  background: var(--surface-2);
  border-radius: 6px;
  padding: 0.75rem;
  margin-bottom: 0.5rem;
  border-left: 3px solid var(--danger);
  position: relative;
}

.booking-time {
  font-size: 0.8rem;
  color: var(--text-muted);
  margin-bottom: 0.25rem;
}

.booking-title {
  font-weight: 600;
  margin-bottom: 0.25rem;
}

.booking-description {
  font-size: 0.85rem;
  color: var(--text-muted);
  margin-top: 0.5rem;
}

.public-footer {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 2rem 1.5rem;
}

@media (max-width: 1024px) {
  .month-grid {
    grid-template-columns: repeat(4, 1fr);
  }
}

@media (max-width: 768px) {
  .week-navigation,
  .month-navigation,
  .list-navigation {
    flex-direction: column;
    gap: 1rem;
  }

  .nav-buttons {
    justify-content: center;
  }

  .view-toggle {
    width: 100%;
    justify-content: center;
  }

  .btn-toggle {
    flex: 1;
  }

  .week-view {
    grid-template-columns: repeat(2, 1fr);
  }

  .month-header,
  .month-grid {
    grid-template-columns: repeat(7, 1fr);
    gap: 0.15rem;
  }

  .month-header-cell {
    font-size: 0.6rem;
    padding: 0.2rem 0;
  }

  .month-day {
    min-height: 55px;
    padding: 0.15rem;
    border-radius: 4px;
  }

  .month-day.has-bookings {
    border: 2px solid #10b981;
    background: rgba(16, 185, 129, 0.08);
  }

  .month-day-number {
    font-size: 0.7rem;
    margin-bottom: 0.15rem;
  }

  .month-day-count {
    font-size: 0.6rem;
  }

  .list-item-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .list-item-date {
    min-width: auto;
  }
}
</style>
