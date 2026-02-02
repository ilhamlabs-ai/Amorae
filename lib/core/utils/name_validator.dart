/// Utility for validating and sanitizing companion names
class NameValidator {
  /// Minimum length for companion names
  static const int minLength = 2;
  
  /// Maximum length for companion names
  static const int maxLength = 20;
  
  /// Allowed characters pattern (letters, spaces, hyphens, apostrophes)
  static final RegExp _allowedPattern = RegExp(r"^[a-zA-Z\s\-']+$");
  
  /// Validate a companion name
  /// Returns null if valid, error message if invalid
  static String? validate(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Name cannot be empty';
    }
    
    final trimmed = name.trim();
    
    if (trimmed.length < minLength) {
      return 'Name must be at least $minLength characters';
    }
    
    if (trimmed.length > maxLength) {
      return 'Name must be at most $maxLength characters';
    }
    
    if (!_allowedPattern.hasMatch(trimmed)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null; // Valid
  }
  
  /// Sanitize a name - trim whitespace and capitalize first letter
  static String sanitize(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return trimmed;
    
    // Capitalize first letter of each word
    return trimmed.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
  
  /// Validate and sanitize - returns sanitized name or null if invalid
  static String? validateAndSanitize(String? name) {
    if (validate(name) != null) return null;
    return sanitize(name!);
  }
  
  /// Get default name for persona type
  static String getDefaultName(String personaType) {
    switch (personaType) {
      case 'girlfriend':
        return 'Luna';
      case 'boyfriend':
        return 'Jack';
      case 'friend':
        return 'Alex';
      default:
        return 'Amorae';
    }
  }
  
  /// Check if persona type supports custom names
  static bool supportsCustomName(String? personaType) {
    return ['girlfriend', 'boyfriend', 'friend'].contains(personaType);
  }
}
