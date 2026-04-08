import SwiftUI

func ipmLocalized(
    _ language: String,
    de: String,
    en: String,
    fr: String? = nil,
    ptBR: String? = nil,
    nl: String? = nil
) -> String {
    let normalizedLanguage = normalizedIPMLanguage(language)
    switch normalizedLanguage {
    case "de":
        return de
    case "en":
        return en
    case "fr":
        return fr ?? IPMTranslationCatalog.translate(target: "fr", de: de, en: en) ?? en
    case "pt-BR":
        return ptBR ?? IPMTranslationCatalog.translate(target: "pt-BR", de: de, en: en) ?? en
    case "nl":
        return nl ?? IPMTranslationCatalog.translate(target: "nl", de: de, en: en) ?? en
    default:
        return en
    }
}

private func normalizedIPMLanguage(_ language: String) -> String {
    let normalized = language.lowercased()
    if normalized.hasPrefix("de") { return "de" }
    if normalized.hasPrefix("en") { return "en" }
    if normalized.hasPrefix("fr") { return "fr" }
    if normalized.hasPrefix("nl") { return "nl" }
    if normalized.hasPrefix("pt-br") || normalized.hasPrefix("pt_br") || normalized.hasPrefix("pt") { return "pt-BR" }
    return "en"
}

private enum IPMTranslationCatalog {
    static func translate(target: String, de: String, en: String) -> String? {
        switch target {
        case "fr":
            return frByDe[de] ?? frByEn[en]
        case "pt-BR":
            return ptBRByDe[de] ?? ptBRByEn[en]
        case "nl":
            return nlByDe[de] ?? nlByEn[en]
        default:
            return nil
        }
    }

    static let frByEn: [String: String] = [
        "Dashboard": "Tableau de bord",
        "Rooms": "Pièces",
        "Traps": "Pièges",
        "All clients": "Tous les clients",
        "Select client": "Choisir un client",
        "Overdue": "En retard",
        "Due": "À échéance",
        "Due Items": "Échéances",
        "All": "Tous",
        "more": "de plus",
        "No data yet": "Pas encore de données",
        "Create clients and rooms first": "Crée d’abord des clients et des pièces",
        "Good morning": "Bonjour",
        "Good afternoon": "Bon après-midi",
        "Good evening": "Bonsoir",
        "Trap": "Piège",
        "All done": "Tout est fait",
        "No traps due": "Aucun piège à échéance",
        "This week": "Cette semaine",
        "All traps": "Tous les pièges",
        "Search traps": "Rechercher des pièges",
        "Email": "E-mail",
        "Current password": "Mot de passe actuel",
        "Email updated successfully.": "E-mail mis à jour avec succès.",
        "Save email": "Enregistrer l’e-mail",
        "Name": "Nom",
        "Security": "Sécurité",
        "New password": "Nouveau mot de passe",
        "Confirm new password": "Confirmer le nouveau mot de passe",
        "The new passwords do not match.": "Les nouveaux mots de passe ne correspondent pas.",
        "Password updated successfully.": "Mot de passe mis à jour avec succès.",
        "Save password": "Enregistrer le mot de passe",
        "Password": "Mot de passe",
        "Subscription status": "Statut de l’abonnement",
        "Payment & invoices": "Paiement et factures",
        "Manage": "Gérer",
        "Plan": "Forfait",
        "Billing": "Facturation",
        "Clients": "Clients",
        "Rooms per client": "Pièces par client",
        "Traps per room": "Pièges par pièce",
        "Restore purchases": "Restaurer les achats",
        "Manage subscription": "Gérer l’abonnement",
        "Subscription": "Abonnement",
        "Delete account": "Supprimer le compte",
        "I understand: account and data will be permanently deleted.": "Je comprends : le compte et les données seront supprimés définitivement.",
        "Delete account permanently": "Supprimer définitivement le compte",
        "Critical": "Critique",
        "Sign out": "Se déconnecter",
        "Account": "Compte",
        "Sign out?": "Se déconnecter ?",
        "Cancel": "Annuler",
        "You will be signed out of your account.": "Tu vas être déconnecté de ton compte.",
        "Delete account now?": "Supprimer le compte maintenant ?",
        "Delete": "Supprimer",
        "This action cannot be undone.": "Cette action est irréversible.",
        "Notifications": "Notifications",
        "Default inspection interval": "Intervalle d’inspection par défaut",
        "days": "jours",
        "Language": "Langue",
        "Trap numbers on pins": "Numéros des pièges sur les repères",
        "Settings": "Réglages",
        "Export data as CSV": "Exporter les données en CSV",
        "Share CSV": "Partager le CSV",
        "Export data as PDF": "Exporter les données en PDF",
        "Share PDF": "Partager le PDF",
        "Export": "Export",
        "Imprint": "Mentions légales",
        "Privacy Policy": "Politique de confidentialité",
        "Terms & Conditions": "Conditions générales",
        "Contact / Support": "Contact / Support",
        "App": "App",
        "Billing history": "Historique de facturation",
        "Payment & Invoices": "Paiement et factures",
        "Open in App Store": "Ouvrir dans l’App Store",
        "View invoices": "Voir les factures",
        "Open online imprint": "Ouvrir les mentions légales en ligne",
        "Open full privacy policy": "Ouvrir la politique de confidentialité complète",
        "Open terms": "Ouvrir les conditions",
        "Email support": "Support par e-mail",
        "Support page": "Page de support",
        "Welcome back": "Bon retour",
        "Sign in": "Se connecter",
        "or": "ou",
        "Sign in with Google": "Se connecter avec Google",
        "Onboarding": "Intégration",
        "Quick sign in": "Connexion rapide",
        "New here? Start": "Nouveau ici ? Commencer",
        "Already have an account?": "Tu as déjà un compte ?",
        "Back": "Retour",
        "Create account": "Créer un compte",
        "Continue": "Continuer",
        "Welcome to IPM Manager": "Bienvenue dans IPM Manager",
        "What is your name?": "Comment t’appelles-tu ?",
        "First name": "Prénom",
        "Last name": "Nom",
        "Choose a username": "Choisis un nom d’utilisateur",
        "Username": "Nom d’utilisateur",
        "How did you hear about us?": "Comment nous as-tu connus ?",
        "Almost done": "Presque terminé",
        "No clients yet": "Pas encore de clients",
        "Search clients": "Rechercher des clients",
        "Address": "Adresse",
        "Contact": "Contact",
        "Phone": "Téléphone",
        "Notes": "Notes",
        "Add room": "Ajouter une pièce",
        "Share export": "Partager l’export",
        "New client": "Nouveau client",
        "Save": "Enregistrer",
        "New room": "Nouvelle pièce",
        "Inspection": "Contrôle",
        "Measurement": "Mesure",
        "Pests": "Ravageurs",
        "Guests": "Invités",
        "Limit reached: The \\(tierTitle()) plan allows up to \\(max) clients. Please upgrade.": "Limite atteinte : Le forfait \\(tierTitle()) permet jusqu'à \\(max) clients. Veuillez passer à un forfait supérieur.",
        "Limit reached: The \\(tierTitle()) plan allows up to \\(max) rooms per client. Please upgrade.": "Limite atteinte : Le forfait \\(tierTitle()) permet jusqu'à \\(max) pièces par client. Veuillez passer à un forfait supérieur.",
        "Limit reached: The \\(tierTitle()) plan allows up to \\(max) traps per room. Please upgrade.": "Limite atteinte : Le forfait \\(tierTitle()) permet jusqu'à \\(max) pièges par pièce. Veuillez passer à un forfait supérieur.",
        "Please sign in first.": "Veuillez d'abord vous connecter.",
        "Inspection report": "Rapport d'inspection",
        "Client": "Client",
        "Room": "Pièce",
        "Type": "Type",
        "Inspection date": "Date d'inspection",
        "Total count": "Nombre total",
        "Photos": "Photos",
        "Findings": "Constats",
        "PDF report is only available on iOS.": "Le rapport PDF est uniquement disponible sur iOS.",
        "PDF export is only available on iOS.": "L'export PDF est uniquement disponible sur iOS.",
        "Invalid client for export.": "Client invalide pour l'export.",
        "Today": "Aujourd'hui",
        "No traps": "Aucun piège",
        "No traps found for the current filter": "Aucun piège trouvé pour le filtre actuel",
        "Check-in": "Check-in",
        "Monthly": "Mensuel",
        "Yearly (-10%)": "Annuel (−10 %)",
        "Unlimited": "Illimité",
        "Price pending": "Prix en attente",
        "valid until": "valide jusqu'au",
        "CSV export created.": "Export CSV créé.",
        "PDF export created.": "Export PDF créé.",
        "Manage payment method": "Gérer le mode de paiement",
        "Privacy Policy: This app processes account and operational inspection data to provide IPM features. See the full online policy for details.": "Politique de confidentialité : Cette appli traite les données de compte et d'inspection opérationnelle pour fournir les fonctionnalités IPM. Consulte la politique complète en ligne pour plus de détails.",
        "Terms & Conditions: App usage is subject to the applicable terms. Please read the full version online.": "CGU : L'utilisation de l'appli est soumise aux conditions en vigueur. Lis la version complète en ligne.",
        "Prioritized due items": "Éléments prioritaires à vérifier",
        "No dashboard data is currently available for this client.": "Aucune donnée du tableau de bord disponible pour ce client.",
        "Manage clients": "Gérer les clients",
        "Friends": "Amis",
        "Recommendation": "Recommandation",
        "Checking email...": "Vérification de l'e-mail...",
        "Please enter a valid email.": "Veuillez saisir un e-mail valide.",
        "Email is available.": "E-mail disponible.",
        "Email is already taken.": "E-mail déjà utilisé.",
        "Could not check email right now.": "Impossible de vérifier l'e-mail pour l'instant.",
        "Plan recommendation": "Recommandation de forfait",
        "Choose Plus": "Choisir Plus",
        "Choose Pro": "Choisir Pro",
        "Stay on Free": "Rester sur Free",
        "With multiple clients, Plus or Pro is usually a better fit. You can switch anytime later.": "Avec plusieurs clients, Plus ou Pro convient généralement mieux. Tu peux changer à tout moment.",
        "Step \\(step + 1) of \\(totalSteps)": "Étape \\(step + 1) sur \\(totalSteps)",
        "We will set up your account in a few quick steps so you can start right away.": "On va configurer ton compte en quelques étapes rapides pour que tu puisses commencer tout de suite.",
        "Rooms & traps": "Pièces & pièges",
        "Inspection rhythm": "Rythme d'inspection",
        "Your login": "Tes identifiants",
        "At least 6 characters.": "Au moins 6 caractères.",
        "This name will be shown on your profile.": "Ce nom sera affiché sur ton profil.",
        "How many clients do you currently manage?": "Combien de clients gères-tu actuellement ?",
        "Tip: Plus or Pro is usually better for multiple clients.": "Astuce : Plus ou Pro convient généralement mieux pour plusieurs clients.",
        "Quickly review your details and create your account.": "Vérifie rapidement tes informations et crée ton compte.",
        "Source": "Source",
        "Tap + to get started": "Appuie sur + pour commencer",
        "Limit reached": "Limite atteinte",
        "OK": "OK",
        "No rooms in filter": "Aucune pièce dans le filtre",
        "Choose another client or create a room": "Choisis un autre client ou crée une pièce",
        "Search rooms": "Rechercher des pièces",
        "Select client for new room": "Sélectionner un client pour la nouvelle pièce",
        "Payment": "Paiement",
        "Rooms / Floors": "Pièces / Étages",
        "Export as Excel": "Exporter en Excel",
        "Edit": "Modifier",
        "Company name *": "Nom de l'entreprise *",
        "Required fields": "Champs obligatoires",
        "Contact person": "Personne de contact",
        "Payment method": "Mode de paiement",
        "Notes...": "Notes...",
        "Edit client": "Modifier le client",
        "Save failed": "Échec de la sauvegarde",
        "Unknown error.": "Erreur inconnue.",
        "Name and address are required.": "Le nom et l'adresse sont obligatoires.",
        "Start route": "Démarrer l'itinéraire",
        "Could not save client": "Impossible d'enregistrer le client",
        "Address *": "Adresse *",
        "Room name": "Nom de la pièce",
        "e.g. ground floor · storage · basement · upper floor": "p. ex. rez-de-chaussée · stockage · sous-sol · étage",
        "Number": "Numéro",
        "Due date": "Date d'échéance",
        "Status": "Statut",
        "Position": "Position",
        "traps": "pièges",
        "Move traps": "Déplacer les pièges",
        "Auto arrange": "Organisation automatique",
        "No traps yet": "Aucun piège pour l'instant",
        "Add trap": "Ajouter un piège",
        "Sort": "Trier",
        "Done": "Terminé",
        "Room area for trap positions": "Espace de la pièce pour les pièges",
        "Installed": "Installé",
        "Inspection interval": "Intervalle d'inspection",
        "Next inspection": "Prochaine inspection",
        "Details": "Détails",
        "Pest trend": "Tendance des nuisibles",
        "Add inspection": "Ajouter une inspection",
        "No inspections yet": "Aucune inspection",
        "Inspection history": "Historique des inspections",
        "Temperature": "Température",
        "Humidity": "Humidité",
        "Not enough data for trend yet.": "Pas encore assez de données.",
        "No change since last inspection.": "Pas de changement depuis la dernière inspection.",
        "since last inspection.": "depuis la dernière inspection.",
        "Filter": "Filtre",
        "At least 2 inspections with this metric are required to show a trend.": "Au moins 2 inspections avec cette métrique sont nécessaires pour afficher une tendance.",
        "Current": "Actuel",
        "Average": "Moyenne",
        "Empty": "Vide",
        "pests": "nuisibles",
        "Trap number (e.g. 1031-1)": "Numéro du piège (p. ex. 1031-1)",
        "The trap starts centered in the room area. You can adjust it later.": "Le piège commence centré dans la pièce. Tu peux l'ajuster plus tard.",
        "New trap": "Nouveau piège",
        "Inspection saved.": "Inspection enregistrée.",
        "Share report": "Partager le rapport",
        "Result": "Résultat",
        "Total": "Total",
        "Date & time": "Date et heure",
        "Notes, observations...": "Notes, observations...",
        "Add photos": "Ajouter des photos",
        "Maximum \\(maxPhotosPerInspection) photos per inspection (\\(min(existingPhotoCount + selectedPhotoData.count, maxPhotosPerInspection))/\\(maxPhotosPerInspection)).": "Maximum \\(maxPhotosPerInspection) photos par inspection (\\(min(existingPhotoCount + selectedPhotoData.count, maxPhotosPerInspection))/\\(maxPhotosPerInspection)).",
        "Edit inspection": "Modifier l'inspection",
        "Local photo save failed. Inspection was saved without new photos.": "Échec de la sauvegarde des photos. L'inspection a été enregistrée sans nouvelles photos.",
        "Photos could not be loaded. Inspection was saved without new photos.": "Les photos n'ont pas pu être chargées. L'inspection a été enregistrée sans nouvelles photos.",
        "PDF report was created automatically.": "Rapport PDF créé automatiquement.",
        "Inspection saved. Report could not be created.": "Inspection enregistrée. Le rapport n'a pas pu être créé."

    ]

    static let ptBRByEn: [String: String] = [
        "Dashboard": "Painel",
        "Rooms": "Ambientes",
        "Traps": "Armadilhas",
        "All clients": "Todos os clientes",
        "Select client": "Selecionar cliente",
        "Overdue": "Atrasado",
        "Due": "A vencer",
        "Due Items": "Pendências",
        "All": "Todos",
        "more": "mais",
        "No data yet": "Sem dados ainda",
        "Create clients and rooms first": "Crie clientes e ambientes primeiro",
        "Good morning": "Bom dia",
        "Good afternoon": "Boa tarde",
        "Good evening": "Boa noite",
        "Trap": "Armadilha",
        "All done": "Tudo certo",
        "No traps due": "Nenhuma armadilha pendente",
        "This week": "Esta semana",
        "All traps": "Todas as armadilhas",
        "Search traps": "Buscar armadilhas",
        "Email": "E-mail",
        "Current password": "Senha atual",
        "Email updated successfully.": "E-mail atualizado com sucesso.",
        "Save email": "Salvar e-mail",
        "Name": "Nome",
        "Security": "Segurança",
        "New password": "Nova senha",
        "Confirm new password": "Confirmar nova senha",
        "The new passwords do not match.": "As novas senhas não coincidem.",
        "Password updated successfully.": "Senha atualizada com sucesso.",
        "Save password": "Salvar senha",
        "Password": "Senha",
        "Subscription status": "Status da assinatura",
        "Payment & invoices": "Pagamento e faturas",
        "Manage": "Gerenciar",
        "Plan": "Plano",
        "Billing": "Cobrança",
        "Clients": "Clientes",
        "Rooms per client": "Ambientes por cliente",
        "Traps per room": "Armadilhas por ambiente",
        "Restore purchases": "Restaurar compras",
        "Manage subscription": "Gerenciar assinatura",
        "Subscription": "Assinatura",
        "Delete account": "Excluir conta",
        "I understand: account and data will be permanently deleted.": "Entendo: a conta e os dados serão excluídos permanentemente.",
        "Delete account permanently": "Excluir conta permanentemente",
        "Critical": "Crítico",
        "Sign out": "Sair",
        "Account": "Conta",
        "Sign out?": "Sair?",
        "Cancel": "Cancelar",
        "You will be signed out of your account.": "Você será desconectado da sua conta.",
        "Delete account now?": "Excluir conta agora?",
        "Delete": "Excluir",
        "This action cannot be undone.": "Esta ação não pode ser desfeita.",
        "Notifications": "Notificações",
        "Default inspection interval": "Intervalo padrão de inspeção",
        "days": "dias",
        "Language": "Idioma",
        "Trap numbers on pins": "Números das armadilhas nos pinos",
        "Settings": "Configurações",
        "Export data as CSV": "Exportar dados como CSV",
        "Share CSV": "Compartilhar CSV",
        "Export data as PDF": "Exportar dados como PDF",
        "Share PDF": "Compartilhar PDF",
        "Export": "Exportação",
        "Imprint": "Impressum",
        "Privacy Policy": "Política de Privacidade",
        "Terms & Conditions": "Termos e Condições",
        "Contact / Support": "Contato / Suporte",
        "App": "App",
        "Billing history": "Histórico de cobrança",
        "Payment & Invoices": "Pagamento e faturas",
        "Open in App Store": "Abrir na App Store",
        "View invoices": "Ver faturas",
        "Open online imprint": "Abrir impressum online",
        "Open full privacy policy": "Abrir política de privacidade completa",
        "Open terms": "Abrir termos",
        "Email support": "Suporte por e-mail",
        "Support page": "Página de suporte",
        "Welcome back": "Bem-vindo de volta",
        "Sign in": "Entrar",
        "or": "ou",
        "Sign in with Google": "Entrar com Google",
        "Onboarding": "Onboarding",
        "Quick sign in": "Login rápido",
        "New here? Start": "Novo aqui? Começar",
        "Already have an account?": "Já tem uma conta?",
        "Back": "Voltar",
        "Create account": "Criar conta",
        "Continue": "Continuar",
        "Welcome to IPM Manager": "Bem-vindo ao IPM Manager",
        "What is your name?": "Qual é o seu nome?",
        "First name": "Nome",
        "Last name": "Sobrenome",
        "Choose a username": "Escolha um nome de usuário",
        "Username": "Nome de usuário",
        "How did you hear about us?": "Como você nos conheceu?",
        "Almost done": "Quase pronto",
        "No clients yet": "Nenhum cliente ainda",
        "Search clients": "Buscar clientes",
        "Address": "Endereço",
        "Contact": "Contato",
        "Phone": "Telefone",
        "Notes": "Observações",
        "Add room": "Adicionar ambiente",
        "Share export": "Compartilhar exportação",
        "New client": "Novo cliente",
        "Save": "Salvar",
        "New room": "Novo ambiente",
        "Inspection": "Inspeção",
        "Measurement": "Medição",
        "Pests": "Pragas",
        "Guests": "Convidados",
        "Limit reached: The \\(tierTitle()) plan allows up to \\(max) clients. Please upgrade.": "Limite atingido: O plano \\(tierTitle()) permite até \\(max) clientes. Por favor, faça upgrade.",
        "Limit reached: The \\(tierTitle()) plan allows up to \\(max) rooms per client. Please upgrade.": "Limite atingido: O plano \\(tierTitle()) permite até \\(max) ambientes por cliente. Por favor, faça upgrade.",
        "Limit reached: The \\(tierTitle()) plan allows up to \\(max) traps per room. Please upgrade.": "Limite atingido: O plano \\(tierTitle()) permite até \\(max) armadilhas por ambiente. Por favor, faça upgrade.",
        "Please sign in first.": "Faça login primeiro.",
        "Inspection report": "Relatório de inspeção",
        "Client": "Cliente",
        "Room": "Ambiente",
        "Type": "Tipo",
        "Inspection date": "Data de inspeção",
        "Total count": "Contagem total",
        "Photos": "Fotos",
        "Findings": "Achados",
        "PDF report is only available on iOS.": "O relatório PDF está disponível apenas no iOS.",
        "PDF export is only available on iOS.": "O export de PDF está disponível apenas no iOS.",
        "Invalid client for export.": "Cliente inválido para exportação.",
        "Today": "Hoje",
        "No traps": "Nenhuma armadilha",
        "No traps found for the current filter": "Nenhuma armadilha encontrada no filtro atual",
        "Check-in": "Check-in",
        "Monthly": "Mensal",
        "Yearly (-10%)": "Anual (−10%)",
        "Unlimited": "Ilimitado",
        "Price pending": "Preço em breve",
        "valid until": "válido até",
        "CSV export created.": "Exportação CSV criada.",
        "PDF export created.": "Exportação PDF criada.",
        "Manage payment method": "Gerenciar método de pagamento",
        "Privacy Policy: This app processes account and operational inspection data to provide IPM features. See the full online policy for details.": "Política de Privacidade: Este aplicativo processa dados de conta e inspeção operacional para fornecer os recursos do IPM. Consulte a política completa online para mais detalhes.",
        "Terms & Conditions: App usage is subject to the applicable terms. Please read the full version online.": "Termos e Condições: O uso do aplicativo está sujeito aos termos aplicáveis. Leia a versão completa online.",
        "Prioritized due items": "Itens prioritários pendentes",
        "No dashboard data is currently available for this client.": "Nenhum dado do painel disponível para este cliente.",
        "Manage clients": "Gerenciar clientes",
        "Friends": "Amigos",
        "Recommendation": "Recomendação",
        "Checking email...": "Verificando e-mail...",
        "Please enter a valid email.": "Insira um e-mail válido.",
        "Email is available.": "E-mail disponível.",
        "Email is already taken.": "E-mail já está em uso.",
        "Could not check email right now.": "Não foi possível verificar o e-mail agora.",
        "Plan recommendation": "Recomendação de plano",
        "Choose Plus": "Escolher Plus",
        "Choose Pro": "Escolher Pro",
        "Stay on Free": "Continuar no Free",
        "With multiple clients, Plus or Pro is usually a better fit. You can switch anytime later.": "Com vários clientes, Plus ou Pro costuma ser melhor. Você pode mudar a qualquer momento.",
        "Step \\(step + 1) of \\(totalSteps)": "Passo \\(step + 1) de \\(totalSteps)",
        "We will set up your account in a few quick steps so you can start right away.": "Vamos configurar sua conta em alguns passos rápidos para você começar imediatamente.",
        "Rooms & traps": "Ambientes & armadilhas",
        "Inspection rhythm": "Ritmo de inspeção",
        "Your login": "Seu login",
        "At least 6 characters.": "Pelo menos 6 caracteres.",
        "This name will be shown on your profile.": "Este nome será exibido no seu perfil.",
        "How many clients do you currently manage?": "Quantos clientes você gerencia atualmente?",
        "Tip: Plus or Pro is usually better for multiple clients.": "Dica: Plus ou Pro costuma ser melhor para vários clientes.",
        "Quickly review your details and create your account.": "Revise rapidamente seus dados e crie sua conta.",
        "Source": "Fonte",
        "Tap + to get started": "Toque em + para começar",
        "Limit reached": "Limite atingido",
        "OK": "OK",
        "No rooms in filter": "Nenhum ambiente no filtro",
        "Choose another client or create a room": "Escolha outro cliente ou crie um ambiente",
        "Search rooms": "Buscar ambientes",
        "Select client for new room": "Selecionar cliente para novo ambiente",
        "Payment": "Pagamento",
        "Rooms / Floors": "Ambientes / Andares",
        "Export as Excel": "Exportar como Excel",
        "Edit": "Editar",
        "Company name *": "Nome da empresa *",
        "Required fields": "Campos obrigatórios",
        "Contact person": "Pessoa de contato",
        "Payment method": "Método de pagamento",
        "Notes...": "Observações...",
        "Edit client": "Editar cliente",
        "Save failed": "Falha ao salvar",
        "Unknown error.": "Erro desconhecido.",
        "Name and address are required.": "Nome e endereço são obrigatórios.",
        "Start route": "Iniciar rota",
        "Could not save client": "Não foi possível salvar o cliente",
        "Address *": "Endereço *",
        "Room name": "Nome do ambiente",
        "e.g. ground floor · storage · basement · upper floor": "ex.: térreo · depósito · porão · andar superior",
        "Number": "Número",
        "Due date": "Data de vencimento",
        "Status": "Status",
        "Position": "Posição",
        "traps": "armadilhas",
        "Move traps": "Mover armadilhas",
        "Auto arrange": "Organizar automaticamente",
        "No traps yet": "Nenhuma armadilha ainda",
        "Add trap": "Adicionar armadilha",
        "Sort": "Ordenar",
        "Done": "Concluído",
        "Room area for trap positions": "Área do ambiente para posições das armadilhas",
        "Installed": "Instalado",
        "Inspection interval": "Intervalo de inspeção",
        "Next inspection": "Próxima inspeção",
        "Details": "Detalhes",
        "Pest trend": "Tendência de pragas",
        "Add inspection": "Adicionar inspeção",
        "No inspections yet": "Nenhuma inspeção ainda",
        "Inspection history": "Histórico de inspeções",
        "Temperature": "Temperatura",
        "Humidity": "Umidade",
        "Not enough data for trend yet.": "Dados insuficientes para tendência.",
        "No change since last inspection.": "Sem alteração desde a última inspeção.",
        "since last inspection.": "desde a última inspeção.",
        "Filter": "Filtro",
        "At least 2 inspections with this metric are required to show a trend.": "São necessárias pelo menos 2 inspeções com esta métrica para exibir uma tendência.",
        "Current": "Atual",
        "Average": "Média",
        "Empty": "Vazio",
        "pests": "pragas",
        "Trap number (e.g. 1031-1)": "Número da armadilha (ex.: 1031-1)",
        "The trap starts centered in the room area. You can adjust it later.": "A armadilha começa centralizada na área do ambiente. Você pode ajustá-la depois.",
        "New trap": "Nova armadilha",
        "Inspection saved.": "Inspeção salva.",
        "Share report": "Compartilhar relatório",
        "Result": "Resultado",
        "Total": "Total",
        "Date & time": "Data e hora",
        "Notes, observations...": "Observações...",
        "Add photos": "Adicionar fotos",
        "Maximum \\(maxPhotosPerInspection) photos per inspection (\\(min(existingPhotoCount + selectedPhotoData.count, maxPhotosPerInspection))/\\(maxPhotosPerInspection)).": "Máximo \\(maxPhotosPerInspection) fotos por inspeção (\\(min(existingPhotoCount + selectedPhotoData.count, maxPhotosPerInspection))/\\(maxPhotosPerInspection)).",
        "Edit inspection": "Editar inspeção",
        "Local photo save failed. Inspection was saved without new photos.": "Falha ao salvar fotos locais. A inspeção foi salva sem novas fotos.",
        "Photos could not be loaded. Inspection was saved without new photos.": "As fotos não puderam ser carregadas. A inspeção foi salva sem novas fotos.",
        "PDF report was created automatically.": "Relatório PDF criado automaticamente.",
        "Inspection saved. Report could not be created.": "Inspeção salva. Não foi possível criar o relatório."

    ]

    static let nlByEn: [String: String] = [
        "Dashboard": "Dashboard",
        "Rooms": "Ruimtes",
        "Traps": "Vallen",
        "All clients": "Alle klanten",
        "Select client": "Klant kiezen",
        "Overdue": "Over tijd",
        "Due": "Vervalt",
        "Due Items": "Te controleren",
        "All": "Alle",
        "more": "meer",
        "No data yet": "Nog geen gegevens",
        "Create clients and rooms first": "Maak eerst klanten en ruimtes aan",
        "Good morning": "Goedemorgen",
        "Good afternoon": "Goedemiddag",
        "Good evening": "Goedenavond",
        "Trap": "Val",
        "All done": "Alles afgerond",
        "No traps due": "Geen vallen vervallen",
        "This week": "Deze week",
        "All traps": "Alle vallen",
        "Search traps": "Vallen zoeken",
        "Email": "E-mail",
        "Current password": "Huidig wachtwoord",
        "Email updated successfully.": "E-mail succesvol bijgewerkt.",
        "Save email": "E-mail opslaan",
        "Name": "Naam",
        "Security": "Beveiliging",
        "New password": "Nieuw wachtwoord",
        "Confirm new password": "Nieuw wachtwoord bevestigen",
        "The new passwords do not match.": "De nieuwe wachtwoorden komen niet overeen.",
        "Password updated successfully.": "Wachtwoord succesvol bijgewerkt.",
        "Save password": "Wachtwoord opslaan",
        "Password": "Wachtwoord",
        "Subscription status": "Abonnementsstatus",
        "Payment & invoices": "Betaling en facturen",
        "Manage": "Beheren",
        "Plan": "Plan",
        "Billing": "Facturatie",
        "Clients": "Klanten",
        "Rooms per client": "Ruimtes per klant",
        "Traps per room": "Vallen per ruimte",
        "Restore purchases": "Aankopen herstellen",
        "Manage subscription": "Abonnement beheren",
        "Subscription": "Abonnement",
        "Delete account": "Account verwijderen",
        "I understand: account and data will be permanently deleted.": "Ik begrijp het: account en gegevens worden permanent verwijderd.",
        "Delete account permanently": "Account permanent verwijderen",
        "Critical": "Kritiek",
        "Sign out": "Uitloggen",
        "Account": "Account",
        "Sign out?": "Uitloggen?",
        "Cancel": "Annuleren",
        "You will be signed out of your account.": "Je wordt uit je account uitgelogd.",
        "Delete account now?": "Account nu verwijderen?",
        "Delete": "Verwijderen",
        "This action cannot be undone.": "Deze actie kan niet ongedaan worden gemaakt.",
        "Notifications": "Meldingen",
        "Default inspection interval": "Standaard inspectie-interval",
        "days": "dagen",
        "Language": "Taal",
        "Trap numbers on pins": "Valnummers op pins",
        "Settings": "Instellingen",
        "Export data as CSV": "Gegevens exporteren als CSV",
        "Share CSV": "CSV delen",
        "Export data as PDF": "Gegevens exporteren als PDF",
        "Share PDF": "PDF delen",
        "Export": "Export",
        "Imprint": "Colofon",
        "Privacy Policy": "Privacybeleid",
        "Terms & Conditions": "Algemene voorwaarden",
        "Contact / Support": "Contact / Support",
        "App": "App",
        "Billing history": "Factuurgeschiedenis",
        "Payment & Invoices": "Betaling en facturen",
        "Open in App Store": "Openen in App Store",
        "View invoices": "Facturen bekijken",
        "Open online imprint": "Online colofon openen",
        "Open full privacy policy": "Volledig privacybeleid openen",
        "Open terms": "Voorwaarden openen",
        "Email support": "E-mail support",
        "Support page": "Supportpagina",
        "Welcome back": "Welkom terug",
        "Sign in": "Inloggen",
        "or": "of",
        "Sign in with Google": "Inloggen met Google",
        "Onboarding": "Onboarding",
        "Quick sign in": "Snel inloggen",
        "New here? Start": "Nieuw hier? Start",
        "Already have an account?": "Heb je al een account?",
        "Back": "Terug",
        "Create account": "Account aanmaken",
        "Continue": "Doorgaan",
        "Welcome to IPM Manager": "Welkom bij IPM Manager",
        "What is your name?": "Hoe heet je?",
        "First name": "Voornaam",
        "Last name": "Achternaam",
        "Choose a username": "Kies een gebruikersnaam",
        "Username": "Gebruikersnaam",
        "How did you hear about us?": "Hoe heb je van ons gehoord?",
        "Almost done": "Bijna klaar",
        "No clients yet": "Nog geen klanten",
        "Search clients": "Klanten zoeken",
        "Address": "Adres",
        "Contact": "Contact",
        "Phone": "Telefoon",
        "Notes": "Notities",
        "Add room": "Ruimte toevoegen",
        "Share export": "Export delen",
        "New client": "Nieuwe klant",
        "Save": "Opslaan",
        "New room": "Nieuwe ruimte",
        "Inspection": "Inspectie",
        "Measurement": "Meting",
        "Pests": "Plagen",
        "Guests": "Gasten",
        "Limit reached: The \\(tierTitle()) plan allows up to \\(max) clients. Please upgrade.": "Limiet bereikt: Het \\(tierTitle())-abonnement staat maximaal \\(max) klanten toe. Upgrade alsjeblieft.",
        "Limit reached: The \\(tierTitle()) plan allows up to \\(max) rooms per client. Please upgrade.": "Limiet bereikt: Het \\(tierTitle())-abonnement staat maximaal \\(max) ruimtes per klant toe. Upgrade alsjeblieft.",
        "Limit reached: The \\(tierTitle()) plan allows up to \\(max) traps per room. Please upgrade.": "Limiet bereikt: Het \\(tierTitle())-abonnement staat maximaal \\(max) vallen per ruimte toe. Upgrade alsjeblieft.",
        "Please sign in first.": "Meld je eerst aan.",
        "Inspection report": "Inspectierapport",
        "Client": "Klant",
        "Room": "Ruimte",
        "Type": "Type",
        "Inspection date": "Inspectiedatum",
        "Total count": "Totaal aantal",
        "Photos": "Foto's",
        "Findings": "Bevindingen",
        "PDF report is only available on iOS.": "PDF-rapport is alleen beschikbaar op iOS.",
        "PDF export is only available on iOS.": "PDF-export is alleen beschikbaar op iOS.",
        "Invalid client for export.": "Ongeldige klant voor export.",
        "Today": "Vandaag",
        "No traps": "Geen vallen",
        "No traps found for the current filter": "Geen vallen gevonden voor het huidige filter",
        "Check-in": "Check-in",
        "Monthly": "Maandelijks",
        "Yearly (-10%)": "Jaarlijks (−10%)",
        "Unlimited": "Onbeperkt",
        "Price pending": "Prijs volgt",
        "valid until": "geldig tot",
        "CSV export created.": "CSV-export aangemaakt.",
        "PDF export created.": "PDF-export aangemaakt.",
        "Manage payment method": "Betaalmethode beheren",
        "Privacy Policy: This app processes account and operational inspection data to provide IPM features. See the full online policy for details.": "Privacybeleid: Deze app verwerkt account- en inspectiegegevens om IPM-functies te bieden. Zie het volledige online beleid voor meer informatie.",
        "Terms & Conditions: App usage is subject to the applicable terms. Please read the full version online.": "Algemene Voorwaarden: Het gebruik van de app is onderworpen aan de geldende voorwaarden. Lees de volledige versie online.",
        "Prioritized due items": "Prioritaire vervallende items",
        "No dashboard data is currently available for this client.": "Er zijn momenteel geen dashboardgegevens beschikbaar voor deze klant.",
        "Manage clients": "Klanten beheren",
        "Friends": "Vrienden",
        "Recommendation": "Aanbeveling",
        "Checking email...": "E-mail controleren...",
        "Please enter a valid email.": "Voer een geldig e-mailadres in.",
        "Email is available.": "E-mail beschikbaar.",
        "Email is already taken.": "E-mail al in gebruik.",
        "Could not check email right now.": "Kan e-mail momenteel niet controleren.",
        "Plan recommendation": "Planaanbeveling",
        "Choose Plus": "Plus kiezen",
        "Choose Pro": "Pro kiezen",
        "Stay on Free": "Blijf bij Free",
        "With multiple clients, Plus or Pro is usually a better fit. You can switch anytime later.": "Met meerdere klanten past Plus of Pro meestal beter. Je kunt altijd later overstappen.",
        "Step \\(step + 1) of \\(totalSteps)": "Stap \\(step + 1) van \\(totalSteps)",
        "We will set up your account in a few quick steps so you can start right away.": "We stellen je account in een paar stappen in zodat je meteen kunt beginnen.",
        "Rooms & traps": "Ruimtes & vallen",
        "Inspection rhythm": "Inspectieritmiek",
        "Your login": "Jouw login",
        "At least 6 characters.": "Minimaal 6 tekens.",
        "This name will be shown on your profile.": "Deze naam wordt weergegeven op je profiel.",
        "How many clients do you currently manage?": "Hoeveel klanten beheer je momenteel?",
        "Tip: Plus or Pro is usually better for multiple clients.": "Tip: Plus of Pro is meestal beter voor meerdere klanten.",
        "Quickly review your details and create your account.": "Controleer snel je gegevens en maak je account aan.",
        "Source": "Bron",
        "Tap + to get started": "Tik op + om te beginnen",
        "Limit reached": "Limiet bereikt",
        "OK": "OK",
        "No rooms in filter": "Geen ruimtes in filter",
        "Choose another client or create a room": "Kies een andere klant of maak een ruimte aan",
        "Search rooms": "Ruimtes zoeken",
        "Select client for new room": "Klant selecteren voor nieuwe ruimte",
        "Payment": "Betaling",
        "Rooms / Floors": "Ruimtes / Verdiepingen",
        "Export as Excel": "Exporteren als Excel",
        "Edit": "Bewerken",
        "Company name *": "Bedrijfsnaam *",
        "Required fields": "Verplichte velden",
        "Contact person": "Contactpersoon",
        "Payment method": "Betaalmethode",
        "Notes...": "Notities...",
        "Edit client": "Klant bewerken",
        "Save failed": "Opslaan mislukt",
        "Unknown error.": "Onbekende fout.",
        "Name and address are required.": "Naam en adres zijn verplicht.",
        "Start route": "Route starten",
        "Could not save client": "Klant kon niet worden opgeslagen",
        "Address *": "Adres *",
        "Room name": "Ruimtenaam",
        "e.g. ground floor · storage · basement · upper floor": "bijv. begane grond · opslag · kelder · bovenverdieping",
        "Number": "Nummer",
        "Due date": "Vervaldatum",
        "Status": "Status",
        "Position": "Positie",
        "traps": "vallen",
        "Move traps": "Vallen verplaatsen",
        "Auto arrange": "Automatisch rangschikken",
        "No traps yet": "Nog geen vallen",
        "Add trap": "Val toevoegen",
        "Sort": "Sorteren",
        "Done": "Klaar",
        "Room area for trap positions": "Ruimtegebied voor valposities",
        "Installed": "Geïnstalleerd",
        "Inspection interval": "Inspectie-interval",
        "Next inspection": "Volgende inspectie",
        "Details": "Details",
        "Pest trend": "Plaagtrend",
        "Add inspection": "Inspectie toevoegen",
        "No inspections yet": "Nog geen inspecties",
        "Inspection history": "Inspectiegeschiedenis",
        "Temperature": "Temperatuur",
        "Humidity": "Luchtvochtigheid",
        "Not enough data for trend yet.": "Nog niet genoeg gegevens voor trend.",
        "No change since last inspection.": "Geen wijziging sinds laatste inspectie.",
        "since last inspection.": "sinds de laatste inspectie.",
        "Filter": "Filter",
        "At least 2 inspections with this metric are required to show a trend.": "Er zijn minimaal 2 inspecties met deze metric nodig om een trend te tonen.",
        "Current": "Huidig",
        "Average": "Gemiddeld",
        "Empty": "Leeg",
        "pests": "plagen",
        "Trap number (e.g. 1031-1)": "Valnummer (bijv. 1031-1)",
        "The trap starts centered in the room area. You can adjust it later.": "De val begint gecentreerd in de ruimte. Je kunt dit later aanpassen.",
        "New trap": "Nieuwe val",
        "Inspection saved.": "Inspectie opgeslagen.",
        "Share report": "Rapport delen",
        "Result": "Resultaat",
        "Total": "Totaal",
        "Date & time": "Datum en tijd",
        "Notes, observations...": "Notities, observaties...",
        "Add photos": "Foto's toevoegen",
        "Maximum \\(maxPhotosPerInspection) photos per inspection (\\(min(existingPhotoCount + selectedPhotoData.count, maxPhotosPerInspection))/\\(maxPhotosPerInspection)).": "Maximaal \\(maxPhotosPerInspection) foto's per inspectie (\\(min(existingPhotoCount + selectedPhotoData.count, maxPhotosPerInspection))/\\(maxPhotosPerInspection)).",
        "Edit inspection": "Inspectie bewerken",
        "Local photo save failed. Inspection was saved without new photos.": "Opslaan van lokale foto mislukt. Inspectie opgeslagen zonder nieuwe foto's.",
        "Photos could not be loaded. Inspection was saved without new photos.": "Foto's konden niet worden geladen. Inspectie opgeslagen zonder nieuwe foto's.",
        "PDF report was created automatically.": "PDF-rapport automatisch aangemaakt.",
        "Inspection saved. Report could not be created.": "Inspectie opgeslagen. Rapport kon niet worden aangemaakt."

    ]

    static let frByDe: [String: String] = [:]
    static let ptBRByDe: [String: String] = [:]
    static let nlByDe: [String: String] = [:]
}

enum IPMKeyboardType {
    case `default`
    case emailAddress
    case numberPad
    case decimalPad
    case phonePad
    case namePhonePad
    case url
}

extension View {
    @ViewBuilder
    func ipmKeyboardType(_ type: IPMKeyboardType) -> some View {
#if canImport(UIKit)
        switch type {
        case .default:
            self.keyboardType(.default)
        case .emailAddress:
            self.keyboardType(.emailAddress)
        case .numberPad:
            self.keyboardType(.numberPad)
        case .decimalPad:
            self.keyboardType(.decimalPad)
        case .phonePad:
            self.keyboardType(.phonePad)
        case .namePhonePad:
            self.keyboardType(.namePhonePad)
        case .url:
            self.keyboardType(.URL)
        }
#else
        self
#endif
    }

    @ViewBuilder
    func ipmNoAutocapitalization() -> some View {
#if canImport(UIKit)
        self.autocapitalization(.none)
#else
        self
#endif
    }
}

extension View {
    @ViewBuilder
    func ipmNavigationBarTitleDisplayModeInline() -> some View {
#if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
#else
        self
#endif
    }

    @ViewBuilder
    func ipmNavigationBarTitleDisplayModeLarge() -> some View {
#if os(iOS)
        self.navigationBarTitleDisplayMode(.large)
#else
        self
#endif
    }

    @ViewBuilder
    func ipmNavigationBarHidden() -> some View {
#if os(iOS)
        self.toolbar(.hidden, for: .navigationBar)
#else
        self
#endif
    }
}

// MARK: - Section Label
struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(IPMColors.brownMid)
            .textCase(.uppercase)
            .tracking(0.4)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    @Environment(\.colorScheme) var scheme
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(color)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(IPMColors.brownMid)
                if !value.isEmpty {
                    Text(value)
                        .font(.system(size: 14))
                        .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                }
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Status Pill
struct StatusPill: View {
    @AppStorage("appLanguage") private var appLanguage = "de"
    let status: FaelligkeitStatus
    var body: some View {
        Text(status.label(language: appLanguage))
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.color.opacity(0.12))
            .clipShape(Capsule())
    }
}

// MARK: - IPM Form Field (für Sheets/Forms)
struct IPMFormField: View {
    @Environment(\.colorScheme) var scheme
    let label: String
    @Binding var text: String
    let icon: String
    var iconColor: Color = IPMColors.brownMid
    var keyboard: IPMKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(iconColor)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(IPMColors.brownMid)
                if isSecure {
                    SecureField("", text: $text)
                        .font(.system(size: 15))
                        .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                } else {
                    TextField("", text: $text)
                        .font(.system(size: 15))
                        .foregroundStyle(AdaptiveColor.textPrimary(scheme))
                        .ipmKeyboardType(keyboard)
                        .ipmNoAutocapitalization()
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - IPM Text Field (für Login)
struct IPMTextField: View {
    @Environment(\.colorScheme) var scheme
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboard: IPMKeyboardType = .default
    var isSecure: Bool = false
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(focused ? IPMColors.green : IPMColors.brownMid)
                .frame(width: 20)
                .animation(IPMMotion.focusEase, value: focused)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .focused($focused)
                    .font(.system(size: 15))
                    .foregroundStyle(AdaptiveColor.textPrimary(scheme))
            } else {
                TextField(placeholder, text: $text)
                    .focused($focused)
                    .ipmKeyboardType(keyboard)
                    .ipmNoAutocapitalization()
                    .font(.system(size: 15))
                    .foregroundStyle(AdaptiveColor.textPrimary(scheme))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(AdaptiveColor.cardSecondary(scheme))
        .shadow(
            color: IPMColors.shadow.opacity(focused ? 0.12 : 0.04),
            radius: focused ? 14 : 8,
            y: focused ? 8 : 4
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(focused ? IPMColors.green.opacity(0.45) : .white.opacity(scheme == .dark ? 0.04 : 0.28), lineWidth: 1.2)
        )
        .scaleEffect(focused ? 1.01 : 1)
        .animation(IPMMotion.focusEase, value: focused)
    }
}

// MARK: - Empty State
struct IPMEmptyState: View {
    @Environment(\.colorScheme) private var scheme
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                IPMColors.green.opacity(0.16),
                                IPMColors.greenLight.opacity(0.3),
                                AdaptiveColor.cardSecondary(scheme)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 164, height: 112)

                Circle()
                    .fill(IPMColors.green.opacity(0.18))
                    .frame(width: 72, height: 72)
                    .offset(x: 36, y: -26)

                Image(systemName: icon)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(IPMColors.greenDark)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(AdaptiveColor.textPrimary(scheme))
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(IPMColors.brownMid)
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }
}

// MARK: - Motion / Interaction
struct IPMPressableStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .opacity(configuration.isPressed ? 0.95 : 1)
            .brightness(configuration.isPressed ? -0.01 : 0)
            .animation(IPMMotion.pressSpring, value: configuration.isPressed)
    }
}

private struct IPMFlowEntranceModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 14)
            .scaleEffect(isVisible ? 1 : 0.985)
            .onAppear {
                guard !isVisible else { return }
                withAnimation(IPMMotion.sectionSpring.delay(delay)) {
                    isVisible = true
                }
            }
    }
}

extension AnyTransition {
    static var ipmFadeSlide: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .move(edge: .bottom)),
            removal: .opacity
        )
    }

    static var ipmScreenSwap: AnyTransition {
        .asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.985)).combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .scale(scale: 0.98))
        )
    }
}

extension View {
    func ipmFlowEntrance(delay: Double = 0) -> some View {
        modifier(IPMFlowEntranceModifier(delay: delay))
    }
}
struct IPMAnimatedBackdrop: View {
    @Environment(\.colorScheme) private var scheme
    @State private var animate = false

    var body: some View {
        ZStack {
            AdaptiveColor.background(scheme).ignoresSafeArea()

            LinearGradient(
                colors: [
                    IPMColors.mist.opacity(scheme == .dark ? 0.05 : 0.95),
                    IPMColors.greenLight.opacity(scheme == .dark ? 0.08 : 0.24),
                    AdaptiveColor.background(scheme)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Circle()
                .fill(IPMColors.green.opacity(scheme == .dark ? 0.14 : 0.1))
                .frame(width: 360, height: 360)
                .blur(radius: 42)
                .offset(x: animate ? 130 : 82, y: animate ? -246 : -212)

            RoundedRectangle(cornerRadius: 96, style: .continuous)
                .fill(IPMColors.greenLight.opacity(scheme == .dark ? 0.08 : 0.13))
                .frame(width: 280, height: 280)
                .rotationEffect(.degrees(animate ? 18 : 5))
                .blur(radius: 30)
                .offset(x: animate ? -142 : -168, y: animate ? 292 : 246)
        }
        .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animate)
        .onAppear { animate = true }
    }
}
