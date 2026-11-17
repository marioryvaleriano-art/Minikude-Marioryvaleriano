# 🚀 Despliegue de Backend Spring Boot WebFlux y MongoDB en Kubernetes (Minikube)

![Kubernetes](https://img.shields.io/badge/Kubernetes-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white)
![Minikube](https://img.shields.io/badge/Minikube-2496ED?style=for-the-badge&logo=minikube&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring_Boot-6DB33F?style=for-the-badge&logo=spring&logoColor=white)
![MongoDB](https://img.shields.io/badge/MongoDB-47A248?style=for-the-badge&logo=mongodb&logoColor=white)
![SQL Server](https://img.shields.io/badge/SQL_Server-CC292B?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)

Este repositorio contiene los manifiestos de **Kubernetes** para el despliegue y orquestación de una solución backend reactiva desarrollada con **Spring Boot WebFlux**, integrada con **MongoDB** (almacenamiento persistente) y conectividad a **Microsoft SQL Server**, configurado para entornos locales de desarrollo mediante **Minikube**.

---

## 📌 Arquitectura del Sistema

```mermaid
flowchart TD
    subgraph Cliente["Acceso Externo"]
        User["Cliente / Navegador / Postman"]
    end

    subgraph K8s["Clúster Kubernetes (Minikube) - Namespace: practica-s11"]
        subgraph Config["Configuración y Secretos"]
            CM["ConfigMap: app-config<br/>(DB_HOST, DB_PORT, DB_NAME, APP_PORT)"]
            SEC["Secret: db-secret<br/>(MONGO_INITDB_ROOT_USERNAME, MONGO_INITDB_ROOT_PASSWORD)"]
        end

        subgraph IngressNet["Exposición de Servicios"]
            NodePortSvc["Service: backend-service<br/>(NodePort: 30085 / Port: 8085)"]
            ClusterIPSvc["Service: mongo-service<br/>(ClusterIP: 27017)"]
        end

        subgraph Workloads["Cargas de Trabajo"]
            BackendPods["Deployment: backend-deployment<br/>(Replicas: 2 | WebFlux 8085)"]
            MongoPod["Deployment: mongo-deployment<br/>(MongoDB 7.0: 27017)"]
        end

        subgraph Storage["Almacenamiento Persistente"]
            PVC["PersistentVolumeClaim: mongo-pvc<br/>(1Gi - ReadWriteOnce)"]
        end
    end

    subgraph ExternalDB["Base de Datos Externa"]
        SQLServer["SQL Server: BodegaPeiranoDBF<br/>(192.168.18.10:1433)"]
    end

    User -->|Puerto 30085| NodePortSvc
    NodePortSvc --> BackendPods
    CM -.->|Inyección envFrom| BackendPods
    SEC -.->|Inyección envFrom / secretKeyRef| BackendPods
    SEC -.->|Autenticación root| MongoPod
    BackendPods -->|MongoDB URI| ClusterIPSvc
    ClusterIPSvc --> MongoPod
    MongoPod --- PVC
    BackendPods -->|JDBC / SPRING_DATASOURCE_URL| SQLServer
```

---

## 📁 Estructura de Manifiestos (`k8s/`)

Los manifiestos se encuentran numerados según el orden recomendado de despliegue:

| Manifiesto | Tipo de Recurso | Función Principal |
| :--- | :--- | :--- |
| [`00-namespace.yaml`](k8s/00-namespace.yaml) | `Namespace` | Crea y aisla el entorno lógico `practica-s11`. |
| [`01-mongo-pvc.yaml`](k8s/01-mongo-pvc.yaml) | `PersistentVolumeClaim` | Solicita 1Gi de almacenamiento persistente para MongoDB. |
| [`02-app-configmap.yaml`](k8s/02-app-configmap.yaml) | `ConfigMap` | Variables de entorno no sensibles del backend (hosts, puertos, DB). |
| [`03-db-secret.yaml`](k8s/03-db-secret.yaml) | `Secret` | Credenciales de base de datos en Base64 (`MONGO_INITDB_ROOT_*`). |
| [`04-mongo-stack.yaml`](k8s/04-mongo-stack.yaml) | `Deployment` + `Service` | Instancia de MongoDB 7.0 con sondas (liveness/readiness) y ClusterIP. |
| [`05-backend-stack.yaml`](k8s/05-backend-stack.yaml) | `Deployment` + `Service` | 2 réplicas del Backend WebFlux y servicio NodePort (30085). |

---

## ⚙️ Requisitos Previos

- [Minikube](https://minikube.sigs.k8s.io/docs/start/) (v1.30 o superior)
- [kubectl](https://kubernetes.io/docs/tasks/tools/) instalado y configurado
- Docker Desktop u otro driver compatible configurado para Minikube
- PowerShell 5.1+ o terminal compatible (Bash, Zsh)

---

## 🚀 Guía de Despliegue

### 1. Iniciar el clúster local de Minikube

```powershell
minikube start --driver=docker
