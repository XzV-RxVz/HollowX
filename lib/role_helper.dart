// role_helper.dart
// SxC ExecX - v13 Gen 2 (UPDATED ROLES - NO TRIAL)
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

String _normalize(String role) {
  return role.toLowerCase().replaceAll('_', ' ').replaceAll(' ', '_');
}

/// Mendapatkan level/tingkatan dari sebuah role (SEMAKIN BESAR SEMAKIN TINGGI)
int roleLevel(String role) {
  switch (_normalize(role)) {
    case 'developer': return 10;
    case 'executive': return 9;
    case 'xfounder': return 8;
    case 'moderator': return 7;
    case 'owner': return 5;
    case 'xvip': return 4;
    case 'reseller': return 3;
    case 'member': return 2;
    default: return 0;
  }
}

/// Label role untuk UI (huruf besar semua)
String roleLabel(String role) {
  switch (_normalize(role)) {
    case 'developer': return 'DEVELOPER';
    case 'executive': return 'EXECUTIVE';
    case 'xfounder': return 'XFOUNDER';
    case 'moderator': return 'MODERATOR';
    case 'owner': return 'OWNER';
    case 'xvip': return 'XVIP';
    case 'reseller': return 'RESELLER';
    case 'member': return 'MEMBER';
    default: return role.toUpperCase();
  }
}

/// Role yang dapat dibuat oleh currentRole
List<String> creatableRoles(String currentRole) {
  final current = _normalize(currentRole);
  
  switch (current) {
    case 'developer':
      // Developer bisa membuat SEMUA role termasuk developer sendiri
      return ['developer', 'executive', 'xfounder', 'moderator', 'owner', 'xvip', 'reseller', 'member'];
    
    case 'executive':
      return ['xfounder', 'moderator', 'owner', 'xvip', 'reseller', 'member'];
    
    case 'xfounder':
      return ['moderator', 'owner', 'xvip', 'reseller', 'member'];
    
    case 'moderator':
      return ['owner', 'xvip', 'reseller', 'member'];
    
    case 'owner':
      return ['owner', 'xvip', 'reseller', 'member'];
    
    case 'xvip':
      return ['reseller', 'member'];
    
    case 'reseller':
      return ['member'];
    
    default:
      return [];
  }
}

/// Cek apakah currentRole dapat membuat targetRole
bool canCreateRole(String currentRole, String targetRole) {
  final targetNorm = _normalize(targetRole);
  return creatableRoles(currentRole).contains(targetNorm);
}

/// Cek apakah currentRole dapat menghapus targetRole
bool canDeleteUser(String currentRole, String targetRole) {
  final currentLvl = roleLevel(currentRole);
  final targetLvl = roleLevel(targetRole);
  final currentNorm = _normalize(currentRole);
  final targetNorm = _normalize(targetRole);
  
  // Developer bisa hapus semua role termasuk developer lain
  if (currentNorm == 'developer') {
    return true;
  }
  
  // Tidak bisa hapus role yang levelnya sama atau lebih tinggi
  return targetLvl < currentLvl;
}

/// Cek apakah currentRole dapat mengedit (extend durasi) targetRole
bool canEditUser(String currentRole, String targetRole) {
  return canDeleteUser(currentRole, targetRole);
}

/// Maksimal hari yang dapat diberikan oleh currentRole
int maxDays(String currentRole) {
  switch (_normalize(currentRole)) {
    case 'developer': return 9999;
    case 'executive': return 9999;
    case 'xfounder': return 9999;
    case 'moderator': return 9999;
    case 'owner': return 9999;
    case 'xvip': return 9999;
    case 'reseller': return 9999;
    default: return 0;
  }
}

/// Daftar semua role (untuk filter dropdown)
List<String> getAllRoles() {
  return ['developer', 'executive', 'xfounder', 'moderator', 'owner', 'xvip', 'reseller', 'member'];
}

/// Mendapatkan role yang lebih tinggi dari role tertentu
List<String> getHigherRoles(String role) {
  final currentLvl = roleLevel(role);
  return getAllRoles().where((r) => roleLevel(r) > currentLvl).toList();
}

/// Mendapatkan role yang lebih rendah dari role tertentu
List<String> getLowerRoles(String role) {
  final currentLvl = roleLevel(role);
  return getAllRoles().where((r) => roleLevel(r) < currentLvl).toList();
}

/// Cek apakah role valid
bool isValidRole(String role) {
  return getAllRoles().contains(_normalize(role));
}

/// Warna role untuk UI
Color getRoleColor(String role) {
  switch (_normalize(role)) {
    case 'developer': return const Color(0xFF9C27B0);      // Ungu
    case 'executive': return const Color(0xFF6A1B9A);   // Deep Purple (ganti dari pink)
    case 'xfounder': return const Color(0xFF00BCD4);      // Cyan
    case 'moderator': return const Color(0xFFFF9800);  // Orange
    case 'owner': return const Color(0xFFF44336);         // Red
    case 'xvip': return const Color(0xFF673AB7);          // Deep Purple
    case 'reseller': return const Color(0xFFFF6B35);      // Orange Red
    case 'member': return const Color(0xFF4CAF50);        // Green
    default: return const Color(0xFF9E9E9E);
  }
}

/// Ikon role untuk UI (Premium Icons)
IconData getRoleIcon(String role) {
  switch (_normalize(role)) {
    case 'developer': return Icons.code_rounded;                      // Code
    case 'executive': return Icons.auto_awesome_rounded;           // Auto awesome (bintang berkilau)
    case 'xfounder': return Icons.verified_rounded;                  // Verified (centang)
    case 'moderator': return Icons.volunteer_activism_rounded;    // Volunteer activism
    case 'owner': return Icons.military_tech_rounded;                // Military tech (medali)

    case 'xvip': return Icons.diamond_rounded;                       // Diamond (berlian)
    case 'reseller': return Icons.shopping_bag_rounded;              // Shopping bag
    default: return Icons.person_rounded;                            // Person
  }
}

/// Deskripsi role
String getRoleDescription(String role) {
  switch (_normalize(role)) {
    case 'developer': return 'Developer - Akses penuh ke semua fitur';
    case 'executive': return 'Executive - Bisa membuat Xfounder ke bawah';
    case 'xfounder': return 'Xfounder - Bisa membuat Moderator ke bawah';
    case 'moderator': return 'Moderator - Bisa membuat Owner ke bawah';
    case 'owner': return 'Owner - Bisa membuat XVIP ke bawah';
    case 'xvip': return 'XVIP - Bisa membuat Reseller ke bawah';
    case 'reseller': return 'Reseller - Bisa membuat Member';
    case 'member': return 'Member - Tidak bisa membuat akun';
    default: return 'Role tidak dikenal';
  }
}