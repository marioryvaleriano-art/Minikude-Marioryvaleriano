# Script de PowerShell para limpiar todos los recursos del proyecto
# Proyecto: ASE251S4_T02-be (Spring Boot WebFlux + MongoDB)
# Uso: .\scripts\cleanup.ps1

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  S11 - Limpieza de Recursos" -ForegroundColor Cyan
Write-Host "  Spring WebFlux + MongoDB" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠ ADVERTENCIA: Este script eliminará TODOS los recursos del namespace practica-s11" -ForegroundColor Yellow
Write-Host ""
$confirmation = Read-Host "¿Estás seguro de que deseas continuar? (s/n)"

if ($confirmation -ne 's' -and $confirmation -ne 'S') {
    Write-Host "Operación cancelada." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Eliminando namespace practica-s11..." -ForegroundColor Yellow
kubectl delete namespace practica-s11

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Namespace eliminado exitosamente" -ForegroundColor Green
} else {
    Write-Host "⚠ El namespace no existe o ya fue eliminado" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Verificando que se eliminaron todos los recursos..." -ForegroundColor Yellow
kubectl get namespace practica-s11 2>&1 | Out-Null

if ($LASTEXITCODE -ne 0) {
    Write-Host "✓ Todos los recursos fueron eliminados" -ForegroundColor Green
} else {
    Write-Host "⚠ El namespace aún existe (puede tardar unos segundos en eliminarse completamente)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  Limpieza completada" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Para detener Minikube, ejecuta: minikube stop" -ForegroundColor Yellow
Write-Host "Para eliminar completamente Minikube, ejecuta: minikube delete" -ForegroundColor Yellow
Write-Host ""
