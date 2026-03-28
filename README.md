# Vue 3 + TypeScript + Vite

This template should help get you started developing with Vue 3 and TypeScript in Vite. The template uses Vue 3 `<script setup>` SFCs, check out the [script setup docs](https://v3.vuejs.org/api/sfc-script-setup.html#sfc-script-setup) to learn more.

Learn more about the recommended Project Setup and IDE Support in the [Vue Docs TypeScript Guide](https://vuejs.org/guide/typescript/overview.html#project-setup).

## Keep-alive con GitHub Actions

Se agrego el workflow `.github/workflows/keep-alive.yml` para hacer un ping diario y manual a una URL publica.

### Configuracion

1. En GitHub, abre `Settings > Secrets and variables > Actions`.
2. Crea el secret `KEEPALIVE_URL`.
3. Usa una URL que realmente consulte la base de datos.

### URL recomendada

En esta app, la home no carga datos desde Supabase. La URL recomendada es un calendario publico, por ejemplo:

`https://tu-dominio.com/?public=<calendar-id>`

Esa vista ejecuta consultas a `calendars` y `bookings`, por lo que sirve mejor como keep-alive que la portada.

### Frecuencia

El workflow corre todos los dias a las `13:00 UTC`. Tambien puedes ejecutarlo manualmente desde la pestana `Actions`.
