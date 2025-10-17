# Alianza Producciones API (Node.js + TypeScript + Sequelize)

Arquitectura por capas con conexión a base de datos lista en el arranque.

## Stack
- Node.js + Express
- TypeScript
- Sequelize ORM (driver: mysql2)
- Dotenv

## Scripts
- `npm run dev` – Modo desarrollo con recarga
- `npm run build` – Compila a JS (dist/)
- `npm start` – Ejecuta desde dist/

## Configuración rápida
1) Copia `.env.example` a `.env` y ajusta tus credenciales de BD.
2) Instala dependencias:
   ```bash
   npm install
   ```
3) Ejecuta en desarrollo:
   ```bash
   npm run dev
   ```

## Estructura por capas
```
src/
  app.ts                # Express app
  server.ts             # Bootstrap + conexión BD
  config/env.ts         # Variables de entorno
  database/sequelize.ts # Instancia Sequelize + testConnection()
  controllers/          # Controladores (HTTP)
  routes/               # Rutas Express
  models/               # Modelos Sequelize
  repositories/         # Acceso a datos (usa modelos)
  services/             # Lógica de negocio
```

## GitFlow sugerido
```bash
git init
git remote add origin https://github.com/AnSan29/alianzaProduccionesApp.git
git checkout -b main
git checkout -b develop
git add .
git commit -m "chore: initial scaffold (Node+TS+Sequelize) with DB connection"
git push -u origin develop
```
Luego crea ramas de feature desde `develop`.
