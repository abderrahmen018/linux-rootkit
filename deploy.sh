#!/bin/bash

# Script d'automatisation pour la compilation et l'installation
# Fichier : deploy.sh

echo "=========================================="
echo "  Déploiement du projet - Installation"
echo "=========================================="
echo ""

# Vérification que le script est exécuté avec sudo
if [ "$EUID" -ne 0 ]; then
    echo "❌ Erreur : Ce script doit être exécuté avec les privilèges root"
    echo "Usage: sudo ./deploy.sh"
    exit 1
fi

# Étape 1: Compilation avec make
echo "📦 Étape 1: Compilation du projet..."
echo "Exécution: sudo make"
echo "------------------------------------------"

if ! sudo make; then
    echo "❌ Erreur: La compilation a échoué"
    exit 1
fi

echo "✅ Compilation terminée avec succès"
echo ""

# Étape 2: Installation avec make install
echo "🚀 Étape 2: Installation du projet..."
echo "Exécution: sudo make install"
echo "------------------------------------------"

if ! sudo make install; then
    echo "❌ Erreur: L'installation a échoué"
    exit 1
fi

echo "✅ Installation terminée avec succès"
echo ""

# Étape 3: Affichage du fichier process.txt
echo "📄 Étape 3: Lecture du fichier de processus..."
echo "Exécution: sudo cat /root/process.txt"
echo "------------------------------------------"

if [ -f "/root/process.txt" ]; then
    echo "Contenu du fichier /root/process.txt:"
    echo "------------------------------------------"
    sudo cat /root/process.txt
    echo "------------------------------------------"
    echo "✅ Lecture du fichier terminée"
else
    echo "⚠️  Attention: Le fichier /root/process.txt n'existe pas"
    echo "Cela peut être normal si c'est la première installation"
fi

echo ""
echo "=========================================="
echo "✅ Déploiement terminé avec succès!"
echo "=========================================="

