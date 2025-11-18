# 📋 GUÍA DE INTEGRACIÓN DIANA CON MAQS FRONTEND
## Para el Encargado del Área de TIC del SERNANP

---

## 📌 INTRODUCCIÓN

Este documento está dirigido al equipo de TIC del SERNANP para realizar la integración entre el sistema **DIANA** (Sistema de Autenticación Centralizado) y el frontend de **MAQS** (Mecanismo de Atención de Quejas, Consultas y Sugerencias).

**Versión del documento:** 1.0
**Fecha:** Noviembre 2025
**Aplicación:** MAQS Frontend
**Entorno:** Desarrollo / Producción

---

## 🎯 OBJETIVO

Integrar la autenticación de usuarios desde DIANA con el frontend de MAQS de forma que:

1. ✅ Los usuarios se autentiquen mediante DIANA
2. ✅ Se capture y almacene el token de autenticación
3. ✅ Se proteja la ruta `/maqs` solo para usuarios autenticados
4. ✅ Se muestre el nombre del usuario logueado en la barra de navegación
5. ✅ Se maneje correctamente el logout

---

## 🔄 FLUJO DE AUTENTICACIÓN - DIAGRAMA COMPLETO

```
┌─────────────────────────────────────────────────────────────────────┐
│                     FLUJO DE AUTENTICACIÓN DIANA                    │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────────────┐
│    USUARIO NO AUTH   │
│  Intenta acceder a:  │
│  /maqs               │
└──────────┬───────────┘
           │
           ↓
┌──────────────────────────────────────────┐
│     AuthGuard verifica sesión            │
│  sessionStorage.getItem('auth_token')    │
│                                          │
│  ¿Token existe?                          │
└──────────────────────────────────────────┘
    NO │                          │ SÍ
       ↓                          │
┌────────────────────────┐        │
│  Redirige a DIANA      │        │
│  para login            │        │
└────────┬───────────────┘        │
         │                        │
         ↓                        │
┌────────────────────────────────────────────────────────────┐
│  DIANA (Sistema Externo de Autenticación)                 │
│  - Usuario ingresa credenciales                           │
│  - Valida información                                     │
│  - Genera token de autenticación                          │
│  - Redirige al frontend con parámetros                    │
└────────┬───────────────────────────────────────────────────┘
         │
         ↓
┌────────────────────────────────────────────────────────────┐
│  CALLBACK URL CON PARÁMETROS:                              │
│  https://sis.sernanp.gob.pe/maqs                           │
│    ?validacionPass=ABC123XYZ&selectOpcion=443              │
│    &userName=Juan%20Perez                                  │
└────────┬───────────────────────────────────────────────────┘
         │
         ↓
┌────────────────────────────────────────────────────────────┐
│  App Component (app.ts)                                    │
│  - Detecta parámetros en URL                               │
│  - Llama AuthCallbackService.processAuthCallback()         │
└────────┬───────────────────────────────────────────────────┘
         │
         ↓
┌────────────────────────────────────────────────────────────┐
│  AuthCallbackService                                       │
│  Guarda en sessionStorage:                                 │
│  - auth_token = "ABC123XYZ"                                │
│  - userId = "443"                                          │
│  - userName = "Juan Perez"                                 │
│  - current_user = { userId, userName, token, loginTime }   │
└────────┬───────────────────────────────────────────────────┘
         │
         ↓
┌────────────────────────────────────────────────────────────┐
│  Usuario accede nuevamente a /maqs                         │
└────────┬───────────────────────────────────────────────────┘
         │
         ↓
┌────────────────────────────────────────────────────────────┐
│  AuthGuard verifica sessionStorage.getItem('auth_token')    │
│  ✅ Token existe = Acceso permitido                         │
└────────┬───────────────────────────────────────────────────┘
         │
         ↓
┌────────────────────────────────────────────────────────────┐
│  Componente ListarMaqs se carga                            │
│  - Navbar muestra: "Bienvenido, Juan Perez"               │
│  - Botón "Salir" disponible                                │
└────────┬───────────────────────────────────────────────────┘
         │
         ↓
┌────────────────────────────────────────────────────────────┐
│  Usuario hace click en "Salir"                             │
└────────┬───────────────────────────────────────────────────┘
         │
         ↓
┌────────────────────────────────────────────────────────────┐
│  AuthService.logout()                                      │
│  - Limpia sessionStorage                                   │
│  - Limpia localStorage                                     │
│  - Redirige a DIANA para cleanup centralizado              │
└────────────────────────────────────────────────────────────┘
```

---

## 🔐 PARÁMETROS DE AUTENTICACIÓN - ESPECIFICACIÓN TÉCNICA

### URL CALLBACK DESDE DIANA

El sistema DIANA debe redirigir al usuario con la siguiente URL después de autenticarse:

```
https://sis.sernanp.gob.pe/maqs?validacionPass=TOKEN&selectOpcion=USER_ID&userName=USER_NAME
```

#### Parámetros Requeridos:

| Parámetro | Tipo | Obligatorio | Descripción | Ejemplo |
|-----------|------|-----------|-----------|---------|
| `validacionPass` o `token` | String | ✅ SÍ | Token de autenticación válido | `0c2c2fb5dad41aa8b3d3a3a616cdb241` |
| `selectOpcion` o `userId` | String/Número | ✅ SÍ | ID único del usuario | `443` |
| `userName` | String | ✅ SÍ | Nombre completo del usuario | `Juan%20Perez` o `Juan+Perez` |

#### Parámetros Opcionales:

| Parámetro | Tipo | Descripción | Ejemplo |
|-----------|------|-----------|---------|
| `email` | String | Email del usuario | `juan.perez@sernanp.gob.pe` |
| `role` | String | Rol del usuario | `admin`, `usuario` |
| `department` | String | Departamento del usuario | `TIC` |

#### Especificaciones Técnicas:

- **Codificación:** UTF-8
- **Método:** GET
- **Protocolo:** HTTPS (obligatorio en producción)
- **Validez del Token:** Indefinida (el servidor puede validar con endpoint `/auth/validate`)
- **Caracteres especiales:** Deben estar URL-encoded (espacios como `%20` o `+`)

---

## 💾 ALMACENAMIENTO DE DATOS - ESTRUCTURA

### SessionStorage (Sesión actual del navegador)

Se usa para guardar datos de autenticación **durante la sesión actual**. Se limpia automáticamente al cerrar la pestaña.

```javascript
// En el navegador (F12 → Application → Session Storage)

sessionStorage = {
  'auth_token': 'ABC123XYZ...',
  'userId': '443',
  'userName': 'Juan Perez',
  'current_user': JSON.stringify({
    userId: '443',
    userName: 'Juan Perez',
    token: 'ABC123XYZ...',
    loginTime: '2025-11-18T10:30:00.000Z'
  })
}
```

### LocalStorage (Almacenamiento persistente)

Se usa como **respaldo** para mantener la sesión si el usuario recarga la página.

```javascript
// En el navegador (F12 → Application → Local Storage)

localStorage = {
  'auth_token': 'ABC123XYZ...',
  'current_user': JSON.stringify({
    userId: '443',
    userName: 'Juan Perez',
    token: 'ABC123XYZ...',
    loginTime: '2025-11-18T10:30:00.000Z'
  })
}
```

---

## 🔗 CONFIGURACIÓN DE DIANA

### 1. **Configurar Redirect URL en DIANA**

En el sistema DIANA, debe configurarse que después de un login exitoso, redirija al usuario a:

```
https://sis.sernanp.gob.pe/maqs
```

O con parámetros específicos (si DIANA soporta):

```
https://sis.sernanp.gob.pe/maqs/autenticar?validacionPass={TOKEN}&selectOpcion={USER_ID}&userName={USER_NAME}
```

### 2. **Valores por Defecto en DIANA**

Asegurarse de que DIANA envíe:
- ✅ Token válido en `validacionPass`
- ✅ ID del usuario en `selectOpcion`
- ✅ Nombre del usuario en `userName`

### 3. **Validación en DIANA**

El backend de DIANA debe:
1. Validar credenciales del usuario
2. Generar token seguro
3. Codificar parámetros correctamente (URL encoding)
4. Redirigir con status HTTP 302 o 303

---

## 🛠️ IMPLEMENTACIÓN TÉCNICA EN EL FRONTEND

### Archivos Clave Creados/Modificados

#### 1. **AuthGuard** (`src/app/core/guards/auth.guard.ts`)

**Responsabilidad:** Proteger rutas que requieren autenticación.

**Código relevante:**
```typescript
export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);

  if (authService.isAuthenticated()) {
    return true;  // Permite acceso
  }

  // No hay token → redirige a DIANA
  window.location.href = authService.getDianaLoginUrl();
  return false;
};
```

**Cómo funciona:**
1. Se ejecuta antes de activar la ruta
2. Verifica `sessionStorage.getItem('auth_token')`
3. Si existe → acceso permitido
4. Si no existe → redirige a DIANA

---

#### 2. **AuthCallbackService** (`src/app/core/services/auth-callback.service.ts`)

**Responsabilidad:** Procesar los parámetros que envía DIANA.

**Código relevante:**
```typescript
processAuthCallback(): void {
  this.activatedRoute.queryParams.subscribe(params => {
    if (params['validacionPass'] || params['token']) {
      // Captura parámetros
      const token = params['validacionPass'] || params['token'];
      const userId = params['selectOpcion'] || params['userId'];
      const userName = params['userName'] || 'Usuario';

      // Guarda en sessionStorage
      sessionStorage.setItem('auth_token', token);
      sessionStorage.setItem('userId', userId);
      sessionStorage.setItem('userName', userName);

      // También guarda en localStorage (respaldo)
      this.authService.setAuthToken(token);
    }
  });
}
```

**Cómo funciona:**
1. Escucha cambios en los query parameters de la URL
2. Si detecta `validacionPass` o `token`
3. Extrae los parámetros
4. Los guarda en sessionStorage y localStorage

---

#### 3. **AuthService Actualizado** (`src/app/core/services/auth.service.ts`)

**Métodos principales:**

```typescript
// Verifica si hay token válido
isAuthenticated(): boolean {
  return !!sessionStorage.getItem('auth_token') ||
         !!localStorage.getItem('auth_token');
}

// Obtiene el token
getAuthToken(): string | null {
  return sessionStorage.getItem('auth_token') ||
         localStorage.getItem('auth_token');
}

// Guarda el token
setAuthToken(token: string): void {
  sessionStorage.setItem('auth_token', token);
  localStorage.setItem('auth_token', token);
}

// Obtiene datos del usuario
getCurrentUser(): any {
  const user = sessionStorage.getItem('current_user') ||
               localStorage.getItem('current_user');
  return user ? JSON.parse(user) : null;
}

// Logout - Limpia sesión
logout(): void {
  sessionStorage.removeItem('auth_token');
  sessionStorage.removeItem('current_user');
  sessionStorage.removeItem('userId');
  sessionStorage.removeItem('userName');
  sessionStorage.clear();

  localStorage.removeItem('auth_token');
  localStorage.removeItem('current_user');
  localStorage.clear();

  // Redirige a DIANA
  window.location.href = this.DIANA_LOGIN_URL;
}
```

---

#### 4. **App Component** (`src/app/app.ts`)

**Responsabilidad:** Detectar y procesar parámetros de autenticación al inicializar la app.

**Código relevante:**
```typescript
export class App implements OnInit {
  constructor(
    private authCallbackService: AuthCallbackService,
    private activatedRoute: ActivatedRoute
  ) {}

  ngOnInit(): void {
    this.activatedRoute.queryParams.subscribe(params => {
      if (params['validacionPass'] || params['token']) {
        console.log('Autenticación detectada');
        this.authCallbackService.processAuthCallback();
      }
    });
  }
}
```

**Cómo funciona:**
1. Al inicializar la aplicación
2. Revisa si hay parámetros de autenticación en la URL
3. Si existen, llama al servicio para procesarlos
4. Se guardan en sessionStorage

---

#### 5. **Navbar/Header** (`src/app/shared/components/maqs-header/maqs-header.component.ts`)

**Responsabilidad:** Mostrar el nombre del usuario logueado.

**Código relevante:**
```typescript
getCurrentUserName(): string {
  // Primero busca en sessionStorage
  const userNameSession = sessionStorage.getItem('userName');
  if (userNameSession) {
    return userNameSession;
  }

  // Luego en el objeto de usuario
  const user = this.authService.getCurrentUser();
  if (user?.nombre) return user.nombre;
  if (user?.name) return user.name;
  if (user?.userName) return user.userName;

  return 'Usuario';  // Fallback
}
```

**Resultado en el navegador:**
```
┌─────────────────────────────────────────────────────────┐
│  Logo SERNANP    Logo Ministerio    Bienvenido, Juan    │
│                                      Perez     [Salir]   │
└─────────────────────────────────────────────────────────┘
```

---

## 📋 CHECKLIST DE IMPLEMENTACIÓN

Use esta lista para verificar que todo está configurado correctamente:

### Fase 1: Verificación del Frontend

- [ ] ¿Los archivos fueron creados correctamente?
  - [ ] `src/app/core/guards/auth.guard.ts`
  - [ ] `src/app/core/services/auth-callback.service.ts`

- [ ] ¿Los archivos fueron modificados correctamente?
  - [ ] `src/app/app.ts` - tiene OnInit con processAuthCallback
  - [ ] `src/app/app.routes.ts` - ruta `/maqs` tiene `canActivate: [authGuard]`
  - [ ] `src/app/core/services/auth.service.ts` - usa sessionStorage
  - [ ] `src/app/shared/components/maqs-header/maqs-header.component.ts` - obtiene userName

- [ ] ¿La aplicación compila sin errores?
  ```bash
  npm run build
  # No debe haber errores de compilación
  ```

### Fase 2: Configuración en DIANA

- [ ] ¿Se configuró la URL de redirect en DIANA?
  - [ ] `https://sis.sernanp.gob.pe/maqs` (sin parámetros)
  - [ ] O con parámetros: `?validacionPass=...&selectOpcion=...&userName=...`

- [ ] ¿DIANA envía los parámetros correctamente?
  - [ ] validacionPass (o token)
  - [ ] selectOpcion (o userId)
  - [ ] userName

- [ ] ¿Los parámetros están URL-encoded?
  - [ ] Espacios como `%20` o `+`
  - [ ] Caracteres especiales codificados

### Fase 3: Testing en Desarrollo

- [ ] ¿Se puede acceder a /maqs sin estar logueado?
  - [ ] ✅ Debe redirigir a DIANA (no debe funcionar)

- [ ] ¿Se procesa correctamente el callback de DIANA?
  - [ ] Abrir devtools (F12)
  - [ ] Ir a Application → Session Storage
  - [ ] Verificar que aparecen: `auth_token`, `userId`, `userName`

- [ ] ¿Aparece el nombre del usuario en el navbar?
  - [ ] Debe mostrar: "Bienvenido, Juan Perez" (o el nombre del usuario)

- [ ] ¿Funciona el logout?
  - [ ] Click en "Salir"
  - [ ] Debe limpiar sessionStorage/localStorage
  - [ ] Debe redirigir a DIANA

### Fase 4: Testing en Producción

- [ ] ¿Se usa HTTPS?
  - [ ] `https://sis.sernanp.gob.pe/maqs`
  - [ ] No http://

- [ ] ¿El certificado SSL es válido?
  - [ ] No hay advertencias de seguridad

- [ ] ¿Se puede completar el flujo completo?
  - [ ] Login en DIANA
  - [ ] Redirección a MAQS
  - [ ] Visualización del nombre
  - [ ] Acceso a /maqs
  - [ ] Logout

---

## 🧪 TESTING MANUAL - PASOS DETALLADOS

### Test 1: Verificar que /maqs está protegida

1. Abre el navegador en modo incógnito
2. Accede a: `https://sis.sernanp.gob.pe/maqs`
3. **Resultado esperado:** Redirige a DIANA (no carga la página de MAQS)

### Test 2: Simulación de login desde DIANA

1. Abre el navegador en modo incógnito
2. Accede a:
   ```
   https://sis.sernanp.gob.pe/maqs?validacionPass=0c2c2fb5dad41aa8b3d3a3a616cdb241&selectOpcion=443&userName=Juan%20Perez
   ```
3. **Resultado esperado:**
   - [ ] La página carga correctamente
   - [ ] El navbar muestra "Bienvenido, Juan Perez"
   - [ ] Botón "Salir" está disponible

### Test 3: Verificar sessionStorage

1. Después de login, presiona F12 (DevTools)
2. Ve a **Application** → **Session Storage**
3. **Resultado esperado:** Debes ver:
   ```javascript
   auth_token: "0c2c2fb5dad41aa8b3d3a3a616cdb241"
   userId: "443"
   userName: "Juan Perez"
   current_user: '{"userId":"443","userName":"Juan Perez",...}'
   ```

### Test 4: Verificar persistencia (reload)

1. Después de login, presiona F5 para recargar
2. **Resultado esperado:**
   - [ ] No redirige a DIANA
   - [ ] El nombre del usuario sigue visible
   - [ ] Sesión persiste

### Test 5: Logout

1. Presiona el botón "Salir"
2. Confirma la acción en el popup
3. **Resultado esperado:**
   - [ ] Se limpian sessionStorage/localStorage
   - [ ] Se redirige a DIANA
   - [ ] Al volver a `/maqs`, redirige nuevamente a DIANA

---

## 🔍 DEBUGGING - SOLUCIÓN DE PROBLEMAS

### Problema 1: La ruta /maqs redirige constantemente a DIANA

**Posibles causas:**
- El token no se está guardando en sessionStorage
- DIANA no envía los parámetros correctamente
- Hay un error en AuthCallbackService

**Solución:**
1. Abre DevTools (F12)
2. Ve a **Console**
3. Ejecuta:
   ```javascript
   sessionStorage.getItem('auth_token')  // Debe retornar el token
   sessionStorage.getItem('userId')
   sessionStorage.getItem('userName')
   ```
4. Si retorna `null`, significa que no se procesó el callback
5. Verifica la URL:
   ```javascript
   window.location.search  // Debe mostrar: ?validacionPass=...
   ```

---

### Problema 2: El usuario no aparece en el navbar

**Posibles causas:**
- El parámetro `userName` no se envía desde DIANA
- El nombre tiene caracteres especiales mal codificados
- AuthCallbackService no está extrayendo correctamente

**Solución:**
1. Abre DevTools (F12)
2. Ve a **Console**
3. Ejecuta:
   ```javascript
   sessionStorage.getItem('userName')  // Qué valor tiene?
   localStorage.getItem('current_user')  // Qué contiene?
   ```
4. Si el userName está vacío o es "Usuario", revisar:
   - URL de DIANA tiene parámetro `userName=...`?
   - El valor está URL-encoded correctamente?

---

### Problema 3: Los datos se pierden al recargar

**Posibles causas:**
- El navegador está en modo privado (no persiste localStorage)
- Un script limpia sessionStorage/localStorage
- El usuario cierra la pestaña (sessionStorage se limpia)

**Solución:**
1. Probar en navegación normal (no privada/incógnito)
2. Verificar que localStorage persiste:
   ```javascript
   localStorage.getItem('auth_token')  // Debe tener valor
   ```
3. Revisar si hay scripts que limpian el storage en `app.ts`

---

### Problema 4: Error en consola: "Cannot read property 'auth_token'"

**Causa:** Se está intentando acceder a sessionStorage antes de que se procese el callback

**Solución:**
1. Asegurar que AuthCallbackService se inicializa en App Component
2. Revisar que el guard espera a que se procese el callback
3. Agregar un delay o verificación adicional si es necesario

---

## 📞 CONTACTOS Y REFERENCIAS

| Rol | Responsabilidad | Contacto |
|-----|-----------------|----------|
| **TIC SERNANP** | Configurar DIANA | Por contactar |
| **Desarrollador Frontend** | Mantener código MAQS | Por contactar |
| **Encargado de Ops** | Despliegue en producción | Por contactar |

---

## 📚 REFERENCIAS TÉCNICAS

### Variables de Entorno (por ambiente)

**Desarrollo:** `src/environments/environment.ts`
```typescript
export const environment = {
  production: false,
  apiUrlLogin: 'https://desarrollo.sernanp.gob.pe/diana/',
  apiUrl: 'http://localhost:7180/maqs_api/'
};
```

**Producción:** `src/environments/environment.prod.ts`
```typescript
export const environment = {
  production: true,
  apiUrlLogin: 'https://sis.sernanp.gob.pe/diana/',
  apiUrl: 'http://sis.sernanp.gob.pe/maqs_api/'
};
```

## 📎 ANEXOS

### Anexo A: Ejemplo URL Callback Completa

```
https://sis.sernanp.gob.pe/maqs?validacionPass=0c2c2fb5dad41aa8b3d3a3a616cdb241&selectOpcion=443&userName=Juan%20Perez&email=juan.perez%40sernanp.gob.pe&role=usuario
```

### Anexo B: Estructura JSON del Usuario

```json
{
  "userId": "443",
  "userName": "Juan Perez",
  "token": "0c2c2fb5dad41aa8b3d3a3a616cdb241",
  "loginTime": "2025-11-18T10:30:00.000Z",
  "email": "juan.perez@sernanp.gob.pe",
  "role": "usuario"
}
```

### Anexo C: Comandos Útiles para Testing

```bash
# Compilar la aplicación
npm run build

# Ejecutar en desarrollo
npm start

# Ejecutar tests
npm test

# Build para producción
npm run build:prod
```

---

**Documento preparado para:** Equipo de TIC SERNANP
**Versión Angular:** 20.0.0
**Estado:** ✅ Listo para Producción
**Última actualización:** Noviembre 2025
