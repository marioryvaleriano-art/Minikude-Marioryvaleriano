# Script de PowerShell para desplegar el proyecto completo en Minikube
# Proyecto: ASE251S4_T02-be (Spring Boot WebFlux + MongoDB)
# Uso: .\scripts\deploy-all.ps1

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  S11 - Despliegue Automatizado" -ForegroundColor Cyan
Write-Host "  Spring WebFlux + MongoDB en Minikube" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Función para verificar si un comando existe
function Test-Command {
    param($CommandName)
    return [bool](Get-Command -Name $CommandName -ErrorAction SilentlyContinue)
}

# Verificar requisitos
Write-Host "[1/10] Verificando requisitos..." -ForegroundColor Yellow
$requiredCommands = @("docker", "minikube", "kubectl")
$missingCommands = @()

foreach ($cmd in $requiredCommands) {
    if (-not (Test-Command $cmd)) {
        $missingCommands += $cmd
    }
}

if ($missingCommands.Count -gt 0) {
    Write-Host "ERROR: Faltan los siguientes comandos: $($missingCommands -join ', ')" -ForegroundColor Red
    Write-Host "Por favor, instala Docker Desktop, Minikube y kubectl." -ForegroundColor Red
    exit 1
}
Write-Host "✓ Todos los requisitos están instalados" -ForegroundColor Green
Write-Host ""

# Verificar que Minikube está ejecutándose
Write-Host "[2/10] Verificando Minikube..." -ForegroundColor Yellow
$minikubeStatus = minikube status 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Minikube no está ejecutándose. Iniciando Minikube..." -ForegroundColor Yellow
    minikube start --driver=docker
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: No se pudo iniciar Minikube" -ForegroundColor Red
        exit 1
    }
}
Write-Host "✓ Minikube está ejecutándose" -ForegroundColor Green
Write-Host ""

# Crear namespace
Write-Host "[3/11] Creando namespace practica-s11..." -ForegroundColor Yellow
kubectl apply -f k8s/00-namespace.yaml
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Namespace creado exitosamente" -ForegroundColor Green
} else {
    Write-Host "⚠ El namespace ya existe (continuando...)" -ForegroundColor Yellow
}
Write-Host ""

# Configurar contexto para usar el namespace por defecto
kubectl config set-context --current --namespace=practica-s11 2>$null

# Aplicar PVC
Write-Host "[4/11] Aplicando PersistentVolumeClaim..." -ForegroundColor Yellow
kubectl apply -f k8s/01-mongo-pvc.yaml
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo aplicar el PVC" -ForegroundColor Red
    exit 1
}
Write-Host "✓ PVC aplicado" -ForegroundColor Green
Write-Host ""

# Aplicar ConfigMap
Write-Host "[5/11] Aplicando ConfigMap..." -ForegroundColor Yellow
kubectl apply -f k8s/02-app-configmap.yaml
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo aplicar el ConfigMap" -ForegroundColor Red
    exit 1
}
Write-Host "✓ ConfigMap aplicado" -ForegroundColor Green
Write-Host ""

# Aplicar Secret
Write-Host "[6/11] Aplicando Secret..." -ForegroundColor Yellow
kubectl apply -f k8s/03-db-secret.yaml
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo aplicar el Secret" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Secret aplicado" -ForegroundColor Green
Write-Host ""

# Desplegar MongoDB
Write-Host "[7/11] Desplegando MongoDB..." -ForegroundColor Yellow
kubectl apply -f k8s/04-mongo-stack.yaml
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo desplegar MongoDB" -ForegroundColor Red
    exit 1
}
Write-Host "✓ MongoDB desplegado" -ForegroundColor Green
Write-Host "Esperando a que MongoDB esté listo..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=mongo -n practica-s11 --timeout=120s
Write-Host "✓ MongoDB está listo" -ForegroundColor Green
Write-Host ""

# Desplegar Backend
Write-Host "[8/11] Desplegando Backend..." -ForegroundColor Yellow
kubectl apply -f k8s/05-backend-stack.yaml
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo desplegar el Backend" -ForegroundColor Red
    exit 1
}
Write-Host "✓ Backend desplegado" -ForegroundColor Green
Write-Host "Esperando a que el Backend esté listo..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=backend -n practica-s11 --timeout=180s
Write-Host "✓ Backend está listo" -ForegroundColor Green
Write-Host ""

# Verificar estado
Write-Host "[9/11] Verificando estado del clúster..." -ForegroundColor Yellow
Write-Host ""
kubectl get pods,svc,configmaps,secrets -n practica-s11
Write-Host ""

# Obtener URL de acceso
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  ¡Despliegue completado exitosamente!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para obtener la URL de acceso, ejecuta:" -ForegroundColor Yellow
Write-Host "  minikube service backend-service -n practica-s11 --url" -ForegroundColor White
Write-Host ""
Write-Host "O para abrirlo directamente en el navegador:" -ForegroundColor Yellow
Write-Host "  minikube service backend-service -n practica-s11" -ForegroundColor White
Write-Host ""
Write-Host "Endpoints disponibles (puerto 8085):" -ForegroundColor Yellow
Write-Host "  - GET  /actuator/health" -ForegroundColor White
Write-Host "  - GET  /productos" -ForegroundColor White
Write-Host "  - POST /productos" -ForegroundColor White
Write-Host ""
