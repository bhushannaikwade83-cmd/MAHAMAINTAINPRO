/// Comprehensive keyword mapping for all services
/// Used for intelligent search matching
const Map<String, List<String>> SERVICE_KEYWORDS = {
  // Cleaning
  'Cleaning': [
    'cleaning', 'clean', 'deep', 'carpet', 'professional', 'house', 'general',
    'sweep', 'mop', 'dust', 'sanitize', 'hygiene', 'wash', 'scrub'
  ],

  // Salon & Spa
  'Women\'s Salon & Spa': [
    'salon', 'spa', 'hair', 'cut', 'styling', 'beauty', 'women', 'facial',
    'massage', 'pedicure', 'manicure', 'grooming', 'dtan', 'glow'
  ],
  'Men\'s Salon & Massage': [
    'salon', 'barber', 'haircut', 'massage', 'men', 'grooming', 'shave',
    'beard', 'spa', 'relaxation', 'therapy'
  ],

  // Painting
  'Home Painting': [
    'painting', 'paint', 'wall', 'interior', 'exterior', 'color', 'wall painting',
    'home', 'house', 'renovation', 'interior painting', 'enamel', 'duco'
  ],

  // AC & Appliance
  'AC & Appliance Repair': [
    'ac', 'air conditioner', 'appliance', 'repair', 'cooling', 'air', 'fridge',
    'refrigerator', 'washing machine', 'microwave', 'heating', 'servicing',
    'maintenance', 'fix'
  ],

  // Electrician, Plumber & Carpenter
  'Electrician, Plumber & Carpenter': [
    'electrician', 'plumber', 'carpenter', 'electrical', 'plumbing', 'wiring',
    'pipe', 'leakage', 'tap', 'mixer', 'fixture', 'switch', 'socket', 'light',
    'fan', 'door', 'lock', 'wood', 'cabinet', 'woodwork', 'drilling', 'mcb',
    'power', 'water', 'emergency', 'repair', 'fix', 'gas', 'stove'
  ],

  // Vehicle Care
  'Vehicle Care': [
    'vehicle', 'car', 'wash', 'cleaning', 'auto', 'bike', 'motorcycle',
    'detailing', 'polish', 'maintenance', 'service', 'care'
  ],

  // Food & Catering
  'Food & Catering': [
    'food', 'catering', 'delivery', 'cooking', 'meals', 'lunch', 'dinner',
    'breakfast', 'tiffin', 'party', 'event', 'cooking service', 'chef',
    'restaurant', 'cuisine', 'vegetarian'
  ],

  // Health & Care
  'Health & Care': [
    'health', 'medical', 'care', 'wellness', 'fitness', 'gym', 'yoga',
    'therapy', 'doctor', 'clinic', 'medicine', 'healthcare', 'nursing',
    'physiotherapy', 'exercise', 'diet'
  ],

  // Pooja Services
  'Pooja Services': [
    'pooja', 'puja', 'prayer', 'religious', 'ceremony', 'ritual', 'spiritual',
    'temple', 'worship', 'aarti', 'offering', 'priest', 'blessing'
  ],

  // Festival Services
  'Festival Services': [
    'festival', 'decoration', 'party', 'event', 'celebration', 'diwali', 'holi',
    'wedding', 'birthday', 'theme', 'setup', 'lights', 'balloons', 'banner'
  ],

  // Pest Control
  'Pest Control': [
    'pest', 'control', 'insect', 'rodent', 'termite', 'bug', 'mosquito',
    'cockroach', 'rat', 'treatment', 'fumigation', 'spraying', 'prevention'
  ],

  // Smart Society Management
  'Smart Society Management': [
    'management', 'society', 'administration', 'apartment', 'building', 'community',
    'resident', 'maintenance', 'billing', 'fee', 'governance'
  ],

  // Real Estate
  'Real Estate': [
    'real estate', 'property', 'apartment', 'flat', 'house', 'rent', 'sale',
    'buy', 'sell', 'lease', 'housing', 'dwelling', 'commercial', 'residential'
  ],

  // Interior Design
  'Interior Designer': [
    'interior', 'design', 'designer', 'decor', 'furniture', 'home decor',
    'renovation', 'decoration', 'style', 'layout', 'space', 'modular'
  ],

  // Fire Safety
  'Fire Safety': [
    'fire', 'safety', 'protection', 'emergency', 'extinguisher', 'alarm',
    'detection', 'security', 'hazard', 'prevention', 'evacuation'
  ],

  // Water Proofing
  'Water Proofing': [
    'waterproof', 'water proofing', 'leakage', 'damp', 'moisture', 'sealing',
    'coating', 'protection', 'treatment', 'wall', 'roof', 'terrace'
  ],

  // Water Testing
  'Water Testing': [
    'water', 'testing', 'quality', 'purity', 'analysis', 'lab', 'report',
    'contamination', 'safe', 'drinking', 'filter', 'treatment'
  ],

  // Blood Testing
  'Blood Testing': [
    'blood', 'testing', 'test', 'medical', 'health', 'lab', 'analysis',
    'report', 'disease', 'virus', 'screening', 'checkup', 'diagnostic'
  ],

  // Weekly Bazar
  'Weekly Bazar': [
    'bazar', 'grocery', 'shopping', 'market', 'vegetables', 'fruits', 'fresh',
    'organic', 'delivery', 'supplies', 'products', 'daily', 'weekly'
  ],

  // Tours & Travels
  'Tours & Travels': [
    'tours', 'travel', 'vacation', 'trip', 'hotel', 'booking', 'destination',
    'holiday', 'package', 'flight', 'ticket', 'adventure', 'tourism'
  ],

  // Society Features
  'Visitor Gate': [
    'visitor', 'gate', 'register', 'entry', 'access', 'security', 'management',
    'pass', 'approval', 'pending'
  ],
  'Parking Management': [
    'parking', 'vehicle', 'space', 'slot', 'booking', 'guest', 'request',
    'car', 'bike', 'management', 'allocation'
  ],
  'Tenant Management': [
    'tenant', 'tenant info', 'information', 'register', 'apartment', 'flat',
    'resident', 'data', 'details'
  ],
  'Bills & Maintenance': [
    'bill', 'bills', 'maintenance', 'payment', 'fee', 'charges', 'invoice',
    'receipt', 'dues'
  ],
  'Announcements': [
    'announcement', 'notice', 'message', 'update', 'news', 'information',
    'society', 'community', 'alert'
  ],
  'Add Complaint': [
    'complaint', 'issue', 'problem', 'raise', 'grievance', 'feedback',
    'report', 'maintenance', 'repair'
  ],
};

/// Get keywords for a service by name
List<String> getServiceKeywords(String serviceName) {
  return SERVICE_KEYWORDS[serviceName] ?? _extractDefaultKeywords(serviceName);
}

/// Extract default keywords if not found in map
List<String> _extractDefaultKeywords(String title) {
  final titleLower = title.toLowerCase();
  final words = titleLower.split(RegExp(r'[\s&\-]+'));
  return words.where((w) => w.isNotEmpty).toList();
}
