# 🔐 Gestión de Credenciales - S11

> [!WARNING]
> **AVISO DE SEGURIDAD (Repositorio Público):** Este repositorio es público. Las credenciales aquí expuestas son exclusivamente de **demostración académica** para un entorno de pruebas en un **clúster local (Minikube)**. NUNCA subas ni utilices estas credenciales en entornos de producción, servidores expuestos a Internet o proyectos reales.

---

## Estructura de Manifiestos de la Práctica (S11)

Para mantener la coherencia y orden de despliegue en el clúster local, la arquitectura se divide en los siguientes manifiestos:

| Archivo | Tipo / Recurso | Descripción |
| :--- | :--- | :--- |
| `00-namespace.yaml` | `Namespace` | Crea y aísla el espacio de nombres `practica-s11`. |
| `01-mongo-pvc.yaml` | `PersistentVolumeClaim` | Solicita almacenamiento persistente (1Gi) para MongoDB. |
| `02-app-configmap.yaml` | `ConfigMap` | Variables de entorno no sensibles del Backend (`DB_HOST`, `DB_PORT`, `DB_NAME`, `APP_PORT`). |
| `03-db-secret.yaml` | `Secret` | Credenciales sensibles de MongoDB codificadas en Base64. |
| `04-mongo-stack.yaml` | `Deployment` + `Service` | Despliegue de MongoDB 7.0 y servicio de red interno. |
| `05-backend-stack.yaml` | `Deployment` + `Service` | Despliegue del Backend Spring Boot WebFlux y exposición NodePort. |

---

## Credenciales Actuales (Solo para Desarrollo / Entorno Local)

### MongoDB

- **Usuario:** `admin`
- **Contraseña:** `Mongo2026$eguro`

---

## Cómo Cambiar las Credenciales

Si deseas cambiar las credenciales de MongoDB, sigue estos pasos:

### Opción 1: Cambiar el Secret (Recomendado)

#### Paso 1: Generar valores en Base64

En PowerShell:

```powershell
# Convertir usuario a Base64
$nuevoUsuario = "admin"
$usuarioBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($nuevoUsuario))
Write-Host "MONGO_INITDB_ROOT_USERNAME (Base64): $usuarioBase64"
# Resultado para 'admin': YWRtaW4=

# Convertir contraseña a Base64 (usar comillas simples para no interpolar el caracter $)
$nuevaPassword = 'Mongo2026$eguro'
$passwordBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($nuevaPassword))
Write-Host "MONGO_INITDB_ROOT_PASSWORD (Base64): $passwordBase64"
# Resultado para 'Mongo2026$eguro': TW9uZ28yMDI2JGVndXJv
```

#### Paso 2: Editar k8s/03-db-secret.yaml

Reemplaza los valores en Base64 correspondientes:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
  namespace: practica-s11
  labels:
    app: mongo
    tier: database
type: Opaque
data:
  # Usuario root de MongoDB (en Base64)
  MONGO_INITDB_ROOT_USERNAME: YWRtaW4=
  
  # Contraseña de MongoDB (en Base64)
  MONGO_INITDB_ROOT_PASSWORD: TW9uZ28yMDI2JGVndXJv
```

#### Paso 3: Aplicar los cambios

```powershell
# Eliminar el secret anterior
kubectl delete secret db-secret -n practica-s11

# Aplicar el nuevo secret actualizado
kubectl apply -f k8s/03-db-secret.yaml

# Reiniciar los deployments para que tomen el nuevo secret
kubectl rollout restart deployment mongo-deployment -n practica-s11
kubectl rollout restart deployment backend-deployment -n practica-s11

# Esperar a que estén listos
kubectl wait --for=condition=ready pod -l app=mongo -n practica-s11 --timeout=120s
kubectl wait --for=condition=ready pod -l app=backend -n practica-s11 --timeout=180s
```

---

### Opción 2: Usar kubectl para crear el Secret

En lugar de editar el archivo YAML manualmente, puedes crear el Secret directamente mediante CLI:

```powershell
# Eliminar el secret anterior (si existe)
kubectl delete secret db-secret -n practica-s11 2>$null

# Crear nuevo secret con las credenciales
kubectl create secret generic db-secret --from-literal=MONGO_INITDB_ROOT_USERNAME=admin --from-literal=MONGO_INITDB_ROOT_PASSWORD=Mongo2026$eguro -n practica-s11

# Reiniciar deployments
kubectl rollout restart deployment mongo-deployment -n practica-s11
kubectl rollout restart deployment backend-deployment -n practica-s11
```

> [!NOTE]
> En PowerShell, si ejecutas el comando con `--from-literal=MONGO_INITDB_ROOT_PASSWORD=Mongo2026$eguro`, PowerShell podría intentar interpretar `$eguro` como variable si está entre comillas dobles. Usar comillas simples `'Mongo2026$eguro'` asegura que se mantenga el texto literal.

---

### Opción 3: Usar variables de entorno locales (para testing sin Kubernetes)

Si deseas probar localmente la aplicación Spring Boot sin Kubernetes:

```powershell
# Definir variables de entorno
$env:DB_HOST = "localhost"
$env:DB_PORT = "27017"
$env:DB_NAME = "BodegaPeiranoNoSQL"
$env:MONGO_INITDB_ROOT_USERNAME = "admin"
$env:MONGO_INITDB_ROOT_PASSWORD = 'Mongo2026$eguro'
$env:APP_PORT = "8085"

# Variable para URI de MongoDB (según backend-stack)
$env:SPRING_DATA_MONGODB_URI = "mongodb://${env:MONGO_INITDB_ROOT_USERNAME}:${env:MONGO_INITDB_ROOT_PASSWORD}@${env:DB_HOST}:${env:DB_PORT}/${env:DB_NAME}?authSource=admin"

# Ejecutar la aplicación
mvn spring-boot:run
```

---

## Verificar que las Credenciales Funcionan

### 1. Verificar en MongoDB

```powershell
# Obtener el nombre del pod de MongoDB
$mongoPod = kubectl get pods -n practica-s11 -l app=mongo -o jsonpath="{.items[0].metadata.name}"

# Intentar conectarse con las credenciales
kubectl exec -it $mongoPod -n practica-s11 -- mongosh `
  -u admin `
  -p Mongo2026$eguro `
  --authenticationDatabase admin
```

Si las credenciales son correctas, verás el prompt de MongoDB:
```
test>
```

### 2. Verificar en el Backend

```powershell
# Obtener el nombre del pod del backend
$backendPod = kubectl get pods -n practica-s11 -l app=backend -o jsonpath="{.items[0].metadata.name}"

# Ver las variables de entorno inyectadas (sin exponer contraseñas)
kubectl exec -it $backendPod -n practica-s11 -- env | Select-String "MONGO_INITDB_ROOT_USERNAME"

# Ver los logs para verificar conexión
kubectl logs $backendPod -n practica-s11 --tail=50 | Select-String "MongoDB"
```

### 3. Verificar mediante la API

```powershell
# Obtener URL del servicio en Minikube
$serviceUrl = minikube service backend-service -n practica-s11 --url

# Health check (Spring Boot Actuator)
curl "$serviceUrl/actuator/health"
```

---

## Decodificar Credenciales del Secret

Si necesitas ver las credenciales actuales almacenadas en el Secret:

```powershell
# Ver el Secret completo en YAML (valores en Base64)
kubectl get secret db-secret -n practica-s11 -o yaml

# Decodificar solo el usuario
kubectl get secret db-secret -n practica-s11 -o jsonpath="{.data.MONGO_INITDB_ROOT_USERNAME}" | `
  ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }

# Decodificar solo la contraseña
kubectl get secret db-secret -n practica-s11 -o jsonpath="{.data.MONGO_INITDB_ROOT_PASSWORD}" | `
  ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

---

## Buenas Prácticas de Seguridad

### ✅ SÍ hacer:

1. **Usar Secrets para credenciales:**
   - Nunca hardcodearlas en el código fuente.
   - Usar ConfigMaps únicamente para configuración no sensible.

2. **Rotar credenciales regularmente:**
   - Cambiar contraseñas periódicamente.
   - Especialmente después de cambios en el equipo o ciclo del proyecto.

3. **Principio de mínimo privilegio:**
   - Crear usuarios de MongoDB con solo los permisos necesarios para la base de datos de la aplicación.

4. **Credenciales diferentes por entorno:**
   - Desarrollo / Local: credenciales de prueba predefinidas (como en este laboratorio).
   - Producción: credenciales complejas, generadas aleatoriamente y gestionadas por sistemas de secretos dedicados.

5. **No commitear Secrets sensibles a repositorios públicos:**
   - Los secretos de entornos reales no deben versionarse en Git sin cifrado previo.

### ❌ NO hacer:

1. **No usar credenciales por defecto:**
   - Evitar `admin/admin`, `root/root`, etc.

2. **No compartir credenciales en repositorios públicos:**
   - Recordar que este repositorio es público; cualquier credencial aquí visible es de demostración para Minikube.

3. **No imprimir credenciales en logs:**
   - Nunca imprimir cadenas de conexión con passwords en los logs de la aplicación.

4. **No reutilizar contraseñas:**
   - Las contraseñas de este clúster local jamás deben reutilizarse en otros servicios o infraestructuras.

---

## Gestión Avanzada de Secretos

### Para Producción: Sealed Secrets

Sealed Secrets permite encriptar secretos para commitearlos de forma segura a Git:

```powershell
# Instalar Sealed Secrets Controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Crear un secret localmente (dry-run)
kubectl create secret generic db-secret `
  --from-literal=MONGO_INITDB_ROOT_USERNAME=admin `
  --from-literal=MONGO_INITDB_ROOT_PASSWORD='Mongo2026$eguro' `
  --dry-run=client `
  -o yaml > db-secret.yaml

# Encriptar el secret
kubeseal -f db-secret.yaml -w db-sealed-secret.yaml

# Ahora db-sealed-secret.yaml puede commitearse a Git de forma segura
```

### Para Producción: HashiCorp Vault

Vault proporciona gestión centralizada de secretos con auditoría y rotación automática:

```yaml
# Ejemplo de configuración con Vault Agent
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-deployment
  namespace: practica-s11
spec:
  template:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "backend"
        vault.hashicorp.com/agent-inject-secret-database: "database/creds/mongodb"
```

---

## Auditoría de Acceso a Secretos

### Ver quién accedió a un Secret

Kubernetes registra accesos en los logs de auditoría:

```powershell
# Ver eventos relacionados con el secret
kubectl get events -n practica-s11 --field-selector involvedObject.name=db-secret

# Ver pods que consumen el secret db-secret
kubectl get pods -n practica-s11 -o json | `
  jq '.items[] | select(.spec.containers[].envFrom[]?.secretRef.name=="db-secret") | .metadata.name'
```

---

## Rotación de Credenciales Sin Downtime

Para rotar credenciales sin interrumpir el servicio:

```powershell
# 1. Crear nuevo usuario en MongoDB con los mismos permisos
kubectl exec -it $mongoPod -n practica-s11 -- mongosh -u admin -p Mongo2026$eguro --authenticationDatabase admin --eval '
  db.getSiblingDB("admin").createUser({
    user: "nuevo_usuario",
    pwd: "nueva_password_segura",
    roles: [{role: "root", db: "admin"}]
  })
'

# 2. Crear nuevo Secret con las nuevas credenciales
kubectl create secret generic db-secret-new `
  --from-literal=MONGO_INITDB_ROOT_USERNAME=nuevo_usuario `
  --from-literal=MONGO_INITDB_ROOT_PASSWORD=nueva_password_segura `
  -n practica-s11

# 3. Actualizar Deployment para usar el nuevo Secret
# Editar k8s/05-backend-stack.yaml:
# secretRef:
#   name: db-secret-new

# 4. Aplicar cambios
kubectl apply -f k8s/05-backend-stack.yaml

# 5. Verificar que funciona correctamente

# 6. Eliminar el usuario antiguo de MongoDB
kubectl exec -it $mongoPod -n practica-s11 -- mongosh -u nuevo_usuario -p nueva_password_segura --authenticationDatabase admin --eval '
  db.getSiblingDB("admin").dropUser("admin")
'

# 7. Eliminar el Secret antiguo
kubectl delete secret db-secret -n practica-s11
```

---

## Preguntas Frecuentes

### ¿Por qué Base64 si no es seguro?

Base64 es solo **codificación**, no **encriptación**. Se usa para:
- Permitir caracteres especiales en YAML.
- Consistencia en el formato de Secrets de Kubernetes.

Kubernetes proporciona seguridad adicional mediante encriptación en reposo en `etcd` y control de acceso con RBAC.

### ¿Puedo usar archivos en lugar de variables de entorno?

Sí, puedes montar Secrets como volúmenes:

```yaml
volumeMounts:
- name: secret-volume
  mountPath: /etc/secrets
  readOnly: true
volumes:
- name: secret-volume
  secret:
    secretName: db-secret
```

Luego leer desde `/etc/secrets/MONGO_INITDB_ROOT_USERNAME` y `/etc/secrets/MONGO_INITDB_ROOT_PASSWORD`.

---

## Resumen

- ✅ **Credenciales actuales:** `admin` / `Mongo2026$eguro` (demostración académica para clúster local Minikube).
- ✅ **Claves del Secret:** `MONGO_INITDB_ROOT_USERNAME` y `MONGO_INITDB_ROOT_PASSWORD`.
- ✅ **Namespace:** `practica-s11`.
- ✅ **Manifiestos vigentes:**
  - `00-namespace.yaml`
  - `01-mongo-pvc.yaml`
  - `02-app-configmap.yaml`
  - `03-db-secret.yaml`
  - `04-mongo-stack.yaml`
  - `05-backend-stack.yaml`
- ✅ **Procedimiento:** Cambiar credenciales editando `k8s/03-db-secret.yaml` o mediante `kubectl create secret generic` y reiniciando deployments.
- ✅ **Verificación:** Probar conexión mediante `mongosh`, inspección de variables de entorno con `Select-String "MONGO_INITDB_ROOT_USERNAME"` y health check de Actuator.

---

**Documentación de seguridad para la práctica académica S11**
