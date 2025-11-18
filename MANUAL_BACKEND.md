# MANUAL TÉCNICO PARA PASE A PRODUCCIÓN
## Sistema MAQS - Mecanismo de Atención de Quejas, Consultas y Sugerencias
### SERNANP - Servicio Nacional de Áreas Naturales Protegidas

**Versión:** 1.0.0
**Fecha:** Noviembre 2025
**Destinatario:** Área de Tecnología de Información (TIC)

---

## TABLA DE CONTENIDOS

1. [Descripción General del Sistema](#1-descripción-general-del-sistema)
2. [Requisitos Previos](#2-requisitos-previos)
3. [Scripts de Base de Datos](#3-scripts-de-base-de-datos)
4. [Arquitectura Técnica](#4-arquitectura-técnica)
5. [Componentes del Sistema](#5-componentes-del-sistema)
6. [Configuración para Producción](#6-configuración-para-producción)
7. [Proceso de Despliegue](#7-proceso-de-despliegue)
8. [Validaciones Post-Despliegue](#8-validaciones-post-despliegue)
9. [Monitoreo y Mantenimiento](#9-monitoreo-y-mantenimiento)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. DESCRIPCIÓN GENERAL DEL SISTEMA

### 1.1 Propósito
MAQS es una aplicación backend que implementa un sistema integral de gestión de reclamos, quejas, consultas y sugerencias para el SERNANP. Permite:

- Recepción de reclamos por múltiples canales (físico, virtual, telefónico)
- Generación automática de PDF de confirmación y respuesta
- Envío de correos con caracteres españoles (tildes, ñ, °)
- Generación de reportes en PDF y Excel
- Búsqueda y filtrado avanzado de reclamos
- Auditoria completa de operaciones

### 1.2 Tecnología Base
- **Framework:** Spring Boot 3.1.5
- **Lenguaje:** Java 17
- **Base de Datos:** PostgreSQL 12+
- **ORM/SQL Mapping:** MyBatis 3.0.2
- **Reportes:** Jasper Reports 6.20.6
- **Gestión de Dependencias:** Maven 3.6+
- **Servidor de Aplicaciones:** Embedded Tomcat (en Spring Boot)
- **Documentación API:** Swagger/OpenAPI 3.0

---

## 2. REQUISITOS PREVIOS

### 2.1 Hardware Mínimo Recomendado
| Recurso | Especificación |
|---------|----------------|
| CPU | 2 cores (mínimo 2.0 GHz) |
| RAM | 4 GB (mínimo 2 GB) |
| Disco | 500 MB (código) + espacio para documentos |
| Almacenamiento | SSD recomendado para mejor rendimiento |

### 2.2 Software Requerido

#### Sistema Operativo
- Linux (recomendado CentOS 7+ o Ubuntu 18.04+)
- O Windows Server 2016+

#### Java
```
Java Development Kit (JDK) 17 o superior
Verificar: java -version
```

#### PostgreSQL
```
PostgreSQL 12 o superior
Verificar conexión: psql -U postgres -h localhost
```

#### Otros Tools (para compilación)
- Maven 3.6 o superior
- Git (opcional, para versionado)

### 2.3 Requisitos de Red
- Acceso a base de datos PostgreSQL (puerto 5432 por defecto)
- Acceso a servidor SMTP para correos (puerto 25 o 465)
- Acceso HTTP/HTTPS (puertos 80/443 para usuario final, 7180 internamente)

---

## 3. SCRIPTS DE BASE DE DATOS

### 3.1 PASO CRÍTICO: EJECUTAR SCRIPTS ANTES DE INICIAR LA APLICACIÓN

**IMPORTANTE:** Antes de cualquier operación, debe ejecutar los siguientes scripts SQL en orden:

#### 3.1.1 Script 1: `update_bd_.sql`
```
Propósito: Crear/actualizar estructura de base de datos
Ejecutar: psql -U postgres -d maqs -f update_bd_.sql
Acciones:
  - Crea tablas de reclamos
  - Crea tablas de personas/reclamantes
  - Crea tablas de archivos
  - Crea tablas de referencia (códigos, temas)
  - Crea secuencias numéricas
  - Define claves primarias y foráneas
```

#### 3.1.2 Script 2: `update_data_maqs.sql`
```
Propósito: Cargar datos maestros y de referencia
Ejecutar: psql -U postgres -d maqs -f update_data_maqs.sql
Acciones:
  - Inserta códigos de canales (260=Físico, 261=Virtual, 262=Teléfono)
  - Inserta estados de reclamos (263=Registrado, 264=Atendido, 265=Anulado)
  - Inserta tipos de documentos
  - Inserta temas/categorías de reclamos
  - Inicializa secuencias numéricas
  - Inserta datos de configuración
```

### 3.2 Tabla de Esquema
| Tabla | Descripción | Registros Iniciales |
|-------|------------|----------------------|
| T_RECLAMO | Registro principal | Vacío |
| T_PERSONA_RECLAMO | Datos de reclamantes | Vacío |
| T_ARCHIVO | Archivos adjuntos | Vacío |
| T_RECLAMO_EVIDENCIA | Relación reclamo-archivo | Vacío |
| TABLATIPO | Tabla de códigos | ~50 registros (canales, estados, tipos de documento) |
| T_TEMA_RECLAMO | Categorías principales | ~10-15 registros |
| T_TEMA_DETALLE | Subcategorías | ~50-100 registros |
| T_SECUENCIA_NUMERO | Secuencias de numeración | 1 registro (inicializado en 0) |
| USUARIO | Usuarios del sistema | 1 registro (administrador) |

### 3.3 Verificación Post-Script
```sql
-- Verificar que las tablas se crearon:
\dt

-- Verificar que los datos de referencia se insertaron:
SELECT COUNT(*) FROM TABLATIPO;        -- Debe ser >= 50
SELECT COUNT(*) FROM T_TEMA_RECLAMO;   -- Debe ser >= 10
SELECT COUNT(*) FROM T_SECUENCIA_NUMERO; -- Debe ser >= 1
```

---

## 4. ARQUITECTURA TÉCNICA

### 4.1 Patrón de Arquitectura
La aplicación implementa arquitectura **en capas de 3 niveles:**

```
┌─────────────────────────────────────────────────┐
│  CAPA PRESENTACIÓN (REST Controllers)           │
│  - HTTP Endpoints (/maqs_api/reclamos/...)      │
│  - Swagger/OpenAPI Documentation                │
└─────────────────────┬───────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────┐
│  CAPA LÓGICA DE NEGOCIO (Services)              │
│  - Validaciones                                  │
│  - Transformaciones de datos                     │
│  - Orquestación de operaciones                   │
│  - Transacciones                                 │
└─────────────────────┬───────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────┐
│  CAPA PERSISTENCIA (MyBatis Mappers)            │
│  - CRUD Operations                              │
│  - Consultas complejas                          │
│  - Mapeo Objeto-Relacional                      │
└─────────────────────┬───────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────┐
│  BASE DE DATOS (PostgreSQL)                     │
│  - T_RECLAMO, T_PERSONA_RECLAMO, etc.          │
└─────────────────────────────────────────────────┘
```

### 4.2 Patrón de Acceso a Datos
Utiliza **MyBatis con enfoque híbrido:**

1. **CRUD Mappers (10 interfaces)**
   - Operaciones estándar insert/update/delete/select
   - Soporte para patrón Example (SQL dinámico)
   - Auto-generados con herramientas

2. **Query Mappers (10 interfaces)**
   - Consultas complejas con JOINs
   - Formateo de datos (fechas, códigos)
   - Paginación automática
   - DTOs de resultado especializados

### 4.3 Flujo de Datos Típico
```
HTTP Request
    ↓
Controller (validación)
    ↓
Service (lógica negocio)
    ↓
Mapper (BD)
    ↓
PostgreSQL
    ↓
[Respuesta en formato JSON]
```

---

## 5. COMPONENTES DEL SISTEMA

### 5.1 Controladores REST (7 controladores)

#### ReclamoRestController (Principal)
**Endpoints:**
- `POST /maqs_api/reclamos/listar` - Listar reclamos con filtros
- `POST /maqs_api/reclamos/crear` - Crear nuevo reclamo
- `GET /maqs_api/reclamos/{id}` - Obtener detalles del reclamo
- `POST /maqs_api/reclamos/{id}/responder` - Responder a un reclamo
- `GET /maqs_api/reclamos/{id}/descargar-pdf` - Descargar PDF del reclamo
- `POST /maqs_api/reclamos/{id}/eliminar` - Eliminar reclamo (solo admin)

#### CommonsController
Operaciones comunes y datos de referencia.

#### GeneraReportesController
**Endpoints:**
- `POST /maqs_api/reportes/pdf` - Generar reportes en PDF
- `POST /maqs_api/reportes/excel` - Generar reportes en Excel

#### Otros Controladores
- TraduccionRestController
- TTemaDetalleRestController
- TutorialController
- Seguridad

### 5.2 Servicios (23 implementaciones)

#### ReclamoServiceImpl (Principal)
**Responsabilidades:**
1. Crear reclamos (validación, almacenamiento, generación de número único)
2. Listar reclamos (filtrado, paginación)
3. Responder reclamos (actualización de estado)
4. Generar PDFs automáticos
5. Enviar correos de confirmación y respuesta

#### EmailServiceImpl
- Envío de correos con caracteres españoles
- Templates HTML profesionales
- Adjuntos en PDF
- Validación de configuración SMTP

#### FileUploadServiceImpl
- Validación de archivos (tamaño, tipo)
- Almacenamiento en disco
- Gestión de nombres únicos
- Recuperación de archivos

#### GeneraReportesServiceImpl
- Integración con Jasper Reports
- Generación de PDF
- Exportación a Excel
- Descarga de archivos

#### Otros 19 Servicios
Gestión de: traducciones, temas, tutoriales, seguridad, datos comunes, etc.

### 5.3 Mappers MyBatis (20 mappers)

**CRUD Mappers (10):**
- TReclamoMapper
- TPersonaReclamoMapper
- TArchivoMapper
- TReclamoEvidenciaMapper
- Y 6 más...

**Query Mappers (10):**
- listarReclamosQueryMapper (consultas complejas con JOINs)
- UsuarioQueryMapper
- ReclamoEvidenciaQueryMapper
- Y 7 más...

---

## 6. CONFIGURACIÓN PARA PRODUCCIÓN

### 6.1 Variables de Entorno Críticas

El archivo `application-production.properties` contiene la configuración de producción:

#### Base de Datos
```
spring.datasource.url=jdbc:postgresql://10.10.14.172:5432/maqs
spring.datasource.username=postgres
spring.datasource.password=ACJJDP
spring.datasource.driver-class-name=org.postgresql.Driver
```

**Verificar:**
- Dirección IP/host del servidor PostgreSQL
- Puerto (por defecto 5432)
- Nombre de base de datos: `maqs`
- Credenciales correctas
- Acceso de red desde servidor de aplicación

#### Almacenamiento de Archivos
```
maqs.upload.dir=/var/www/html/documentos/maqs/
maqs.upload.tempDir=/var/www/html/documentos/maqs/temp
maqs.upload.maxFileSize=10485760  # 10 MB
maqs.upload.enabled=true
```

**Acciones previas:**
```bash
# Crear directorios
mkdir -p /var/www/html/documentos/maqs/
mkdir -p /var/www/html/documentos/maqs/temp

# Asignar permisos (usuario del servidor de aplicaciones)
chown -R tomcat:tomcat /var/www/html/documentos/maqs/
chmod -R 755 /var/www/html/documentos/maqs/
```

#### Correo SMTP (Producción)
```
spring.mail.host=mail.sernanp.gob.pe
spring.mail.port=25
spring.mail.username=dvaldez@sernanp.gob.pe
spring.mail.password=29$@m1n10
spring.mail.properties.mail.smtp.auth=true
spring.mail.properties.mail.smtp.starttls.enable=true
spring.mail.properties.mail.smtp.connectiontimeout=5000
```

**Verificar:**
- Servidor SMTP accesible
- Puertos de conexión abiertos en firewall
- Credenciales válidas
- Permisos de envío desde dirección

#### Configuración de Correos
```
maqs.email.from-name=SERNANP - MAQS
email.confirmacion.subject=SERNANP - Confirmacion de registro de {tipoRegistro} N. {numeroReclamo}
email.respuesta.subject=SERNANP - Respuesta a su {tipoRegistro} N. {numeroReclamo}
```

#### Estilos HTML de Correos
```
email.html.fontFamily=Arial, sans-serif
email.html.headerBackgroundColor=#F9A12F
email.html.fontColor=#333
```

#### Footer de Correos
```
email.footer.organizationName=MAQS del Servicio Nacional de Areas Naturales Protegidas
email.footer.phone=Telefono: (+51) 920 201 317
email.footer.website=Web: https://www.gob.pe/sernanp
```

### 6.2 Activar Perfil de Producción

Cambiar la línea en `application.properties`:
```
# De:
spring.profiles.active=development

# A:
spring.profiles.active=production
```

O pasar como parámetro en tiempo de ejecución:
```bash
java -jar maqs_api.jar --spring.profiles.active=production
```

---

## 7. PROCESO DE DESPLIEGUE

### 7.1 Fases del Despliegue

#### Fase 0: Pre-despliegue (Preparación)
```
1. Ejecutar script update_bd_.sql
   psql -U postgres -d maqs -f update_bd_.sql

2. Ejecutar script update_data_maqs.sql
   psql -U postgres -d maqs -f update_data_maqs.sql

3. Verificar estructura de BD
   psql -U postgres -d maqs -c "SELECT COUNT(*) FROM TABLATIPO;"

4. Crear directorios de almacenamiento
   mkdir -p /var/www/html/documentos/maqs/
   mkdir -p /var/www/html/documentos/maqs/temp
   chown -R tomcat:tomcat /var/www/html/documentos/maqs/

5. Actualizar application-production.properties
   - Servidor BD
   - Credenciales BD
   - Rutas de almacenamiento
   - Servidor SMTP
   - Credenciales SMTP
```

#### Fase 1: Compilación y Empaquetado
```bash
# En servidor de construcción (puede ser máquina de desarrollo)
cd /ruta/al/proyecto/maqs-backend
mvn clean package -DskipTests

# Resultado: target/maqs_api.war
```

#### Fase 2: Transferencia a Servidor
```bash
# Copiar archivo WAR a servidor de aplicaciones
scp target/maqs_api.war usuario@servidor:/opt/maqs/

# O copiar JAR ejecutable
scp target/maqs_api.jar usuario@servidor:/opt/maqs/
```

#### Fase 3: Despliegue en Tomcat (si se usa)
```bash
# Si la aplicación se despliega en Tomcat existente:
cp /opt/maqs/maqs_api.war /opt/apache-tomcat-7.0.68/webapps/

# Tomcat auto-descomprimirá y desplegará
```

#### Fase 4: Ejecución Standalone (Recomendado)
```bash
# Usar el JAR ejecutable que trae Spring Boot
java -jar /opt/maqs/maqs_api.jar --spring.profiles.active=production &

# O con nohup para que continue en background:
nohup java -jar /opt/maqs/maqs_api.jar --spring.profiles.active=production > /opt/maqs/maqs_api.log 2>&1 &

# Verificar que está corriendo:
ps aux | grep maqs_api.jar
```

#### Fase 5: Configurar Nginx como Reverse Proxy
```bash
# En /etc/nginx/sites-available/maqs

upstream maqs_backend {
    server localhost:7180;
}

server {
    listen 80;
    server_name maqs.sernanp.gob.pe;

    location / {
        proxy_pass http://maqs_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Recargar Nginx:
nginx -s reload
```

#### Fase 6: Verificación Post-Despliegue
```bash
# Verificar que la aplicación está respondiendo
curl -X GET http://localhost:7180/maqs_api/swagger-ui.html

# Verificar logs
tail -f /opt/apache-tomcat-7.0.68/logs/maqslogback.log

# O si ejecuta en foreground/log file:
tail -f /opt/maqs/maqs_api.log
```

### 7.2 Checklist de Despliegue

```
□ Scripts SQL ejecutados (update_bd_.sql, update_data_maqs.sql)
□ BD verificada (tablas creadas, datos de referencia insertados)
□ Directorios de almacenamiento creados
□ Permisos configurados
□ application-production.properties actualizado
□ spring.profiles.active=production
□ Proyecto compilado exitosamente
□ Archivo WAR/JAR transferido a servidor
□ Servicio iniciado sin errores
□ API responde en puerto 7180
□ Reverse proxy configurado (Nginx)
□ Acceso desde navegador: http://servidor/maqs_api
□ Swagger accesible: /maqs_api/swagger-ui.html
```

---

## 8. VALIDACIONES POST-DESPLIEGUE

### 8.1 Verificaciones Inmediatas

#### 1. Health Check
```bash
curl -X GET http://localhost:7180/maqs_api/actuator/health
# Respuesta esperada: {"status":"UP"}
```

#### 2. Swagger/API Docs
```
http://localhost:7180/maqs_api/swagger-ui.html
http://localhost:7180/maqs_api/v3/api-docs
```

#### 3. Conexión a BD
```bash
# Desde la aplicación, verificar logs:
tail /opt/apache-tomcat-7.0.68/logs/maqslogback.log | grep -i "database\|datasource\|connected"

# O usar comando psql desde servidor:
psql -U postgres -d maqs -c "SELECT VERSION();"
```

#### 4. Almacenamiento de Archivos
```bash
# Verificar que el directorio es accesible
ls -la /var/www/html/documentos/maqs/

# Intentar crear un archivo de prueba
touch /var/www/html/documentos/maqs/test.txt
rm /var/www/html/documentos/maqs/test.txt
```

#### 5. Correo SMTP
```bash
# Verificar conectividad
nc -zv mail.sernanp.gob.pe 25

# O verificar logs de la aplicación cuando intente enviar correo
```

### 8.2 Test Funcional Básico

#### Crear un Reclamo de Prueba
```json
POST http://localhost:7180/maqs_api/reclamos/crear

Body:
{
  "int_tipo_canal_reclamo": 261,  // Virtual
  "var_descripcion_reclamo": "Prueba de funcionamiento",
  "var_nombre_persona": "Usuario Prueba",
  "var_apellido_persona": "Test",
  "var_email_persona": "test@example.com",
  "var_telefono_persona": "123456789",
  "int_tipo_documento_persona": 1,
  "var_numero_documento_persona": "12345678"
}

Respuesta esperada:
{
  "success": true,
  "statusCode": 201,
  "data": {
    "id": 1,
    "numeroReclamo": 2025001,
    "estado": "Registrado",
    ...
  }
}
```

#### Listar Reclamos
```json
POST http://localhost:7180/maqs_api/reclamos/listar

Body:
{
  "pageNum": 1,
  "pageSize": 10
}

Respuesta esperada:
{
  "success": true,
  "data": [...],
  "paginator": {
    "pageNum": 1,
    "pageSize": 10,
    "totalPages": 1,
    "totalRecords": 1
  }
}
```

### 8.3 Validaciones de Correo
- Revisar bandeja de entrada del correo configurado
- Verificar que la confirmación se envió con formato correcto
- Validar que incluye caracteres españoles (tildes, ñ, °)
- Confirmar que el PDF se adjuntó correctamente

---

## 9. MONITOREO Y MANTENIMIENTO

### 9.1 Logs de Aplicación

#### Ubicación
```
Tomcat: /opt/apache-tomcat-7.0.68/logs/maqslogback.log
O archivo configurado en logback.xml
```

#### Verificar Logs
```bash
# Ver últimas líneas
tail -n 50 /opt/apache-tomcat-7.0.68/logs/maqslogback.log

# Ver en tiempo real
tail -f /opt/apache-tomcat-7.0.68/logs/maqslogback.log

# Buscar errores
grep ERROR /opt/apache-tomcat-7.0.68/logs/maqslogback.log

# Buscar advertencias
grep WARN /opt/apache-tomcat-7.0.68/logs/maqslogback.log
```

#### Niveles de Log
- **ERROR:** Errores críticos que afectan funcionamiento
- **WARN:** Advertencias de situaciones no esperadas
- **INFO:** Información general de operaciones
- **DEBUG:** Información detallada para depuración
- **TRACE:** Rastreo muy detallado

### 9.2 Métricas de Monitoreo

#### Performance
- Tiempo promedio de respuesta por endpoint
- Tasa de uso de CPU
- Memoria utilizada vs disponible
- Conexiones activas a BD

#### Estabilidad
- Tasa de errores (5xx)
- Número de excepciones no manejadas
- Disponibilidad de servicio (uptime)
- Reconexiones a BD

#### Volumen
- Reclamos registrados por día/mes
- Archivos almacenados
- Correos enviados
- Reportes generados

### 9.3 Mantenimiento Preventivo

#### Semanal
- Revisar logs de errores
- Verificar espacio en disco
- Validar que correos se envían correctamente

#### Mensual
- Revisión de permisos de archivos
- Limpieza de archivos temporales en `/var/www/html/documentos/maqs/temp`
- Backup de base de datos
- Análisis de performance

#### Trimestral
- Actualización de dependencias (si corresponde)
- Revisión de seguridad
- Capacitación de usuarios
- Documentación de cambios

### 9.4 Limpieza de Archivos Temporales
```bash
# Eliminar archivos temporales con más de 7 días
find /var/www/html/documentos/maqs/temp -type f -mtime +7 -delete

# Automatizar con cron
# Editar crontab del usuario tomcat:
crontab -e

# Agregar línea (ejecutar cada día a las 2 AM):
0 2 * * * find /var/www/html/documentos/maqs/temp -type f -mtime +7 -delete
```

### 9.5 Backup de Base de Datos
```bash
# Backup completo
pg_dump -U postgres -d maqs > /backup/maqs_$(date +%Y%m%d_%H%M%S).sql

# Automatizar con cron (diario a las 3 AM):
0 3 * * * pg_dump -U postgres -d maqs > /backup/maqs_$(date +\%Y\%m\%d).sql

# Restaurar desde backup
psql -U postgres -d maqs < /backup/maqs_20251118.sql
```

---

## 10. TROUBLESHOOTING

### 10.1 Problemas Comunes y Soluciones

#### Problema: Base de datos no disponible
```
Error: Connection to localhost:5432 refused
Causa: PostgreSQL no está corriendo o no es accesible

Solución:
1. Verificar que PostgreSQL está corriendo:
   systemctl status postgresql

2. Iniciar si está detenido:
   systemctl start postgresql

3. Verificar conectividad:
   psql -U postgres -h 10.10.14.172 -d maqs -c "SELECT 1;"

4. Revisar credenciales en application-production.properties
   - spring.datasource.url
   - spring.datasource.username
   - spring.datasource.password

5. Verificar firewall:
   telnet 10.10.14.172 5432
```

#### Problema: Envío de correo fallido
```
Error: Connection timeout to mail.sernanp.gob.pe:25
Causa: Servidor SMTP no accesible

Solución:
1. Verificar conectividad:
   telnet mail.sernanp.gob.pe 25

2. Verificar credenciales en application-production.properties
   - spring.mail.host
   - spring.mail.port
   - spring.mail.username
   - spring.mail.password

3. Verificar configuración SMTP:
   - spring.mail.properties.mail.smtp.auth=true
   - spring.mail.properties.mail.smtp.starttls.enable=true

4. Revisar logs para mensaje de error específico

5. Si usa puerto 465 en lugar de 25:
   - Cambiar port a 465
   - Agregar: spring.mail.properties.mail.smtp.socketFactory.port=465
   - Agregar: spring.mail.properties.mail.smtp.socketFactory.class=javax.net.ssl.SSLSocketFactory
```

#### Problema: Archivos no se guardan
```
Error: Permission denied or No space left on device
Causa: Permisos insuficientes o espacio en disco lleno

Solución:
1. Verificar permisos:
   ls -la /var/www/html/documentos/maqs/
   # Debe mostrar rwx para el usuario de tomcat

2. Asignar permisos correctos:
   chown -R tomcat:tomcat /var/www/html/documentos/maqs/
   chmod -R 755 /var/www/html/documentos/maqs/

3. Verificar espacio en disco:
   df -h

4. Si está lleno, hacer cleanup:
   find /var/www/html/documentos/maqs -type f -mtime +30 -delete

5. Aumentar partición si es necesario
```

#### Problema: Aplicación no inicia
```
Error: Port 7180 already in use
Causa: Otro proceso está usando el puerto

Solución:
1. Buscar proceso en puerto 7180:
   netstat -tulnp | grep 7180

2. Matar el proceso (si es seguro):
   kill -9 <PID>

3. O cambiar puerto en application.properties:
   server.port=7181
```

#### Problema: Memoria insuficiente
```
Error: OutOfMemoryError: Java heap space
Causa: Aplicación necesita más memoria

Solución:
1. Aumentar heap de JVM:
   java -Xmx2g -Xms1g -jar maqs_api.jar --spring.profiles.active=production

   # Donde:
   # -Xmx2g = Máximo 2GB
   # -Xms1g = Mínimo 1GB

2. Monitorear uso de memoria:
   ps aux | grep maqs_api
   # Ver columna %MEM

3. Revisar logs para memory leaks
```

#### Problema: Conexiones agotadas a BD
```
Error: Cannot get a connection, pool error Timeout waiting for idle object
Causa: Too many connections o pool configurado pequeño

Solución:
1. Revisar logs para identificar consultas lentas

2. Aumentar pool size en MyBatisConfig o via environment variables

3. Matar conexiones antiguas en PostgreSQL:
   SELECT pid, usename, application_name, state FROM pg_stat_activity WHERE datname = 'maqs' AND state = 'idle';
   SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = 'maqs' AND idle_in_transaction;
```

### 10.2 Comandos de Diagnóstico

```bash
# Ver estado del servicio
systemctl status tomcat
systemctl status postgresql

# Ver procesos Java corriendo
ps aux | grep java

# Ver puertos en uso
netstat -tulnp | grep -E "7180|5432"

# Ver conexiones a BD
psql -U postgres -d maqs -c "SELECT * FROM pg_stat_activity;"

# Ver tamaño de BD
psql -U postgres -d maqs -c "SELECT pg_size_pretty(pg_database_size('maqs'));"

# Ver espacio en disco
df -h

# Monitorear en tiempo real
watch -n 1 'ps aux | grep java'
```

---

## APÉNDICE A: VARIABLES DE ENTORNO

Variables que pueden ser sobrescritas por el entorno del servidor:

```
SPRING_DATASOURCE_URL=jdbc:postgresql://10.10.14.172:5432/maqs
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=ACJJDP

SPRING_MAIL_HOST=mail.sernanp.gob.pe
SPRING_MAIL_PORT=25
SPRING_MAIL_USERNAME=dvaldez@sernanp.gob.pe
SPRING_MAIL_PASSWORD=29$@m1n10

MAQS_UPLOAD_DIR=/var/www/html/documentos/maqs/
MAQS_UPLOAD_TEMPDIR=/var/www/html/documentos/maqs/temp
```

---

## APÉNDICE B: REFERENCIAS RÁPIDAS

### URL Importantes (Post-Despliegue)
- **API Base:** http://servidor:7180/maqs_api
- **Swagger Docs:** http://servidor:7180/maqs_api/swagger-ui.html
- **OpenAPI JSON:** http://servidor:7180/maqs_api/v3/api-docs

### Archivos Críticos
- `/opt/maqs/maqs_api.jar` - Aplicación ejecutable
- `/opt/apache-tomcat-7.0.68/webapps/maqs_api.war` - Si usa Tomcat
- `/opt/apache-tomcat-7.0.68/logs/maqslogback.log` - Logs
- `/var/www/html/documentos/maqs/` - Almacenamiento de archivos

### Comandos Frecuentes
```bash
# Iniciar aplicación
nohup java -jar /opt/maqs/maqs_api.jar --spring.profiles.active=production > /opt/maqs/maqs_api.log 2>&1 &

# Ver logs en tiempo real
tail -f /opt/apache-tomcat-7.0.68/logs/maqslogback.log

# Reiniciar
pkill -f "maqs_api.jar" && sleep 2 && nohup java -jar /opt/maqs/maqs_api.jar ...

# Health check
curl -s http://localhost:7180/maqs_api/actuator/health | jq .
```

---

## APÉNDICE C: CONTACTO Y SOPORTE

| Aspecto | Contacto | Teléfono |
|--------|----------|----------|
| **Servidor de Correos** | mail.sernanp.gob.pe | +51-1-XXXX-XXXX |
| **Base de Datos** | PostgreSQL Admin | Interno |
| **Aplicación Java** | Desarrollador | Interno |
| **Soporte SERNANP** | soporte@sernanp.gob.pe | (+51) 920 201 317 |

---

**Fin del Manual Técnico**

**Versión:** 1.0.0
**Creado:** Noviembre 2025
**Responsable:** Wilmer Pisco R.
**Destinatario:** Área de Tecnología de Información (TIC)
