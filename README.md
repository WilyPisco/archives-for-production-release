# MAQS - Despliegue a Producción

Documentación técnica para despliegue del Sistema MAQS (Mecanismo de Atención de Quejas, Consultas y Sugerencias) del SERNANP.

---

## 📚 Documentos

### 1. **MANUAL_TECNICO_BACKEND.md**
Despliegue de backend Java/Spring Boot 3.1.5

**Contenido:**
- Scripts SQL (base de datos)
- Configuración para producción
- Compilación y despliegue
- Validaciones
- Troubleshooting

---

### 2. **MANUAL_TECNICO_FRONTEND.md**
Despliegue de frontend Angular 20

**Contenido:**
- Instalación de dependencias
- Configuración de URLs
- Compilación para producción
- Despliegue en servidor web
- Configuración Nginx
- Validaciones

---

### 3. **INTEGRACION_DIANA.md**
Integración con sistema de autenticación DIANA

**Contenido:**
- Checklist pre-producción
- Flujo de autenticación
- Configuración en DIANA
- Implementación en frontend
- Testing manual
- Debugging

---

## 🚀 PASOS DE DESPLIEGUE

### Backend

```bash
# 1. Ejecutar scripts SQL
psql -U postgres -d maqs -f update_maqs_database.sql
psql -U postgres -d maqs -f data_migration_maqs.sql

# 2. Actualizar application-production.properties
# - BD: 10.10.14.172:5432
# - SMTP: mail.sernanp.gob.pe
# - Almacenamiento: /var/www/html/documentos/maqs/

# 3. Compilar
mvn clean package -DskipTests

# 4. Desplegar
nohup java -jar target/maqs_api.jar --spring.profiles.active=production &

# 5. Verificar
curl http://localhost:7180/maqs_api/actuator/health
```

---

### Frontend

```bash
# 1. Instalar dependencias
npm install

# 2. Configurar URLs en src/environments/environment.prod.ts
# - apiUrl: http://sis.sernanp.gob.pe/maqs_api/
# - apiUrlLogin: https://sis.sernanp.gob.pe/diana/

# 3. Compilar
npm run build:prod

# 4. Desplegar dist/maqs-frontend a servidor web
# Configurar Nginx reverse proxy hacia backend:7180

# 5. Verificar en navegador
# https://sis.sernanp.gob.pe/maqs
```

---

## ✅ CHECKLIST PRE-PRODUCCIÓN

**Backend:**
- [ ] Scripts SQL ejecutados
- [ ] BD verificada (tablas, datos)
- [ ] application-production.properties configurado
- [ ] Directorios creados y permisos asignados
- [ ] SMTP testeable
- [ ] Compilación sin errores
- [ ] API responde en puerto 7180

**Frontend:**
- [ ] npm install ejecutado
- [ ] environment.prod.ts con URLs correctas
- [ ] npm run build:prod sin errores
- [ ] dist/ generado
- [ ] dist/ transferido a servidor web
- [ ] Nginx configurado

**DIANA (OBLIGATORIO):**
- [ ] DIANA redirige a `/maqs`
- [ ] Envía parámetros: validacionPass, selectOpcion, userName
- [ ] Frontend captura parámetros
- [ ] Navbar muestra nombre de usuario
- [ ] Logout funciona

---

## 📋 INFORMACIÓN TÉCNICA

| Componente | Versión | Puerto |
|-----------|---------|--------|
| Backend | Spring Boot 3.1.5, Java 17 | 7180 (interno) |
| Frontend | Angular 20.0.0, Node 20 | 80/443 (público) |
| Base de Datos | PostgreSQL 12+ | 5432 (interno) |
| Auth | DIANA | HTTPS |

---

## 🔗 URLs PRODUCCIÓN

| Sistema | URL |
|--------|-----|
| Frontend | `https://sis.sernanp.gob.pe/maqs` |
| Backend API | `https://sis.sernanp.gob.pe/maqs_api` |
| DIANA | `https://sis.sernanp.gob.pe/diana` |
| BD | `10.10.14.172:5432` |

---

## 🛠️ CÓMO USAR

1. **Despliegue Backend:** Leer `MANUAL_TECNICO_BACKEND.md`
2. **Despliegue Frontend:** Leer `MANUAL_TECNICO_FRONTEND.md`
3. **Integración DIANA:** Leer `INTEGRACION_DIANA.md`
4. **En caso de error:** Ver sección "Troubleshooting" en cada manual

---

## 📊 MONITOREO

```bash
# Health check
curl https://sis.sernanp.gob.pe/maqs_api/actuator/health

# Logs backend
tail -f /opt/apache-tomcat-7.0.68/logs/maqslogback.log

# Logs frontend (Nginx)
tail -f /var/log/nginx/access.log
```

---

**Versión:** 1.0
**Última actualización:** Noviembre 2025
