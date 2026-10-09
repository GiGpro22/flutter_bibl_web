import '../models/app_user.dart';

bool canManageBooks(AppUser? user) {
  if (user == null) return false;
  return user.isAdmin || user.isLibrarian;
}

bool canHardDelete(AppUser? user) {
  if (user == null) return false;
  return user.isAdmin;
}

bool canRestore(AppUser? user) {
  if (user == null) return false;
  return user.isAdmin;
}

bool canManageUsers(AppUser? user) {
  if (user == null) return false;
  return user.isAdmin;
}

bool canViewMyLoans(AppUser? user) {
  if (user == null) return false;
  return user.isReader;
}

// Эксклюзивный экран библиотекаря (недоступен читателю и админу)
bool canManageLoans(AppUser? user) {
  if (user == null) return false;
  return user.isLibrarian;
}