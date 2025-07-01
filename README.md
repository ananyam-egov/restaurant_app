# 🍽️ Restaurant App (Offline Flutter App)

This is a simple offline Restaurant Management App built with **Flutter**, using **BLoC** for state management and **SQLite** for local data persistence. Users can register/login, book tables, place orders from a menu, and view order history—all without internet!

---

## 🚀 Problem Statement

Develop an offline-first restaurant app where:
- Users can register and log in.
- Tables can be booked and unbooked.
- Menu items can be browsed and added to an order.
- Orders can be placed and marked complete.
- Users can view current and past orders (order history).

---

## 🧠 Approach & Design

- **Flutter**: Core UI framework.
- **BLoC**: For handling state (auth, table booking).
- **SQLite**: For all local data storage using `sqflite`.
- **Theme**: Custom design with forest green, tangerine orange, and mint green accents.
- **Modular** structure with clear separation of:
  - Pages
  - Models
  - Blocs/Cubits
  - Database helpers
  - Repositories

---

## 📦 Features

- 🔐 **Login / Registration** with form validation
- 📋 **Table Booking** with real-time UI feedback
- 🍛 **Menu Browsing** and item selection
- 🛒 **Order Placement** with quantity control
- ✅ **Order Completion** with table release
- 🕑 **Order History** view (past and active)
- 📦 **Works Fully Offline** with SQLite

---

## 🛠️ Setup & Run Instructions

1. **Clone the repo**  
   ```bash
   git clone https://github.com/ananyam-egov/restaurant_app.git
   cd restaurant_app

2. **Get dependencies**
   ```bash
   flutter pub get

3. **Run the app**
   ```bash
   flutter run

📱 Make sure you have an emulator running or a physical device connected.   