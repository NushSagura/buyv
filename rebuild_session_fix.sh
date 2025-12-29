#!/bin/bash
# Script de Rebuild BuyV App - Corrections Session & Navigation
# Date: 29 Décembre 2024

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

echo -e "${CYAN}========================================"
echo -e "  BuyV App - Rebuild & Test"
echo -e "  Corrections: Session & Navigation"
echo -e "========================================${NC}"
echo ""

# Chemin vers le projet Flutter
FLUTTER_PROJECT="buyv_flutter_app"

# Vérifier que Flutter est installé
echo -e "${YELLOW}🔍 Vérification de Flutter...${NC}"
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version 2>&1 | head -n 1)
    echo -e "${GREEN}✅ Flutter trouvé: $FLUTTER_VERSION${NC}"
else
    echo -e "${RED}❌ Flutter n'est pas installé ou pas dans le PATH!${NC}"
    echo -e "${YELLOW}   Installer Flutter depuis: https://flutter.dev${NC}"
    exit 1
fi

echo ""

# Se déplacer dans le dossier du projet
echo -e "${YELLOW}📂 Navigation vers $FLUTTER_PROJECT...${NC}"
if [ -d "$FLUTTER_PROJECT" ]; then
    cd "$FLUTTER_PROJECT"
    echo -e "${GREEN}✅ Dossier trouvé${NC}"
else
    echo -e "${RED}❌ Dossier $FLUTTER_PROJECT non trouvé!${NC}"
    exit 1
fi

echo ""

# Flutter Clean
echo -e "${YELLOW}🧹 Nettoyage du projet (flutter clean)...${NC}"
if flutter clean; then
    echo -e "${GREEN}✅ Nettoyage terminé${NC}"
else
    echo -e "${RED}❌ Erreur lors du nettoyage${NC}"
    exit 1
fi

echo ""

# Supprimer le dossier build si existe
echo -e "${YELLOW}🗑️  Suppression du dossier build...${NC}"
if [ -d "build" ]; then
    rm -rf build
    echo -e "${GREEN}✅ Dossier build supprimé${NC}"
else
    echo -e "${GRAY}ℹ️  Dossier build n'existe pas (OK)${NC}"
fi

echo ""

# Flutter Pub Get
echo -e "${YELLOW}📦 Téléchargement des dépendances (flutter pub get)...${NC}"
if flutter pub get; then
    echo -e "${GREEN}✅ Dépendances téléchargées${NC}"
else
    echo -e "${RED}❌ Erreur lors du téléchargement des dépendances${NC}"
    exit 1
fi

echo ""

# Flutter Doctor
echo -e "${YELLOW}🏥 Diagnostic Flutter (flutter doctor)...${NC}"
flutter doctor
echo ""

# Demander le mode de build
echo -e "${CYAN}========================================"
echo -e "  Choisir le mode de build:"
echo -e "========================================${NC}"
echo -e "1. Debug (par défaut)"
echo -e "2. Release (optimisé)"
echo -e "3. Profile (debug + performance)"
echo ""

read -p "Votre choix (1/2/3): " choice

BUILD_MODE="debug"
case $choice in
    2) BUILD_MODE="release" ;;
    3) BUILD_MODE="profile" ;;
    *) BUILD_MODE="debug" ;;
esac

echo ""
echo -e "${YELLOW}🚀 Lancement de l'app en mode $BUILD_MODE...${NC}"
echo ""
echo -e "${CYAN}📱 Assurez-vous qu'un émulateur/appareil est connecté!${NC}"
echo ""

# Lister les appareils connectés
echo -e "${YELLOW}🔍 Appareils détectés:${NC}"
flutter devices
echo ""

# Demander confirmation
read -p "Continuer avec le build? (O/N): " confirm
if [ "$confirm" != "O" ] && [ "$confirm" != "o" ]; then
    echo -e "${RED}❌ Build annulé${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}🏗️  Build en cours...${NC}"
echo -e "${GRAY}⏳ Cela peut prendre quelques minutes...${NC}"
echo ""

# Lancer Flutter Run
case $BUILD_MODE in
    "release")
        flutter run --release
        ;;
    "profile")
        flutter run --profile
        ;;
    *)
        flutter run
        ;;
esac

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}========================================"
    echo -e "  ✅ BUILD RÉUSSI!"
    echo -e "========================================${NC}"
    echo ""
    echo -e "${CYAN}📋 Tests à effectuer:${NC}"
    echo -e "  1. Navigation avec bouton Back"
    echo -e "  2. Session persistante (fermer/rouvrir app)"
    echo -e "  3. Double-tap pour quitter depuis Home"
    echo ""
    echo -e "${YELLOW}📚 Voir: GUIDE_TEST_SESSION_NAVIGATION.md${NC}"
    echo ""
else
    echo ""
    echo -e "${RED}========================================"
    echo -e "  ❌ ERREUR DE BUILD"
    echo -e "========================================${NC}"
    echo ""
    echo -e "${YELLOW}🔍 Vérifier les logs ci-dessus pour plus de détails${NC}"
    echo ""
fi

# Retour au dossier parent
cd ..

echo -e "${GRAY}Script terminé.${NC}"
