# Remedios

<div align="center">

*A persistent medication reminder application designed to ensure users never miss a dose*
</div>

## Overview

**Remedios** is an iOS application developed to solve a common problem: forgetting to take medications despite receiving notifications. Unlike standard reminder apps, Remedios uses an persistent notification system that continues to alert users until they take action, ensuring better medication adherence and ultimately improving health outcomes.

The app was developed using xtool, allowing for iOS development directly from Arch Linux without requiring a macOS environment. This project showcases how cross-platform development tools can break traditional platform barriers while delivering a native experience.

## Screenshots

<div align="center">
<img src="https://i.imgur.com/jq0dldI.png" alt="Home" width="200"/>
<img src="https://i.imgur.com/4QD1TqS.png" alt="History" width="200"/>
<img src="https://i.imgur.com/MZqokYR.png" alt="Name" width="200"/>
<img src="https://i.imgur.com/aZoCrsA.png" alt="Type" width="200"/>
<img src="https://i.imgur.com/Yv2EPiY.png" alt="Time" width="200"/>
<img src="https://i.imgur.com/btNPP5Q.png" alt="Revision" width="200"/>
</div>

## Key Features

### Comprehensive Medication Management
- Add medications with detailed information
- Support for multiple medication types (pills, capsules, liquid, topical, etc.)
- Flexible scheduling options:
  * Daily doses
  * Specific days of the week
  * Interval-based dosing
  * Cycle-based treatments (active/rest periods)
  * Sporadic use medications

### Persistent Notification System
- Progressive notification intensity
- Continuous vibration (30 vibrations at 2-second intervals)
- Three response options:
  * "Taken" - Records medication as taken
  * "Postpone" - Reschedules a reminder in 5 minutes with increased persistence
  * "Skip" - Records medication as skipped for tracking purposes

### Adherence Tracking
- Detailed history of all medication events
- Statistical analysis of adherence rates
- Visual representation of taken, postponed, and skipped medications
- Filterable history by time period and medication

### User-Friendly Interface
- Clean, gradient-based UI design
- Quick access to medication details
- Intuitive medication addition workflow

## Technologies

The application was developed using modern iOS development practices focused on reliability and user experience:

- **Swift**: Apple's programming language
- **SwiftUI**: Declarative UI framework
- **xtool**: Cross-platform iOS development on Linux
- **MVVM Architecture**: Clear separation of concerns
- **Combine**: Reactive programming framework
- **UserNotifications**: Notification management
- **Swift Concurrency**: Task-based asynchronous programming
- **MainActor**: Thread-safe state management

## Architecture

The project follows the MVVM (Model-View-ViewModel) architecture with clear separation of responsibilities:

```
└── Sources
    └── Remedios
        ├── Models          # Data structures
        │   ├── ConfiguracaoApp.swift  
        │   ├── HistoricoMedicacao.swift
        │   └── Medicamento.swift
        ├── Services        # Business logic and data persistence
        │   ├── NotificacaoService.swift
        │   └── PersistenciaService.swift
        ├── ViewModels      # UI state and logic controllers
        │   ├── MedicamentoViewModel.swift
        │   ├── HistoricoViewModel.swift
        │   └── NotificacaoViewModel.swift
        ├── Views           # User interface components
        │   ├── Configuracao     # Medication setup
        │   ├── Historico        # History tracking
        │   ├── Notificacoes     # Notification handling
        │   └── Principal        # Main app screens
        ├── Utilities       # Helper functions and extensions
        └── NotificationManager.swift  # Core notification engine
```

## Unique Technical Aspects

- **Persistent Notification System**: A custom implementation that provides continuous feedback until user action
- **Cross-Platform Development**: iOS app developed entirely on Linux using xtool
- **Thread-Safe Notification Handling**: Use of Swift Concurrency and MainActor for reliable notification processing
- **UserDefaults-Based Persistence**: Lightweight data storage for medication records and history

## How to Run the Project

### Prerequisites
- [xtool](https://github.com/xtool-org/xtool) installed on your system (Linux, macOS, or Windows)
- iOS device for testing (or access to a simulator)

### Setup Steps
1. Clone this repository
   ```
   git clone https://github.com/guicarneiro11/Remedios.git
   cd Remedios
   ```

2. Edit the project
   ```
   vscode + swift plugin
   ```

3. Build and run the project using xtool
   ```
   xtool dev
   ```

## Contact

For questions, suggestions, or collaborations, contact:

- Email: guicarneiro.dev@gmail.com
- GitHub: [github.com/guicarneiro11](https://github.com/guicarneiro11)

<div align="center">
<p>Made using xtool for iOS development on Linux</p>
</div>
