# Sistema de Asistencias Vehiculares  
## Implementación de un Monolito Asíncrono en Capas

## 1. Descripción del sistema

Este proyecto implementa un **MVP funcional** de un sistema de asistencias vehiculares, desarrollado bajo un enfoque de **arquitectura en capas con despliegue monolítico asíncrono**.

El sistema permite que un cliente o conductor registre una solicitud de asistencia desde una aplicación Flutter. Una vez enviada, el backend en Laravel almacena la solicitud, responde de forma inmediata al usuario y delega el procesamiento pesado a un **worker asíncrono**. Posteriormente, el frontend consulta periódicamente el estado de la solicitud hasta detectar que el proceso ha finalizado.

Adicionalmente, se implementó un **Panel Admin MVP** que permite:
- visualizar solicitudes registradas
- filtrarlas por estado
- asignar manualmente un técnico

La implementación busca demostrar:
- integración entre frontend y backend
- uso de arquitectura en capas
- uso de colas y worker
- separación entre canal rápido y canal lento
- despliegue con contenedores
- cumplimiento del requerimiento **Not-Push** mediante **polling**

---

## 2. Objetivo de la implementación

El objetivo principal fue construir el flujo principal del sistema bajo una arquitectura **monolítica asíncrona**, donde:

- el **canal rápido** recibe la solicitud, la guarda y responde inmediatamente
- el **canal lento** procesa la solicitud en segundo plano mediante una cola y un worker independiente

Esto permite mejorar la experiencia del usuario y evitar que el procesamiento lento bloquee la atención inicial.

---

## 3. Arquitectura implementada

La solución se desarrolló como un **monolito asíncrono en capas**.

### Capas implementadas

- **Capa de presentación**  
  Implementada con Flutter. Se encarga de la interacción con el usuario, captura de datos, visualización del estado y navegación entre vistas.

- **Capa de aplicación**  
  Implementada con Laravel. Coordina los casos de uso mediante controladores, rutas y jobs.

- **Capa de negocio**  
  Representada por las reglas del flujo de solicitudes: creación, estados (`pending`, `processing`, `completed`) y asignación de técnico.

- **Capa de datos**  
  Implementada con SQLite, migraciones, seeders y modelos Eloquent.

### Enfoque monolítico

El backend se mantiene como una única aplicación Laravel, con una sola base de código y un único modelo de negocio. Aunque se desplegó con varios contenedores, el sistema **no está dividido en microservicios**, por lo que sigue siendo un **monolito**.

### Comportamiento asíncrono

La parte asíncrona se implementó con:
- Laravel Queue
- tabla `jobs`
- job `ProcessAssistanceRequest`
- contenedor `worker` ejecutando `queue:work`

---

## 4. Tecnologías usadas

### Frontend
- Flutter
- Dart

### Backend
- Laravel
- PHP

### Base de datos
- SQLite

### Comunicación
- API REST
- Polling (Not-Push)

### Asincronía
- Laravel Queue
- Worker independiente

### Despliegue
- Docker
- Docker Compose
- Nginx

---

## 5. Componentes principales del sistema

## Frontend (`frontend_taller`)
Aplicación Flutter que incluye dos vistas principales:

### Vista Cliente
Permite:
- registrar una solicitud de asistencia
- seleccionar aseguradora
- consultar el estado de la solicitud
- visualizar el progreso del proceso
- mantener el último `requestId` para no perder contexto

### Vista Admin
Permite:
- consultar todas las solicitudes
- filtrar solicitudes por estado
- ver aseguradora y técnico asignado
- asignar manualmente un técnico

---

## Backend (`backend_taller`)
Aplicación Laravel encargada de:
- exponer endpoints REST
- validar peticiones
- persistir datos en SQLite
- despachar jobs a la cola
- procesar solicitudes en segundo plano
- permitir funciones administrativas

### Entidades principales
- `Provider`
- `AssistanceRequest`

### Procesamiento asíncrono
- `ProcessAssistanceRequest`

### Controlador principal
- `AssistanceRequestController`

---

## 6. Flujo principal implementado

El flujo principal del sistema es el siguiente:

1. El cliente registra una solicitud desde Flutter.
2. El frontend envía un `POST` al backend.
3. Laravel valida la información.
4. La solicitud se guarda en SQLite con estado `pending`.
5. El backend despacha un job a la cola.
6. Laravel responde rápidamente con `202 Accepted`.
7. El worker toma el job y procesa la solicitud en segundo plano.
8. El estado cambia a `processing` y luego a `completed`.
9. El frontend consulta periódicamente el estado mediante polling.
10. El panel admin puede listar solicitudes y asignar un técnico.

---

## 7. Cumplimiento del requerimiento Not-Push

El enunciado exigía una solución **Not-Push**, por lo tanto no se utilizaron:
- WebSockets
- Server-Sent Events
- push notifications

En su lugar, se implementó **polling** en el frontend Flutter.

Esto significa que:
- el cliente consulta periódicamente al backend
- el servidor no envía actualizaciones activamente
- la aplicación detecta el cambio de estado cuando una de las consultas devuelve `completed`

Esto cumple directamente con la restricción de la entrega.

---

## 8. Despliegue con Docker

Para cumplir el requerimiento de uso de contenedores, el backend fue desplegado con Docker Compose.

### Contenedores usados

- **app**  
  Ejecuta Laravel / PHP-FPM

- **worker**  
  Ejecuta `php artisan queue:work`

- **nginx**  
  Expone el backend por HTTP en `localhost:8000`

### Qué demuestra esta separación
- aislamiento operativo
- separación entre atención inmediata y procesamiento lento
- despliegue más cercano a un entorno real

---

## 9. Estructura del proyecto

```text
SistemaAsistencias/
├── backend_taller/
├── frontend_taller/
└── README.md