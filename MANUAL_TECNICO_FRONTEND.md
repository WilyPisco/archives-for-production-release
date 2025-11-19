# MANUAL TÉCNICO FRONTEND - DESPLIEGUE A PRODUCCIÓN
## Sistema MAQS - Angular 20.0.0 + Node.js 20

**Versión:** 1.0
**Fecha:** Noviembre 2025
**Destinatario:** Equipo TIC

---

## TABLA DE CONTENIDOS

1. [Instalación de Dependencias](#1-instalación-de-dependencias)
2. [Configuración para Producción](#2-configuración-para-producción)
3. [Compilación para Producción](#3-compilación-para-producción)
4. [Despliegue](#4-despliegue)
5. [Validaciones Post-Despliegue](#5-validaciones-post-despliegue)

---

## 1. INSTALACIÓN DE DEPENDENCIAS

### Verificar Versiones Requeridas
```bash
node --version    # Debe ser >= 18.0.0
npm --version     # Debe ser >= 8.0.0
```

### Instalar Dependencias del Proyecto
```bash
cd maqs-frontend
npm install
```

---

## 2. CONFIGURACIÓN PARA PRODUCCIÓN

Actualizar `src/environments/environment.prod.ts`:

```typescript
export const environment = {
  production: true,
  apiUrl: 'http://sis.sernanp.gob.pe/maqs_api/',
  apiUrlLogin: 'https://sis.sernanp.gob.pe/diana/',
  url_video_tutorial: 'https://youtube.com/...',
  version: '2.0.0 - DD-MMM-YYYY'
};
```

**Variables Críticas:**
- `apiUrl`: URL del backend (MAQS API)
- `apiUrlLogin`: URL de DIANA (autenticación)
- `production`: Debe ser `true`

---

## 3. COMPILACIÓN PARA PRODUCCIÓN

### Compilar
```bash
npm run build:prod
```

O manualmente:
```bash
ng build --configuration production
```

### Verificar Compilación
```bash
# Archivos generados en: dist/maqs-frontend/
ls -lah dist/maqs-frontend/

# Debe incluir:
# - index.html
# - main.*.js (bundle principal)
# - styles.*.css
# - assets/
```

---

## 4. DESPLIEGUE

### Transferir a Servidor Web
```bash
# Copiar contenido de dist/maqs-frontend/ a servidor web
# Opción 1: scp
scp -r dist/maqs-frontend/* usuario@servidor:/var/www/html/maqs/

# Opción 2: rsync
rsync -avz dist/maqs-frontend/ usuario@servidor:/var/www/html/maqs/
```

### Configurar Nginx (Reverse Proxy)
```nginx
upstream maqs_backend {
    server localhost:7180;
}

server {
    listen 80;
    server_name sis.sernanp.gob.pe;

    # Servir archivos estáticos del frontend
    location / {
        root /var/www/html/maqs;
        index index.html;
        try_files $uri $uri/ /index.html;
    }

    # Proxy hacia backend
    location /maqs_api/ {
        proxy_pass http://maqs_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Proxy hacia DIANA
    location /diana/ {
        proxy_pass https://sistema-diana.internal/diana/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Recargar Nginx
```bash
nginx -s reload
# O
systemctl reload nginx
```

---

## 5. VALIDACIONES POST-DESPLIEGUE

### Acceso a la Aplicación
```bash
# Frontend debe cargarse en:
curl http://localhost/maqs
# Respuesta: HTML de index.html
```

### Verificar Backend Accesible
```bash
# A través del proxy
curl http://localhost/maqs_api/actuator/health
# Respuesta esperada: {"status":"UP"}
```

### Verificar Configuración DIANA
```bash
# Acceder a /maqs sin autenticar debe redirigir a DIANA
curl -I http://localhost/maqs
# Debe obtener redirección a DIANA
```

### Verificar Autenticación
1. Acceder a: `https://sis.sernanp.gob.pe/maqs`
2. Debe redirigir a DIANA
3. Después de login, debe redirigir con parámetros:
   `?validacionPass=TOKEN&selectOpcion=ID&userName=NAME`
4. Debe mostrar: "Bienvenido, [NOMBRE]" en navbar

---

## IMPORTANTE: DIANA INTEGRACIÓN

**Antes de producción, verificar en INTEGRACION_DIANA.md que:**
- [ ] DIANA redirige a `/maqs`
- [ ] Envía parámetros: `validacionPass`, `selectOpcion`, `userName`
- [ ] Frontend captura y almacena en sessionStorage
- [ ] Navbar muestra nombre del usuario
- [ ] Logout funciona correctamente

---

**Fin del Manual**
**Versión:** 1.0
**Última actualización:** 19 Noviembre 2025
