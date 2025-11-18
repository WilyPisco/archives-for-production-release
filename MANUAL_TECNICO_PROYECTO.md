# 📘 MANUAL TÉCNICO - PROYECTO MAQS FRONTEND
## Guía Completa de Operación y Despliegue a Producción

---

## 📌 INFORMACIÓN DEL DOCUMENTO

- **Proyecto:** MAQS Frontend (Mecanismo de Atención de Quejas, Consultas y Sugerencias)
- **Versión:** 2.0.0
- **Fecha:** Noviembre 2025
- **Framework:** Angular 20.0.0
- **Tipo:** Manual Técnico Operacional
- **Público:** Equipo de DevOps, TIC, Desarrolladores

---

## 🎯 OBJETIVO DEL MANUAL

Este manual proporciona instrucciones detalladas para:

1. ✅ **Instalación y configuración** del entorno de desarrollo
2. ✅ **Ejecución del proyecto** en ambiente local
3. ✅ **Compilación y construcción** para producción
4. ✅ **Configuración de variables de entorno**
5. ✅ **Integración con DIANA** (requisito previo a producción)
6. ✅ **Testing y validación** antes de despliegue
7. ✅ **Despliegue a producción** paso a paso
8. ✅ **Monitoreo y mantenimiento** post-despliegue

---

## 📋 TABLA DE CONTENIDOS

1. [Requisitos del Sistema](#requisitos-del-sistema)
2. [Estructura del Proyecto](#estructura-del-proyecto)
3. [Instalación y Setup](#instalación-y-setup)
4. [Ejecución en Desarrollo](#ejecución-en-desarrollo)
5. [Configuración de Variables de Entorno](#configuración-de-variables-de-entorno)
6. [Compilación para Producción](#compilación-para-producción)
7. [Integración DIANA (REQUISITO)](#integración-diana-requisito)
8. [Testing y Validación](#testing-y-validación)
9. [Despliegue a Producción](#despliegue-a-producción)
10. [Monitoreo y Mantenimiento](#monitoreo-y-mantenimiento)

---

## 🖥️ REQUISITOS DEL SISTEMA

### Software Requerido

| Componente | Versión Mínima | Recomendado | Descripción |
|-----------|-----------------|------------|------------|
| **Node.js** | 18.0.0 | 20.0.0 LTS | Runtime de JavaScript |
| **npm** | 8.0.0 | 10.0.0+ | Gestor de paquetes |
| **Git** | 2.25.0 | Última | Control de versiones |
| **Angular CLI** | 20.0.0 | 20.0.0 | Herramienta CLI de Angular |
| **TypeScript** | 5.0.0 | 5.2.0+ | Lenguaje de programación |

### Navegadores Soportados

| Navegador | Versión Mínima |
|-----------|----------------|
| **Chrome** | 120+ |
| **Firefox** | 121+ |
| **Safari** | 17+ |
| **Edge** | 120+ |

---

## 📁 ESTRUCTURA DEL PROYECTO

```
maqs-frontend/
│
├── 📁 src/
│   ├── 📁 app/
│   │   ├── 📁 core/
│   │   │   ├── 📁 guards/
│   │   │   │   └── 📄 auth.guard.ts
│   │   │   ├── 📁 services/
│   │   │   │   ├── 📄 auth.service.ts
│   │   │   │   ├── 📄 auth-callback.service.ts 
│   │   │   │   ├── 📄 layout.service.ts
│   │   │   │   └── ... otros servicios
│   │   │   ├── 📁 interceptors/
│   │   │   ├── 📁 layouts/
│   │   │   ├── 📁 models/
│   │   │   ├── 📁 constants/
│   │   │   ├── 📁 validators/
│   │   │   └── 📁 utils/
│   │   │
│   │   ├── 📁 features/
│   │   │   ├── 📁 maqs/
│   │   │   │   ├── 📁 components/
│   │   │   │   └── 📁 services/
│   │   │   └── 📁 authentication/
│   │   │
│   │   ├── 📁 shared/
│   │   │   ├── 📁 components/
│   │   │   │   ├── 📁 maqs-header/
│   │   │   │   ├── 📁 maqs-footer/
│   │   │   │   └── ... otros
│   │   │   └── 📁 pipes/
│   │   │
│   │   ├── 📄 app.ts (✏️ MODIFICADO)
│   │   ├── 📄 app.routes.ts (✏️ MODIFICADO)
│   │   ├── 📄 app.config.ts
│   │   └── 📄 app.scss
│   │
│   ├── 📁 environments/
│   │   ├── 📄 environment.ts (Desarrollo)
│   │   ├── 📄 environment.prod.ts (Producción)
│   │
│   ├── 📁 assets/
│   │   ├── 📁 images/
│   │   ├── 📁 icons/
│   │   ├── 📁 styles/
│   │   └── ... otros recursos
│   │
│   ├── 📄 main.ts (Bootstrap de la app)
│   ├── 📄 index.html
│   └── 📄 styles.scss (Estilos globales)
│
├── 📁 dist/
│   └── (Generado durante build - NO commitar)
│
├── 📁 node_modules/
│   └── (Generado con npm install - NO commitar)
│
├── 📄 package.json (Dependencias del proyecto)
├── 📄 package-lock.json (Lock file - COMMITAR SIEMPRE)
├── 📄 tsconfig.json (Configuración TypeScript)
├── 📄 tsconfig.app.json (TS config para app)
├── 📄 angular.json (Configuración Angular)
├── 📄 .angular.json (Archivo generado por Angular)
├── 📄 .gitignore (Archivos a ignorar en git)
├── 📄 .prettierrc (Formato de código)
├── 📄 .eslintrc.json (Linting)
│
├── 📄 README.md (Documentación general)

```

---

## 🔧 INSTALACIÓN Y SETUP

### Paso 1: Clonar el Repositorio

```bash
# Clonar desde repositorio Git
git clone https://github.com/SERNANP/maqs-frontend.git

# Entrar al directorio
cd maqs-frontend

# Verificar rama (debe ser main o develop)
git branch -a
```

### Paso 2: Verificar Versiones Instaladas

```bash
# Node.js (debe ser >= 18.0.0)
node --version
# Salida esperada: v20.x.x o similar

# npm (debe ser >= 8.0.0)
npm --version
# Salida esperada: 10.x.x o similar

# Git
git --version
# Salida esperada: git version 2.x.x o superior
```

**Si alguna versión es menor a la recomendada:**
- Descargar e instalar desde: https://nodejs.org (incluye npm)
- Descargar e instalar Git desde: https://git-scm.com

### Paso 3: Instalar Dependencias

```bash
# Instalar Angular CLI globalmente (opcional pero recomendado)
npm install -g @angular/cli@20

# Instalar dependencias del proyecto
npm install

# Esto descargará ~500 MB de paquetes
# Puede tardar 3-5 minutos según conexión
```

**Verificar instalación exitosa:**
```bash
# Debe listar todos los paquetes instalados
npm list

# O verificar que exista node_modules
ls node_modules | wc -l
# Debe mostrar más de 100 paquetes
```

### Paso 4: Configurar Editor/IDE (Recomendado)

Se recomienda usar **Visual Studio Code**:

1. Descargar desde https://code.visualstudio.com
2. Instalar extensiones:
   - Angular Language Service
   - Prettier - Code formatter
   - ESLint
   - TypeScript Vue Plugin
   - GitLens

---

## ▶️ EJECUCIÓN EN DESARROLLO

### Opción 1: Servidor de Desarrollo Estándar

```bash
# Iniciar servidor de desarrollo
npm start

# O usando Angular CLI directamente
ng serve

# O con puerto específico
ng serve --port 4201
```

**Salida esperada:**
```
✔ Compiled successfully.

Application bundle generated successfully. (... ms)

  Initial Chunk Files   | Names         |  Raw Size
  polyfills.js          | polyfills     |  33.50 kB |
  main.js               | main          | 489.00 kB |
  styles.css            | styles        | 123.00 kB |

  Initial Total         |               | 645.50 kB

  Build at: 2025-11-18T10:30:00.000Z - Hash: abc123 - Time: 45s

✔ Compiled successfully.
✔ Build succeeded
```

**Acceder a la aplicación:**
- Abrir navegador en: `http://localhost:4200`
- Si usa puerto diferente, adaptar URL

### Opción 2: Compilación en Tiempo Real (con Hot Module Replacement)

```bash
# Con recompilación automática
ng serve --poll=2000

# Con información de cambios detectados
ng serve --verbose
```

### Opción 3: Build y Servidor Estático

```bash
# Compilar a distribución
npm run build

# Servir con servidor local (requiere http-server instalado)
npx http-server dist/maqs-frontend -p 4200
```

### Detener el Servidor

```bash
# Presionar Ctrl+C en la terminal donde está corriendo
# O ejecutar:
pkill -f "ng serve"  # En Linux/Mac
taskkill /IM node.exe  # En Windows
```

---

## ⚙️ CONFIGURACIÓN DE VARIABLES DE ENTORNO

### Ubicación de Archivos de Configuración

```
src/environments/
├── environment.ts        ← Configuración DESARROLLO
├── environment.prod.ts   ← Configuración PRODUCCIÓN
└── environment.staging.ts ← Configuración STAGING (opcional)
```

### Variables de Ambiente Disponibles

**Desarrollo (`environment.ts`):**
```
apiUrl: URL de API en desarrollo
apiUrlLogin: URL de DIANA en desarrollo
url_video_tutorial: URL del video tutorial
version: Versión del aplicativo
production: false
```

**Producción (`environment.prod.ts`):**
```
apiUrl: URL de API en producción
apiUrlLogin: URL de DIANA en producción
url_video_tutorial: URL del video tutorial
version: Versión del aplicativo
production: true
```

### Modificar Variables de Entorno

1. **Abrir archivo de configuración:**
   - Desarrollo: `src/environments/environment.ts`
   - Producción: `src/environments/environment.prod.ts`

2. **Actualizar valores:**

```typescript
export const environment = {
  production: false,
  apiUrl: 'http://localhost:7180/maqs_api/',  // ← Cambiar URL de API
  apiUrlLogin: 'https://desarrollo.sernanp.gob.pe/diana/',  // ← Cambiar DIANA
  url_video_tutorial: 'https://youtube.com/...',
  version: '2.0.0 - 18-NOV-2025'
};
```

3. **Guardar archivo**
4. **La compilación automática recargará los cambios**

### Variables Críticas para Producción

| Variable | Valor Desarrollo | Valor Producción | Obligatorio |
|----------|------------------|-----------------|-----------|
| `apiUrl` | `http://localhost:7180/maqs_api/` | `http://sis.sernanp.gob.pe/maqs_api/` | ✅ SÍ |
| `apiUrlLogin` | `https://desarrollo.sernanp.gob.pe/diana/` | `https://sis.sernanp.gob.pe/diana/` | ✅ SÍ |
| `production` | `false` | `true` | ✅ SÍ |
| `version` | `2.0.0 - DATE` | `2.0.0 - DATE` | 🟡 Recomendado |

---

## 🏗️ COMPILACIÓN PARA PRODUCCIÓN

### Pre-compilación: Validaciones

Antes de compilar para producción, verificar:

```bash
# 1. Verificar que no hay errores de TypeScript
ng build --prod --strict

# 2. Ejecutar linter (si está configurado)
ng lint

# 3. Ejecutar tests (si existen)
npm test -- --watch=false --browsers=ChromeHeadless
```

### Compilación Estándar (Sin Optimizaciones)

```bash
# Compilar para desarrollo
npm run build

# Salida en: dist/maqs-frontend/
```

### Compilación Optimizada para Producción

```bash
# Compilar para producción (RECOMENDADO)
npm run build:prod

# O con Angular CLI:
ng build --configuration production

# Características:
# - Minificación y compresión
# - Tree-shaking (elimina código no usado)
# - Bundling optimizado
# - Source maps reducidos
```

### Verificar Salida de Compilación

```bash
# Ver estructura de archivos generados
ls -lah dist/maqs-frontend/

# Ver tamaño total
du -sh dist/maqs-frontend/

# Ver detalles de bundling
npm run build:prod -- --stats-json
```

**Archivos Esperados en dist/:**

```
dist/maqs-frontend/
├── index.html          ← Archivo principal
├── main.xxxx.js        ← Bundle principal (minificado)
├── polyfills.xxxx.js   ← Polyfills
├── styles.xxxx.css     ← Estilos compilados
├── runtime.xxxx.js     ← Runtime de Angular
├── assets/             ← Recursos estáticos
└── 3rdpartylicenses.txt
```

### Tamaños Esperados

| Archivo | Tamaño Esperado |
|---------|-----------------|
| main.js | 300-500 KB |
| styles.css | 100-150 KB |
| polyfills.js | 30-40 KB |
| Total sin gzip | 500-700 KB |
| Total con gzip | 150-250 KB |

---

## 🔗 INTEGRACIÓN DIANA (REQUISITO PREVIO A PRODUCCIÓN)

### ⚠️ IMPORTANTE: REQUISITO OBLIGATORIO

**Antes de hacer cualquier despliegue a producción, DIANA debe estar completamente integrado.**

### Checklist de Integración DIANA

- [ ] **DIANA está configurada** para redirigir a `/maqs`
- [ ] **DIANA envía los 3 parámetros obligatorios:**
  - `validacionPass` (token de autenticación)
  - `selectOpcion` (ID del usuario)
  - `userName` (nombre del usuario)
- [ ] **Testing en desarrollo completado** (ver QA_TESTING_CHECKLIST.md)
- [ ] **Equipo TIC valida la integración**
- [ ] **HTTPS está habilitado** en producción
- [ ] **Certificados SSL son válidos**

### Validar Integración DIANA en Desarrollo

1. **Acceder a /maqs sin autenticar:**
   ```
   http://localhost:4200/maqs
   ```
   **Resultado esperado:** Redirige a DIANA

2. **Hacer login en DIANA**

3. **DIANA redirige con parámetros:**
   ```
   http://localhost:4200/maqs?validacionPass=TOKEN&selectOpcion=ID&userName=NAME
   ```

4. **Verificar en DevTools (F12):**
   - Application → Session Storage
   - Debe tener: `auth_token`, `userId`, `userName`

5. **Navbar debe mostrar:** "Bienvenido, [NOMBRE]"

6. **Logout debe funcionar** y limpiar sesión

### Si DIANA no está Integrado

**❌ NO CONTINUAR CON PRODUCCIÓN**

Contactar con el Desarrollador

## 🚀 DESPLIEGUE A PRODUCCIÓN

### Fase 1: Preparación (1-2 horas)

#### 1.1 Actualizar Versión

```bash
# En package.json
# Cambiar "version": "2.0.0" a la versión correspondiente

# En environment.prod.ts
# Actualizar version: "2.0.0 - DD-MMM-YYYY"
```

#### 1.2 Compilar para Producción

```bash
# Compilar
npm run build:prod

# Verificar que compile sin errores
# Tamaño total < 700 KB sin gzip
```

#### 1.3 Validación Final

```bash
# Revisar dist/
ls -lah dist/maqs-frontend/

# Archivos clave presentes:
# ✅ index.html
# ✅ main.*.js
# ✅ styles.*.css
# ✅ assets/
```

### Fase 2: Validación (30 minutos)

#### 2.1 Testing Manual de Build Compilado

```bash
# Servir compilación de producción localmente
npx http-server dist/maqs-frontend/ -p 8080

# Acceder a http://localhost:8080
# Verificar:
# - ✅ Carga correctamente
# - ✅ Estilos presentes
# - ✅ No hay errores en consola (F12)
# - ✅ DIANA redirect funciona (si está integrado)
```

### Problema: DIANA no redirige correctamente

**Causa:** URL de DIANA está mal configurada en environment.prod.ts

**Solución:**
1. Verificar `environment.prod.ts` tiene URL correcta
2. Compilar de nuevo: `npm run build:prod`
3. Desplegar código actualizado
4. Limpiar cache de navegador (Ctrl+Shift+Del)

---

### Problema: Usuario no aparece en navbar después de login

**Causa:** Parámetro `userName` no se envía desde DIANA

**Solución:**
1. Verificar en DIANA que envía parámetro `userName`
2. En DevTools (F12), verificar URL tiene: `?...&userName=...`
3. Verificar en sessionStorage: `sessionStorage.getItem('userName')`
4. Si retorna `null`, contactar a equipo TIC SERNANP

---

## 🎯 CONCLUSIÓN

Este manual proporciona las instrucciones completas para:

1. ✅ **Instalar y ejecutar** el proyecto en desarrollo
2. ✅ **Compilar para producción** optimizadamente
3. ✅ **Integrar con DIANA** (requisito obligatorio)
4. ✅ **Validar funcionamiento** antes de desplegar
5. ✅ **Desplegar a producción** siguiendo buenas prácticas
6. ✅ **Monitorear y mantener** en producción

**Recordar:** No desplegar a producción sin completar la integración de DIANA.

---

**Manual Técnico Oficial - MAQS Frontend**
**Versión:** 1.0
**Última actualización:** Noviembre 2025
**Realizado por:** Wilmer Pisco R.
