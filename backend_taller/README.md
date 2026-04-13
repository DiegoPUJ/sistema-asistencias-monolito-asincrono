# Sistema de Asistencias Vehiculares - Monolito Asíncrono

## Descripción del sistema

Este proyecto implementa un ejemplo práctico y funcional de un sistema de asistencias vehiculares basado en una arquitectura **monolítica asíncrona**.

El sistema permite que un cliente o conductor registre una solicitud de asistencia desde una aplicación desarrollada en Flutter. Una vez enviada, el backend en Laravel almacena la solicitud en SQLite, la encola para procesamiento asíncrono y responde rápidamente al usuario. Posteriormente, un worker independiente procesa la solicitud en segundo plano y actualiza su estado.

Además, el sistema incluye un **Panel Admin MVP**, desde el cual es posible consultar solicitudes, filtrarlas por estado y asignar manualmente un técnico.

El flujo principal implementado es el siguiente:

1. El cliente registra una solicitud de asistencia.
2. El backend guarda la solicitud con estado `pending`.
3. La solicitud se envía a una cola.
4. Un worker procesa la solicitud en segundo plano.
5. El estado cambia a `completed`.
6. El frontend consulta periódicamente el estado mediante **polling**.
7. El panel admin permite visualizar solicitudes y asignar técnico.

---

## Tecnologías usadas

### Frontend
- Flutter
- Dart

### Backend
- Laravel
- PHP

### Base de datos
- SQLite

### Procesamiento asíncrono
- Laravel Queue
- Worker independiente

### Comunicación
- API REST
- Polling (Not-Push)

### Despliegue
- Docker
- Docker Compose
- Nginx

---

## Pasos para despliegue

### 1. Clonar el repositorio

```bash
git clone <URL_DEL_REPOSITORIO>
cd SistemaAsistencias