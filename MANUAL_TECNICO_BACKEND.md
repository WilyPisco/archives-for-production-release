# MANUAL TÉCNICO BACKEND - DESPLIEGUE A PRODUCCIÓN
## Sistema MAQS - Spring Boot 3.1.5 + Java 17 + PostgreSQL

**Versión:** 1.0.0
**Fecha:** Noviembre 2025
**Destinatario:** Equipo TIC

---

## TABLA DE CONTENIDOS

1. [Scripts de Base de Datos](#1-scripts-de-base-de-datos)
2. [Configuración para Producción](#2-configuración-para-producción)
3. [Proceso de Despliegue](#3-proceso-de-despliegue)
4. [Validaciones Post-Despliegue](#4-validaciones-post-despliegue)

---

## 1. SCRIPTS DE BASE DE DATOS

**ANTES de iniciar la aplicación, ejecutar obligatoriamente:**

```bash
# Script 1: Crear estructura de BD
psql -U postgres -d maqs -f update_maqs_database.sql

# Script 2: Cargar datos maestros
psql -U postgres -d maqs -f data_migration_maqs.sql
```

**Verificar:**
```sql
SELECT COUNT(*) FROM TABLATIPO;        -- Debe ser >= 50
SELECT COUNT(*) FROM T_TEMA_RECLAMO;   -- Debe ser >= 10
```

---

## 2. CONFIGURACIÓN PARA PRODUCCIÓN

Actualizar `application-production.properties`:

### Base de Datos
```properties
spring.datasource.url=jdbc:postgresql://10.10.14.172:5432/maqs
spring.datasource.username=postgres
spring.datasource.password=ACJJDP
```

### Almacenamiento de Archivos
```properties
maqs.upload.dir=/var/www/html/documentos/maqs/
maqs.upload.tempDir=/var/www/html/documentos/maqs/temp
maqs.upload.maxFileSize=10485760
```

**Crear directorios:**
```bash
mkdir -p /var/www/html/documentos/maqs/
mkdir -p /var/www/html/documentos/maqs/temp
chown -R tomcat:tomcat /var/www/html/documentos/maqs/
chmod -R 755 /var/www/html/documentos/maqs/
```

### Correo SMTP
```properties
spring.mail.host=mail.sernanp.gob.pe
spring.mail.port=25
spring.mail.username=dvaldez@sernanp.gob.pe
spring.mail.password=******************
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true
```

### Activar Perfil Producción
```properties
spring.profiles.active=production
```

---

## 3. PROCESO DE DESPLIEGUE

### Compilación
```bash
cd maqs-backend
mvn clean package -DskipTests
```

### Despliegue
```bash
# Opción 1: Ejecución directa
java -jar target/maqs_api.jar --spring.profiles.active=production

# Opción 2: Con nohup (background)
nohup java -jar target/maqs_api.jar --spring.profiles.active=production > /opt/maqs/maqs_api.log 2>&1 &

# Opción 3: Desplegar en Tomcat existente
cp target/maqs_api.war /opt/apache-tomcat-7.0.68/webapps/
```

---

## 4. VALIDACIONES POST-DESPLIEGUE

### Health Check
```bash
curl -X GET http://localhost:7180/maqs_api/actuator/health
# Respuesta esperada: {"status":"UP"}
```

### Swagger/API Docs
```
http://localhost:7180/maqs_api/swagger-ui.html
```

### Conexión a Base de Datos
```bash
psql -U postgres -d maqs -c "SELECT VERSION();"
```

### Crear Reclamo de Prueba
```bash
curl -X POST http://localhost:7180/maqs_api/reclamos/crear \
  -H "Content-Type: application/json" \
  -d '{
    "int_tipo_canal_reclamo": 261,
    "var_descripcion_reclamo": "Prueba",
    "var_nombre_persona": "Test",
    "var_apellido_persona": "User",
    "var_email_persona": "test@example.com",
    "var_telefono_persona": "123456789",
    "int_tipo_documento_persona": 1,
    "var_numero_documento_persona": "12345678"
  }'
```
**Fin del Manual**
**Versión:** 1.0.0
**Última actualización:** 19 Noviembre 2025
