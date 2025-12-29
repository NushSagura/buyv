# Script de Rebuild BuyV App - Corrections Session & Navigation
# Date: 29 Décembre 2024

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  BuyV App - Rebuild & Test" -ForegroundColor Cyan
Write-Host "  Corrections: Session & Navigation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Chemin vers le projet Flutter
$FLUTTER_PROJECT = "buyv_flutter_app"

# Vérifier que Flutter est installé
Write-Host "🔍 Vérification de Flutter..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-Host "✅ Flutter trouvé: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Flutter n'est pas installé ou pas dans le PATH!" -ForegroundColor Red
    Write-Host "   Installer Flutter depuis: https://flutter.dev" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Se déplacer dans le dossier du projet
Write-Host "📂 Navigation vers $FLUTTER_PROJECT..." -ForegroundColor Yellow
if (Test-Path $FLUTTER_PROJECT) {
    Set-Location $FLUTTER_PROJECT
    Write-Host "✅ Dossier trouvé" -ForegroundColor Green
} else {
    Write-Host "❌ Dossier $FLUTTER_PROJECT non trouvé!" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Flutter Clean
Write-Host "🧹 Nettoyage du projet (flutter clean)..." -ForegroundColor Yellow
flutter clean
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Nettoyage terminé" -ForegroundColor Green
} else {
    Write-Host "❌ Erreur lors du nettoyage" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Supprimer le dossier build si existe
Write-Host "🗑️  Suppression du dossier build..." -ForegroundColor Yellow
if (Test-Path "build") {
    Remove-Item -Recurse -Force "build"
    Write-Host "✅ Dossier build supprimé" -ForegroundColor Green
} else {
    Write-Host "ℹ️  Dossier build n'existe pas (OK)" -ForegroundColor Gray
}

Write-Host ""

# Flutter Pub Get
Write-Host "📦 Téléchargement des dépendances (flutter pub get)..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dépendances téléchargées" -ForegroundColor Green
} else {
    Write-Host "❌ Erreur lors du téléchargement des dépendances" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Flutter Doctor
Write-Host "🏥 Diagnostic Flutter (flutter doctor)..." -ForegroundColor Yellow
flutter doctor
Write-Host ""

# Demander le mode de build
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Choisir le mode de build:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. Debug (par défaut)" -ForegroundColor White
Write-Host "2. Release (optimisé)" -ForegroundColor White
Write-Host "3. Profile (debug + performance)" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Votre choix (1/2/3)"

$buildMode = "debug"
switch ($choice) {
    "2" { $buildMode = "release" }
    "3" { $buildMode = "profile" }
    default { $buildMode = "debug" }
}

Write-Host ""
Write-Host "🚀 Lancement de l'app en mode $buildMode..." -ForegroundColor Yellow
Write-Host ""
Write-Host "📱 Assurez-vous qu'un émulateur/appareil est connecté!" -ForegroundColor Magenta
Write-Host ""

# Lister les appareils connectés
Write-Host "🔍 Appareils détectés:" -ForegroundColor Yellow
flutter devices
Write-Host ""

# Demander confirmation
$confirm = Read-Host "Continuer avec le build? (O/N)"
if ($confirm -ne "O" -and $confirm -ne "o") {
    Write-Host "❌ Build annulé" -ForegroundColor Red
    exit 0
}

Write-Host ""
Write-Host "🏗️  Build en cours..." -ForegroundColor Yellow
Write-Host "⏳ Cela peut prendre quelques minutes..." -ForegroundColor Gray
Write-Host ""

# Lancer Flutter Run
if ($buildMode -eq "debug") {
    flutter run
} elseif ($buildMode -eq "release") {
    flutter run --release
} else {
    flutter run --profile
}

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  ✅ BUILD RÉUSSI!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Tests à effectuer:" -ForegroundColor Cyan
    Write-Host "  1. Navigation avec bouton Back" -ForegroundColor White
    Write-Host "  2. Session persistante (fermer/rouvrir app)" -ForegroundColor White
    Write-Host "  3. Double-tap pour quitter depuis Home" -ForegroundColor White
    Write-Host ""
    Write-Host "📚 Voir: GUIDE_TEST_SESSION_NAVIGATION.md" -ForegroundColor Yellow
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  ❌ ERREUR DE BUILD" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "🔍 Vérifier les logs ci-dessus pour plus de détails" -ForegroundColor Yellow
    Write-Host ""
}

# Retour au dossier parent
Set-Location ..

Write-Host "Script terminé." -ForegroundColor Gray
