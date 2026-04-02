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
        "Limit reached: The \\(tierTitle()) plan allows up to \\(max) clients. Please upgrade.": "Limit reached: The \\(tierTitle()) plan allows up to \\(max) clients. Please upgrade.",
        "Limit reached: The \\(tierTitle()) plan allows up to \\(max) rooms per client. Please upgrade.": "Limit reached: The \\(tierTitle()) plan allows up to \\(max) rooms per client. Please upgrade.",
        "Limit reached: The \\(tierTitle()) plan allows up to \\(max) traps per room. Please upgrade.": "Limit reached: The \\(tierTitle()) plan allows up to \\(max) traps per room. Please upgrade.",
        "Please sign in first.": "Veuillez d'abord vous connecter.",
        "Inspection report": "Inspection report",
        "Client": "Client",
        "Room": "Room",
        "Type": "Type",
        "Inspection date": "Inspection date",
        "Total count": "Total count",
        "Photos": "Photos",
        "Findings": "Findings",
        "PDF report is only available on iOS.": "PDF report is only available on iOS.",
        "PDF export is only available on iOS.": "PDF export is only available on iOS.",
        "Invalid client for export.": "Invalid client for export.",
        "Today": "Today",
        "No traps": "No traps",
        "No traps found for the current filter": "No traps found for the current filter",
        "Check-in": "Check-in",
        "Monthly": "Monthly",
        "Yearly (-10%)": "Yearly (-10%)",
        "Unlimited": "Unlimited",
        "Price pending": "Price pending",
        "valid until": "valid until",
        "CSV export created.": "CSV export created.",
        "PDF export created.": "PDF export created.",
        "Manage payment method": "Manage payment method",
        "Privacy Policy: This app processes account and operational inspection data to provide IPM features. See the full online policy for details.": "Privacy Policy: This app processes account and operational inspection data to provide IPM features. See the full online policy for details.",
        "Terms & Conditions: App usage is subject to the applicable terms. Please read the full version online.": "Terms & Conditions: App usage is subject to the applicable terms. Please read the full version online.",
        "Prioritized due items": "Prioritized due items",
        "No dashboard data is currently available for this client.": "No dashboard data is currently available for this client.",
        "Manage clients": "Manage clients",
        "Friends": "Friends",
        "Recommendation": "Recommendation",
        "Checking email...": "Checking email...",
        "Please enter a valid email.": "Please enter a valid email.",
        "Email is available.": "Email is available.",
        "Email is already taken.": "Email is already taken.",
        "Could not check email right now.": "Could not check email right now.",
        "Plan recommendation": "Plan recommendation",
        "Choose Plus": "Choose Plus",
        "Choose Pro": "Choose Pro",
        "Stay on Free": "Stay on Free",
        "With multiple clients, Plus or Pro is usually a better fit. You can switch anytime later.": "With multiple clients, Plus or Pro is usually a better fit. You can switch anytime later.",
        "Step \\(step + 1) of \\(totalSteps)": "Step \\(step + 1) of \\(totalSteps)",
        "We will set up your account in a few quick steps so you can start right away.": "We will set up your account in a few quick steps so you can start right away.",
        "Rooms & traps": "Rooms & traps",
        "Inspection rhythm": "Inspection rhythm",
        "Your login": "Your login",
        "At least 6 characters.": "At least 6 characters.",
        "This name will be shown on your profile.": "This name will be shown on your profile.",
        "How many clients do you currently manage?": "How many clients do you currently manage?",
        "Tip: Plus or Pro is usually better for multiple clients.": "Tip: Plus or Pro is usually better for multiple clients.",
        "Quickly review your details and create your account.": "Quickly review your details and create your account.",
        "Source": "Source",
        "Tap + to get started": "Tap + to get started",
        "Limit reached": "Limite atteinte",
        "OK": "OK",
        "No rooms in filter": "No rooms in filter",
        "Choose another client or create a room": "Choose another client or create a room",
        "Search rooms": "Search rooms",
        "Select client for new room": "Select client for new room",
        "Payment": "Payment",
        "Rooms / Floors": "Rooms / Floors",
        "Export as Excel": "Export as Excel",
        "Edit": "Edit",
        "Company name *": "Company name *",
        "Required fields": "Required fields",
        "Contact person": "Contact person",
        "Payment method": "Payment method",
        "Notes...": "Notes...",
        "Edit client": "Edit client",
        "Save failed": "Save failed",
        "Unknown error.": "Unknown error.",
        "Name and address are required.": "Name and address are required.",
        "Start route": "Start route",
        "Could not save client": "Could not save client",
        "Address *": "Address *",
        "Room name": "Room name",
        "e.g. ground floor · storage · basement · upper floor": "p. ex. rez-de-chaussée · stockage · sous-sol · étage",
        "Number": "Number",
        "Due date": "Due date",
        "Status": "Status",
        "Position": "Position",
        "traps": "traps",
        "Move traps": "Move traps",
        "Auto arrange": "Auto arrange",
        "No traps yet": "No traps yet",
        "Add trap": "Add trap",
        "Sort": "Sort",
        "Done": "Done",
        "Room area for trap positions": "Room area for trap positions",
        "Installed": "Installed",
        "Inspection interval": "Inspection interval",
        "Next inspection": "Next inspection",
        "Details": "Details",
        "Pest trend": "Pest trend",
        "Add inspection": "Add inspection",
        "No inspections yet": "No inspections yet",
        "Inspection history": "Inspection history",
        "Temperature": "Temperature",
        "Humidity": "Humidity",
        "Not enough data for trend yet.": "Not enough data for trend yet.",
        "No change since last inspection.": "No change since last inspection.",
        "since last inspection.": "since last inspection.",
        "Filter": "Filter",
        "At least 2 inspections with this metric are required to show a trend.": "At least 2 inspections with this metric are required to show a trend.",
        "Current": "Current",
        "Average": "Average",
        "Empty": "Empty",
        "pests": "pests",
        "Trap number (e.g. 1031-1)": "Trap number (e.g. 1031-1)",
        "The trap starts centered in the room area. You can adjust it later.": "The trap starts centered in the room area. You can adjust it later.",
        "New trap": "New trap",
        "Inspection saved.": "Inspection saved.",
        "Share report": "Share report",
        "Result": "Result",
        "Total": "Total",
        "Date & time": "Date & time",
        "Notes, observations...": "Notes, observations...",
        "Add photos": "Add photos",
        "Maximum \\(maxPhotosPerInspection) photos per inspection (\\(min(existingPhotoCount + selectedPhotoData.count, maxPhotosPerInspection))/\\(maxPhotosPerInspection)).": "Maximum \\(maxPhotosPerInspection) photos per inspection (\\(min(existingPhotoCount + selectedPhotoData.count, maxPhotosPerInspection))/\\(maxPhotosPerInspection)).",
        "Edit inspection": "Edit inspection",
        "Local photo save failed. Inspection was saved without new photos.": "Local photo save failed. Inspection was saved without new photos.",
        "Photos could not be loaded. Inspection was saved without new photos.": "Photos could not be loaded. Inspection was saved without new photos.",
        "PDF report was created automatically.": "PDF report was created automatically.",
        "Inspection saved. Report could not be created.": "Inspection saved. Report could not be created."
    
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
        "Limit reached: The \\(tierTitle()) plan allows up to \\(max) clients. Please upgrade.": "Limit reached: The \\(tierTitle()) plan allows up to \\(max) clients. Please upgrade.",
        "Limit reached: The \\(tierTitle()) plan allows up to \\(max) rooms per client. Please upgrade.": "Limit reached: The \\(tierTitle()) plan allows up to \\(max) rooms per client. Please upgrade.",
        "Limit reached: The \\(tierTitle()) plan allows up to \\(max) traps per room. Please upgrade.": "Limit reached: The \\(tierTitle()) plan allows up to \\(max) traps per room. Please upgrade.",
        "Please sign in first.": "Faça login primeiro.",
        "Inspection report": "Inspection report",
        "Client": "Client",
        "Room": "Room",
        "Type": "Type",
        "Inspection date": "Inspection date",
        "Total count": "Total count",
        "Photos": "Photos",
        "Findings": "Findings",
        "PDF report is only available on iOS.": "PDF report is only available on iOS.",
        "PDF export is only available on iOS.": "PDF export is only available on iOS.",
        "Invalid client for export.": "Invalid client for export.",
        "Today": "Today",
        "No traps": "No traps",
        "No traps found for the current filter": "No traps found for the current filter",
        "Check-in": "Check-in",
        "Monthly": "Monthly",
        "Yearly (-10%)": "Yearly (-10%)",
        "Unlimited": "Unlimited",
        "Price pending": "Price pending",
        "valid until": "valid until",
        "CSV export created.": "CSV export created.",
        "PDF export created.": "PDF export created.",
        "Manage payment method": "Manage payment method",
        "Privacy Policy: This app processes account and operational inspection data to provide IPM features. See the full online policy for details.": "Privacy Policy: This app processes account and operational inspection data to provide IPM features. See the full online policy for details.",
        "Terms & Conditions: App usage is subject to the applicable terms. Please read the full version online.": "Terms & Conditions: App usage is subject to the applicable terms. Please read the full version online.",
        "Prioritized due items": "Prioritized due items",
        "No dashboard data is currently available for this client.": "No dashboard data is currently available for this client.",
        "Manage clients": "Manage clients",
        "Friends": "Friends",
        "Recommendation": "Recommendation",
        "Checking email...": "Checking email...",
        "Please enter a valid email.": "Please enter a valid email.",
        "Email is available.": "Email is available.",
        "Email is already taken.": "Email is already taken.",
        "Could not check email right now.": "Could not check email right now.",
        "Plan recommendation": "Plan recommendation",
        "Choose Plus": "Choose Plus",
        "Choose Pro": "Choose Pro",
        "Stay on Free": "Stay on Free",
        "With multiple clients, Plus or Pro is usually a better fit. You can switch anytime later.": "With multiple clients, Plus or Pro is usually a better fit. You can switch anytime later.",
        "Step \\(step + 1) of \\(totalSteps)": "Step \\(step + 1) of \\(totalSteps)",
        "We will set up your account in a few quick steps so you can start right away.": "We will set up your account in a few quick steps so you can start right away.",
        "Rooms & traps": "Rooms & traps",
        "Inspection rhythm": "Inspection rhythm",
        "Your login": "Your login",
        "At least 6 characters.": "At least 6 characters.",
        "This name will be shown on your profile.": "This name will be shown on your profile.",
        "How many clients do you currently manage?": "How many clients do you currently manage?",
        "Tip: Plus or Pro is usually better for multiple clients.": "Tip: Plus or Pro is usually better for multiple clients.",
        "Quickly review your details and create your account.": "Quickly review your details and create your account.",
        "Source": "Source",
        "Tap + to get started": "Tap + to get started",
        "Limit reached": "Limite atingido",
        "OK": "OK",
        "No rooms in filter": "No rooms in filter",
        "Choose another client or create a room": "Choose another client or create a room",
        "Search rooms": "Search rooms",
        "Select client for new room": "Select client for new room",
        "Payment": "Payment",
        "Rooms / Floors": "Rooms / Floors",
        "Export as Excel": "Export as Excel",
        "Edit": "Edit",
        "Company name *": "Company name *",
        "Required fields": "Required fields",
        "Contact person": "Contact person",
        "Payment method": "Payment method",
        "Notes...": "Notes...",
        "Edit client": "Edit client",
        "Save failed": "Save failed",
        "Unknown error.": "Unknown error.",
        "Name and address are required.": "Name and address are required.",
        "Start route": "Start route",
        "Could not save client": "Could not save client",
        "Address *": "Address *",
        "Room name": "Room name",
        "e.g. ground floor · storage · basement · upper floor": "ex.: térreo · depósito · porão · andar superior",
        "Number": "Number",
        "Due date": "Due date",
        "Status": "Status",
        "Position": "Position",
        "traps": "traps",
        "Move traps": "Move traps",
        "Auto arrange": "Auto arrange",
        "No traps yet": "No traps yet",
        "Add trap": "Add trap",
        "Sort": "Sort",
        "Done": "Done",
        "Room area for trap positions": "Room area for trap positions",
        "Installed": "Installed",
        "Inspection interval": "Inspection interval",
        "Next inspection": "Next inspection",
        "Details": "Details",
        "Pest trend": "Pest trend",
        "Add inspection": "Add inspection",
        "No inspections yet": "No inspections yet",
        "Inspection history": "Inspection history",
        "Temperature": "Temperature",
        "Humidity": "Humidity",
        "Not enough data for trend yet.": "Not enough data for trend yet.",
        "No change since last inspection.": "No change since last inspection.",
        "since last inspection.": "since last inspection.",
        "Filter": "Filter",
        "At least 2 inspections with this metric are required to show a trend.": "At least 2 inspections with this metric are required to show a trend.",
        "Current": "Current",
        "Average": "Average",
        "Empty": "Empty",
        "pests": "pests",
        "Trap number (e.g. 1031-1)": "Trap number (e.g. 1031-1)",
        "The trap starts centered in the room area. You can adjust it later.": "The trap starts centered in the room area. You can adjust it later.",
        "New trap": "New trap",
        "Inspection saved.": "Inspection saved.",
        "Share report": "Share report",
        "Result": "Result",
        "Total": "Total",
        "Date & time": "Date & time",
        "Notes, observations...": "Notes, observations...",
        "Add photos": "Add photos",
        "Maximum \\(maxPhotosPerInspection) photos per inspection (\\(min(existingPhotoCount + selectedPhotoData.count, maxPhotosPerInspection))/\\(maxPhotosPerInspection)).": "Maximum \\(maxPhotosPerInspection) photos per inspection (\\(min(existingPhotoCount + selectedPhotoData.count, maxPhotosPerInspection))/\\(maxPhotosPerInspection)).",
        "Edit inspection": "Edit inspection",
        "Local photo save failed. Inspection was saved without new photos.": "Local photo save failed. Inspection was saved without new photos.",
        "Photos could not be loaded. Inspection was saved without new photos.": "Photos could not be loaded. Inspection was saved without new photos.",
        "PDF report was created automatically.": "PDF report was created automatically.",
        "Inspection saved. Report could not be created.": "Inspection saved. Report could not be created."
    
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
        "Limit reached: The \\(tierTitle()) plan allows up to \\(max) clients. Please upgrade.": "Limit reached: The \\(tierTitle()) plan allows up to \\(max) clients. Please upgrade.",
        "Limit reached: The \\(tierTitle()) plan allows up to \\(max) rooms per client. Please upgrade.": "Limit reached: The \\(tierTitle()) plan allows up to \\(max) rooms per client. Please upgrade.",
        "Limit reached: The \\(tierTitle()) plan allows up to \\(max) traps per room. Please upgrade.": "Limit reached: The \\(tierTitle()) plan allows up to \\(max) traps per room. Please upgrade.",
        "Please sign in first.": "Meld je eerst aan.",
        "Inspection report": "Inspection report",
        "Client": "Client",
        "Room": "Room",
        "Type": "Type",
        "Inspection date": "Inspection date",
        "Total count": "Total count",
        "Photos": "Photos",
        "Findings": "Findings",
        "PDF report is only available on iOS.": "PDF report is only available on iOS.",
        "PDF export is only available on iOS.": "PDF export is only available on iOS.",
        "Invalid client for export.": "Invalid client for export.",
        "Today": "Today",
        "No traps": "No traps",
        "No traps found for the current filter": "No traps found for the current filter",
        "Check-in": "Check-in",
        "Monthly": "Monthly",
        "Yearly (-10%)": "Yearly (-10%)",
        "Unlimited": "Unlimited",
        "Price pending": "Price pending",
        "valid until": "valid until",
        "CSV export created.": "CSV export created.",
        "PDF export created.": "PDF export created.",
        "Manage payment method": "Manage payment method",
        "Privacy Policy: This app processes account and operational inspection data to provide IPM features. See the full online policy for details.": "Privacy Policy: This app processes account and operational inspection data to provide IPM features. See the full online policy for details.",
        "Terms & Conditions: App usage is subject to the applicable terms. Please read the full version online.": "Terms & Conditions: App usage is subject to the applicable terms. Please read the full version online.",
        "Prioritized due items": "Prioritized due items",
        "No dashboard data is currently available for this client.": "No dashboard data is currently available for this client.",
        "Manage clients": "Manage clients",
        "Friends": "Friends",
        "Recommendation": "Recommendation",
        "Checking email...": "Checking email...",
        "Please enter a valid email.": "Please enter a valid email.",
        "Email is available.": "Email is available.",
        "Email is already taken.": "Email is already taken.",
        "Could not check email right now.": "Could not check email right now.",
        "Plan recommendation": "Plan recommendation",
        "Choose Plus": "Choose Plus",
        "Choose Pro": "Choose Pro",
        "Stay on Free": "Stay on Free",
        "With multiple clients, Plus or Pro is usually a better fit. You can switch anytime later.": "With multiple clients, Plus or Pro is usually a better fit. You can switch anytime later.",
        "Step \\(step + 1) of \\(totalSteps)": "Step \\(step + 1) of \\(totalSteps)",
        "We will set up your account in a few quick steps so you can start right away.": "We will set up your account in a few quick steps so you can start right away.",
        "Rooms & traps": "Rooms & traps",
        "Inspection rhythm": "Inspection rhythm",
        "Your login": "Your login",
        "At least 6 characters.": "At least 6 characters.",
        "This name will be shown on your profile.": "This name will be shown on your profile.",
        "How many clients do you currently manage?": "How many clients do you currently manage?",
        "Tip: Plus or Pro is usually better for multiple clients.": "Tip: Plus or Pro is usually better for multiple clients.",
        "Quickly review your details and create your account.": "Quickly review your details and create your account.",
        "Source": "Source",
        "Tap + to get started": "Tap + to get started",
        "Limit reached": "Limiet bereikt",
        "OK": "OK",
        "No rooms in filter": "No rooms in filter",
        "Choose another client or create a room": "Choose another client or create a room",
        "Search rooms": "Search rooms",
        "Select client for new room": "Select client for new room",
        "Payment": "Payment",
        "Rooms / Floors": "Rooms / Floors",
        "Export as Excel": "Export as Excel",
        "Edit": "Edit",
        "Company name *": "Company name *",
        "Required fields": "Required fields",
        "Contact person": "Contact person",
        "Payment method": "Payment method",
        "Notes...": "Notes...",
        "Edit client": "Edit client",
        "Save failed": "Save failed",
        "Unknown error.": "Unknown error.",
        "Name and address are required.": "Name and address are required.",
        "Start route": "Start route",
        "Could not save client": "Could not save client",
        "Address *": "Address *",
        "Room name": "Room name",
        "e.g. ground floor · storage · basement · upper floor": "bijv. begane grond · opslag · kelder · bovenverdieping",
        "Number": "Number",
        "Due date": "Due date",
        "Status": "Status",
        "Position": "Position",
        "traps": "traps",
        "Move traps": "Move traps",
        "Auto arrange": "Auto arrange",
        "No traps yet": "No traps yet",
        "Add trap": "Add trap",
        "Sort": "Sort",
        "Done": "Done",
        "Room area for trap positions": "Room area for trap positions",
        "Installed": "Installed",
        "Inspection interval": "Inspection interval",
        "Next inspection": "Next inspection",
        "Details": "Details",
        "Pest trend": "Pest trend",
        "Add inspection": "Add inspection",
        "No inspections yet": "No inspections yet",
        "Inspection history": "Inspection history",
        "Temperature": "Temperature",
        "Humidity": "Humidity",
        "Not enough data for trend yet.": "Not enough data for trend yet.",
        "No change since last inspection.": "No change since last inspection.",
        "since last inspection.": "since last inspection.",
        "Filter": "Filter",
        "At least 2 inspections with this metric are required to show a trend.": "At least 2 inspections with this metric are required to show a trend.",
        "Current": "Current",
        "Average": "Average",
        "Empty": "Empty",
        "pests": "pests",
        "Trap number (e.g. 1031-1)": "Trap number (e.g. 1031-1)",
        "The trap starts centered in the room area. You can adjust it later.": "The trap starts centered in the room area. You can adjust it later.",
        "New trap": "New trap",
        "Inspection saved.": "Inspection saved.",
        "Share report": "Share report",
        "Result": "Result",
        "Total": "Total",
        "Date & time": "Date & time",
        "Notes, observations...": "Notes, observations...",
        "Add photos": "Add photos",
        "Maximum \\(maxPhotosPerInspection) photos per inspection (\\(min(existingPhotoCount + selectedPhotoData.count, maxPhotosPerInspection))/\\(maxPhotosPerInspection)).": "Maximum \\(maxPhotosPerInspection) photos per inspection (\\(min(existingPhotoCount + selectedPhotoData.count, maxPhotosPerInspection))/\\(maxPhotosPerInspection)).",
        "Edit inspection": "Edit inspection",
        "Local photo save failed. Inspection was saved without new photos.": "Local photo save failed. Inspection was saved without new photos.",
        "Photos could not be loaded. Inspection was saved without new photos.": "Photos could not be loaded. Inspection was saved without new photos.",
        "PDF report was created automatically.": "PDF report was created automatically.",
        "Inspection saved. Report could not be created.": "Inspection saved. Report could not be created."
    
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
                .animation(.easeInOut(duration: 0.2), value: focused)

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
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(focused ? IPMColors.green.opacity(0.5) : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.2), value: focused)
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
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.24, dampingFraction: 0.82), value: configuration.isPressed)
    }
}

private struct IPMFlowEntranceModifier: ViewModifier {
    let delay: Double
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            .onAppear {
                guard !isVisible else { return }
                withAnimation(.spring(response: 0.46, dampingFraction: 0.86).delay(delay)) {
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
}

extension View {
    func ipmFlowEntrance(delay: Double = 0) -> some View {
        modifier(IPMFlowEntranceModifier(delay: delay))
    }
}
