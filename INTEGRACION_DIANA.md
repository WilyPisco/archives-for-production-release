# INTEGRACIÓN DIANA
## Autenticación Centralizado SERNANP

**Versión:** 1.0
**Fecha:** Noviembre 2025

---

## CHECKLIST PRE-PRODUCCIÓN

**DIANA debe estar integrado antes de desplegar:**

- [ ] DIANA redirige a: `https://sis.sernanp.gob.pe/maqs`
- [ ] Envía parámetros: `?validacionPass=TOKEN&selectOpcion=ID&userName=NAME`
- [ ] Frontend captura en sessionStorage
- [ ] Navbar muestra: "Bienvenido, [USUARIO]"
- [ ] AuthGuard protege `/maqs`
- [ ] Logout limpia sesión

---

## CONFIGURACIÓN EN DIANA

### Redirect URL
Configurar DIANA para redirigir a:
```
https://sis.sernanp.gob.pe/maqs
```

### Parámetros Obligatorios
| Parámetro | Valor | Ejemplo |
|-----------|-------|---------|
| `validacionPass` | Token | `ABC123XYZ` |
| `selectOpcion` | ID Usuario | `443` |
| `userName` | Nombre Usuario | `Juan%20Perez` |

**Espacios:** Codificar como `%20`

### URL Callback Ejemplo
```
https://sis.sernanp.gob.pe/maqs?validacionPass=ABC123&selectOpcion=443&userName=Juan%20Perez
```

---

## FLUJO AUTENTICACIÓN

```
Usuario sin auth
    ↓
Intenta acceder a /maqs
    ↓
AuthGuard verifica token
    ↓ NO existe
Redirige a DIANA
    ↓
Usuario hace login en DIANA
    ↓
DIANA redirige con parámetros
    ↓
AuthCallbackService procesa
    ↓
Guarda en sessionStorage/localStorage
    ↓
Navbar muestra nombre
    ↓
Acceso a /maqs permitido
```

---

## ARCHIVOS FRONTEND

1. **AuthGuard** (`src/app/core/guards/auth.guard.ts`)
   - Verifica token en sessionStorage
   - Redirige a DIANA si no existe

2. **AuthCallbackService** (`src/app/core/services/auth-callback.service.ts`)
   - Procesa parámetros de URL
   - Guarda en sessionStorage/localStorage

3. **AuthService** (`src/app/core/services/auth.service.ts`)
   - Métodos: isAuthenticated(), logout()

4. **App Component** (`src/app/app.ts`)
   - Detecta parámetros al inicializar
   - Llama AuthCallbackService.processAuthCallback()

5. **Navbar** (`src/app/shared/components/maqs-header/`)
   - Obtiene y muestra nombre de usuario
   - Botón logout

---

## ALMACENAMIENTO

### SessionStorage (Sesión actual)
```javascript
{
  'auth_token': 'ABC123XYZ...',
  'userId': '443',
  'userName': 'Juan Perez'
}
```
Se limpia al cerrar pestaña.

### LocalStorage (Respaldo)
```javascript
{
  'auth_token': 'ABC123XYZ...',
  'current_user': '{...}'
}
```
Persiste entre recargas.

---

## TESTING

### Test 1: Ruta Protegida
```bash
curl -I https://sis.sernanp.gob.pe/maqs
# Debe redirigir a DIANA
```

### Test 2: Callback Simulado
Acceder a:
```
https://sis.sernanp.gob.pe/maqs?validacionPass=ABC123&selectOpcion=443&userName=Juan%20Perez
```

**Resultado esperado:**
- ✅ Página carga
- ✅ Navbar: "Bienvenido, Juan Perez"
- ✅ Botón Salir disponible

### Test 3: SessionStorage
1. F12 (DevTools)
2. Application → Session Storage
3. Verificar: auth_token, userId, userName

### Test 4: Recarga
1. F5 en página
2. **Resultado esperado:**
   - ✅ No redirige a DIANA
   - ✅ Nombre sigue visible

### Test 5: Logout
1. Click en "Salir"
2. **Resultado esperado:**
   - ✅ sessionStorage/localStorage limpios
   - ✅ Redirige a DIANA
   - ✅ Acceso a /maqs nuevamente redirige a DIANA

---

## DEBUGGING

### /maqs redirige constantemente a DIANA
```javascript
// En DevTools Console:
sessionStorage.getItem('auth_token')  // Debe tener valor
window.location.search  // Debe mostrar ?validacionPass=...
```

### Usuario no aparece en navbar
```javascript
sessionStorage.getItem('userName')
```
**Causa:** DIANA no envía `userName` o está mal encoded.

### Datos se pierden al recargar
- Verificar localStorage está guardando
- Navegador en modo privado no persiste localStorage
- Revisar scripts limpien storage

### Logout no funciona
- Verificar logout() limpia sessionStorage
- Verificar logout() limpia localStorage
- Verificar logout() redirige a DIANA

---

## VARIABLES ENTORNO

**Desarrollo:** `src/environments/environment.ts`
```typescript
apiUrlLogin: 'https://desarrollo.sernanp.gob.pe/diana/'
```

**Producción:** `src/environments/environment.prod.ts`
```typescript
apiUrlLogin: 'https://sis.sernanp.gob.pe/diana/'
```

---

## CÓDIGO REFERENCIA

### AuthCallbackService
```typescript
processAuthCallback(): void {
  this.activatedRoute.queryParams.subscribe(params => {
    if (params['validacionPass'] || params['token']) {
      const token = params['validacionPass'] || params['token'];
      const userId = params['selectOpcion'] || params['userId'];
      const userName = params['userName'] || 'Usuario';

      sessionStorage.setItem('auth_token', token);
      sessionStorage.setItem('userId', userId);
      sessionStorage.setItem('userName', userName);
    }
  });
}
```

### AuthGuard
```typescript
export const authGuard: CanActivateFn = (route, state) => {
  const authService = inject(AuthService);

  if (authService.isAuthenticated()) {
    return true;
  }

  window.location.href = authService.getDianaLoginUrl();
  return false;
};
```

---

**Fin de Guía DIANA**
**Versión:** 1.0
**Última actualización:** 19 Noviembre 2025
