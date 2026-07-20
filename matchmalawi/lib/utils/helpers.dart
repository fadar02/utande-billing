
class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
    if (!regex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.isEmpty) return 'Name is required';
    if (value.length < 2) return 'Name must be at least 2 characters';
    if (value.length > 50) return 'Name must be less than 50 characters';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final cleaned = value.replaceAll(RegExp(r'[\s\-+]'), '');
    if (cleaned.length < 9) return 'Enter a valid phone number';
    return null;
  }

  static String? age(String? value) {
    if (value == null || value.isEmpty) return 'Age is required';
    final age = int.tryParse(value);
    if (age == null) return 'Enter a valid age';
    if (age < 18) return 'You must be at least 18';
    if (age > 100) return 'Enter a valid age';
    return null;
  }

  static String? bio(String? value) {
    if (value != null && value.length > 500) return 'Bio must be under 500 characters';
    return null;
  }

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.isEmpty) return '$fieldName is required';
    return null;
  }
}

class Formatters {
  static String formatPhoneNumber(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-+]'), '');
    if (cleaned.startsWith('265')) {
      return '+265 ${cleaned.substring(3, 6)} ${cleaned.substring(6)}';
    }
    return '+265 $phone';
  }

  static String formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) return '${duration.inDays}d ago';
    if (duration.inHours > 0) return '${duration.inHours}h ago';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m ago';
    return 'Just now';
  }

  static String formatPrice(int price) {
    return 'MWK ${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }
}

class MalawiDistance {
  static String getDistanceText(double km) {
    if (km < 1) return 'Less than 1 km away';
    if (km < 5) return '${km.toStringAsFixed(1)} km away';
    if (km < 50) return '${km.round()} km away';
    return 'Far away';
  }

  static String getRelativeLocation(String district, String? city) {
    if (city != null && city.isNotEmpty) return '$city, $district';
    return district;
  }
}
