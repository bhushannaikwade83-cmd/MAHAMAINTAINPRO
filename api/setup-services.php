<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$servername = "localhost";
$db_username = "digitrix_maha_user";
$db_password = "maha_user@70";
$database = "digitrix_maha_maintain_pro";

$conn = new mysqli($servername, $db_username, $db_password, $database);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit();
}

try {
    // Create service_categories table
    $createCategoriesTable = "CREATE TABLE IF NOT EXISTS service_categories (
        id INT PRIMARY KEY AUTO_INCREMENT,
        name VARCHAR(255) NOT NULL UNIQUE,
        emoji VARCHAR(10),
        color VARCHAR(20),
        description TEXT,
        is_active TINYINT(1) DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )";

    if (!$conn->query($createCategoriesTable)) {
        throw new Exception("Error creating categories table: " . $conn->error);
    }

    // Create services table
    $createServicesTable = "CREATE TABLE IF NOT EXISTS services (
        id INT PRIMARY KEY AUTO_INCREMENT,
        category_id INT NOT NULL,
        name VARCHAR(255) NOT NULL,
        emoji VARCHAR(10),
        price INT DEFAULT 0,
        duration VARCHAR(50),
        rating DECIMAL(3,2),
        notes TEXT,
        is_active TINYINT(1) DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES service_categories(id) ON DELETE CASCADE
    )";

    if (!$conn->query($createServicesTable)) {
        throw new Exception("Error creating services table: " . $conn->error);
    }

    // Clear existing data
    $conn->query("DELETE FROM services");
    $conn->query("DELETE FROM service_categories");
    $conn->query("ALTER TABLE service_categories AUTO_INCREMENT = 1");
    $conn->query("ALTER TABLE services AUTO_INCREMENT = 1");

    // Categories data with emoji and color
    $categories = [
        ['Insta Help', '⚡', '#FFE5E5', 'Quick 30-60 min fixes for everyday home problems'],
        ['Women\'s Salon & Spa', '💇‍♀️', '#FFF0E5', 'Waxing, facials, hair, makeup & spa at home'],
        ['Men\'s Salon & Massage', '💆‍♂️', '#F0F5FF', 'Haircut, grooming, massage & spa for men'],
        ['Cleaning', '🧹', '#E5F5E5', 'Deep clean, kitchen, bathroom, sofa & tank cleaning'],
        ['Home Painting', '🎨', '#FFF5E5', 'Full home, exterior, texture & waterproof painting'],
        ['AC & Appliance Repair', '❄️', '#E5F5FF', 'AC, fridge, washing machine, geyser & more'],
        ['Electrician, Plumber & Carpenter', '🔧', '#FFF5E5', 'Wiring, plumbing, carpentry & fittings'],
        ['Vehicle Care', '🚗', '#FFE5F5', 'Car & bike wash, service, repair & detailing'],
        ['Food & Catering', '🍳', '#F5E5FF', 'Home chef, event catering & bulk meal orders'],
        ['Health & Care', '🏥', '#E5FFE5', 'Doctor consultation, fitness & wellness services'],
        ['Pooja Services', '🙏', '#FFFFE5', 'Puja ceremonies and religious services'],
        ['Festival Services', '🎉', '#FFE5E5', 'Festival decorations and celebration services'],
        ['Pest Control', '🐜', '#FFF5E5', 'General pest control and treatment'],
        ['Smart Society Management', '🏢', '#E5F5FF', 'Society management and services'],
        ['Real Estate', '🏠', '#FFE5F5', 'Property services and assistance'],
        ['Interior Designer', '🛋️', '#F5E5FF', 'Interior design and home decor'],
        ['Hologram Services', '🔮', '#E5FFE5', 'Holographic display and projection services'],
        ['Fire Safety', '🧯', '#FFF0E0', 'Fire safety equipment and services'],
        ['Water Proofing', '💧', '#E0F7FA', 'Waterproofing and leak protection'],
        ['Water Testing', '🧪', '#E0F2FE', 'Water quality testing services'],
        ['Blood Testing', '🩸', '#FFE0E0', 'Blood testing and lab services'],
        ['Weekly Bazar', '🛒', '#E8F5E9', 'Weekly grocery and shopping service'],
        ['Tours & Travels', '✈️', '#E5FFE5', 'Travel packages and tour services'],
    ];

    $categoryIds = [];
    foreach ($categories as $cat) {
        $stmt = $conn->prepare("INSERT INTO service_categories (name, emoji, color, description) VALUES (?, ?, ?, ?)");
        $stmt->bind_param("ssss", $cat[0], $cat[1], $cat[2], $cat[3]);
        if (!$stmt->execute()) {
            throw new Exception("Error inserting category: " . $stmt->error);
        }
        $categoryIds[$cat[0]] = $conn->insert_id;
        $stmt->close();
    }

    // Services data with pricing
    $services = [
        // Insta Help
        ['Insta Help', 'Pipe Leakage Emergency', '⚡', 449, '30-45 min', 4.9, 'Quick emergency repair'],
        ['Insta Help', 'Tap / Mixer Repair (Urgent)', '', 299, '30-45 min', 4.8, 'Urgent repair'],
        ['Insta Help', 'Fan / Light Fitting (Urgent)', '', 299, '30 min', 4.8, 'Fixture installation'],
        ['Insta Help', 'Door Lock Repair (Emergency)', '', 499, '45 min', 4.7, 'Lock repair'],
        ['Insta Help', 'Electrical Short / Trip', '', 299, '45 min', 4.8, 'Electrical fix'],
        ['Insta Help', 'Gas Stove Repair (Emergency)', '', 399, '45 min', 4.7, 'Stove repair'],
        ['Insta Help', 'Drainage / Clog Clearance', '', 499, '45 min', 4.8, 'Drain cleaning'],
        ['Insta Help', 'Water Heater Not Working', '', 449, '45 min', 4.7, 'Heater repair'],
        ['Insta Help', 'MCB / Power Tripping (Urgent)', '', 349, '30 min', 4.8, 'Power fix'],

        // Women's Salon & Spa
        ['Women\'s Salon & Spa', 'Waxing', '', 0, '', 0, 'Full body/half/arms/legs/underarms'],
        ['Women\'s Salon & Spa', 'Threading', '', 0, '', 0, 'Eyebrow, upper lip, face'],
        ['Women\'s Salon & Spa', 'Facial', '', 0, '', 0, 'Fruit, gold, diamond, Hydrafacial'],
        ['Women\'s Salon & Spa', 'Cleanup', '', 0, '', 0, 'De-tan, bleach'],
        ['Women\'s Salon & Spa', 'Manicure & Pedicure', '', 0, '', 0, 'Classic, spa, nail art/extensions'],
        ['Women\'s Salon & Spa', 'Hair cut & styling', '', 0, '', 0, 'Professional styling services'],
        ['Women\'s Salon & Spa', 'Hair spa/treatment', '', 0, '', 0, 'Keratin, smoothening, coloring'],
        ['Women\'s Salon & Spa', 'Bridal & party makeup', '', 0, '', 0, 'Incl. saree draping'],
        ['Women\'s Salon & Spa', 'Body & head massage (women)', '', 0, '', 0, 'Relaxation therapy'],
        ['Women\'s Salon & Spa', 'Laser hair reduction', '', 0, '', 0, 'Permanent hair removal'],
        ['Women\'s Salon & Spa', 'Skin/hair consultation', '', 0, '', 0, 'Dermal/expert video consult'],

        // Men's Salon & Massage
        ['Men\'s Salon & Massage', 'Haircut & styling', '', 0, '', 0, 'Professional haircut'],
        ['Men\'s Salon & Massage', 'Beard trim & shave', '', 0, '', 0, 'Grooming service'],
        ['Men\'s Salon & Massage', 'Hair coloring (men)', '', 0, '', 0, 'Hair dye service'],
        ['Men\'s Salon & Massage', 'Facial & cleanup (men)', '', 0, '', 0, 'Men\'s skincare'],
        ['Men\'s Salon & Massage', 'Body massage', '', 0, '', 0, 'Swedish, deep tissue, Ayurvedic, Thai'],
        ['Men\'s Salon & Massage', 'Head massage', '', 0, '', 0, 'Relaxation therapy'],
        ['Men\'s Salon & Massage', 'Foot reflexology', '', 0, '', 0, 'Foot therapy'],
        ['Men\'s Salon & Massage', 'Manicure/pedicure (men)', '', 0, '', 0, 'Nail care'],
        ['Men\'s Salon & Massage', 'Grooming package', '', 0, '', 0, 'Combo of above'],

        // Cleaning
        ['Cleaning', 'Full home deep cleaning', '', 0, '', 0, 'Comprehensive home cleaning'],
        ['Cleaning', 'Kitchen deep cleaning', '', 0, '', 0, 'Kitchen cleaning service'],
        ['Cleaning', 'Bathroom cleaning', '', 0, '', 0, 'One-time & weekly subscription'],
        ['Cleaning', 'Sofa/carpet/mattress cleaning', '', 0, '', 0, 'Furniture cleaning'],
        ['Cleaning', 'Water tank cleaning', '', 0, '', 0, 'Tank maintenance'],
        ['Cleaning', 'Chimney/exhaust cleaning', '', 0, '', 0, 'Ventilation cleaning'],
        ['Cleaning', 'Appliance deep clean', '', 0, '', 0, 'AC, fridge, washing machine (non-repair)'],
        ['Cleaning', 'Glass/window cleaning', '', 0, '', 0, 'Window service'],
        ['Cleaning', 'Move-in/move-out cleaning', '', 0, '', 0, 'Complete relocation cleaning'],
        ['Cleaning', 'Society/common area cleaning', '', 0, '', 0, 'B2B society contracts'],
        ['Cleaning', 'Post-construction cleaning', '', 0, '', 0, 'After renovation cleanup'],

        // Home Painting
        ['Home Painting', 'Full home painting', '', 0, '', 0, 'Complete home painting'],
        ['Home Painting', 'Room/partial wall painting', '', 0, '', 0, 'Single room service'],
        ['Home Painting', 'Exterior/building painting', '', 0, '', 0, 'Outside wall painting'],
        ['Home Painting', 'Texture/POP design painting', '', 0, '', 0, 'Decorative finishes'],
        ['Home Painting', 'Waterproofing', '', 0, '', 0, 'Kitchen, bathroom, terrace'],
        ['Home Painting', 'Wood polish', '', 0, '', 0, 'Wood finishing'],
        ['Home Painting', 'Wallpaper installation', '', 0, '', 0, 'Wallpaper service'],
        ['Home Painting', 'Wall panels/PVC panels', '', 0, '', 0, 'Decor panels'],
        ['Home Painting', 'Metal grill/gate painting', '', 0, '', 0, 'Iron work painting'],
        ['Home Painting', 'Colour consultation', '', 0, '', 0, 'Design advice'],

        // AC & Appliance Repair
        ['AC & Appliance Repair', 'AC service, repair, gas refill', '', 0, '', 0, 'Split & window AC'],
        ['AC & Appliance Repair', 'AC installation/uninstallation', '', 0, '', 0, 'AC setup'],
        ['AC & Appliance Repair', 'Refrigerator repair', '', 0, '', 0, 'Fridge service'],
        ['AC & Appliance Repair', 'Washing machine repair', '', 0, '', 0, 'Washer service'],
        ['AC & Appliance Repair', 'Microwave repair', '', 0, '', 0, 'Microwave service'],
        ['AC & Appliance Repair', 'Water purifier (RO) service/repair', '', 0, '', 0, 'RO maintenance'],
        ['AC & Appliance Repair', 'Geyser repair', '', 0, '', 0, 'Water heater service'],
        ['AC & Appliance Repair', 'Chimney & hob repair', '', 0, '', 0, 'Kitchen appliances'],
        ['AC & Appliance Repair', 'TV repair', '', 0, '', 0, 'Television service'],
        ['AC & Appliance Repair', 'Air cooler repair', '', 0, '', 0, 'Cooler service'],
        ['AC & Appliance Repair', 'Air purifier repair', '', 0, '', 0, 'Air quality device'],
        ['AC & Appliance Repair', 'Gas stove repair', '', 0, '', 0, 'Stove service'],
        ['AC & Appliance Repair', 'Inverter/stabilizer repair', '', 0, '', 0, 'Power backup'],

        // Electrician, Plumber & Carpenter
        ['Electrician, Plumber & Carpenter', 'Wiring & switchboard repair', '', 0, '', 0, 'Electrical wiring'],
        ['Electrician, Plumber & Carpenter', 'Fan/light installation', '', 0, '', 0, 'Fixture installation'],
        ['Electrician, Plumber & Carpenter', 'MCB/inverter fitting', '', 0, '', 0, 'Circuit breaker setup'],
        ['Electrician, Plumber & Carpenter', 'Pipe leak repair', '', 0, '', 0, 'Plumbing fix'],
        ['Electrician, Plumber & Carpenter', 'Bathroom fitting installation', '', 0, '', 0, 'Fixture setup'],
        ['Electrician, Plumber & Carpenter', 'Water tank/motor repair', '', 0, '', 0, 'Water system'],
        ['Electrician, Plumber & Carpenter', 'Drainage clearing', '', 0, '', 0, 'Drain cleaning'],
        ['Electrician, Plumber & Carpenter', 'Furniture repair/assembly', '', 0, '', 0, 'Carpentry work'],
        ['Electrician, Plumber & Carpenter', 'Door/window repair', '', 0, '', 0, 'Door service'],
        ['Electrician, Plumber & Carpenter', 'Lock fitting', '', 0, '', 0, 'Lock installation'],
        ['Electrician, Plumber & Carpenter', 'Modular furniture work', '', 0, '', 0, 'Furniture customization'],

        // Vehicle Care
        ['Vehicle Care', 'Car wash/detailing (doorstep)', '', 0, '', 0, 'On-site washing'],
        ['Vehicle Care', 'Bike wash/servicing', '', 0, '', 0, 'Bike maintenance'],
        ['Vehicle Care', 'General car/bike service', '', 0, '', 0, 'Regular service'],
        ['Vehicle Care', 'Battery jumpstart/replacement', '', 0, '', 0, 'Battery service'],
        ['Vehicle Care', 'Puncture repair', '', 0, '', 0, 'Tire repair'],
        ['Vehicle Care', 'Denting-painting', '', 0, '', 0, 'Body work'],
        ['Vehicle Care', 'Car AC service', '', 0, '', 0, 'Vehicle climate control'],
        ['Vehicle Care', 'Car interior deep cleaning', '', 0, '', 0, 'Interior detailing'],
        ['Vehicle Care', 'Ceramic coating/polishing', '', 0, '', 0, 'Paint protection'],
        ['Vehicle Care', 'PUC/inspection assistance', '', 0, '', 0, 'Inspection help'],
        ['Vehicle Care', 'Roadside assistance/towing tie-up', '', 0, '', 0, 'Emergency help'],

        // Food & Catering
        ['Food & Catering', 'Home chef/tiffin service', '', 0, '', 0, 'Daily meal service'],
        ['Food & Catering', 'Event catering (small/large)', '', 0, '', 0, 'Party catering'],
        ['Food & Catering', 'Live food counters', '', 0, '', 0, 'Event counters'],
        ['Food & Catering', 'Bulk/corporate meal catering', '', 0, '', 0, 'Office meals'],
        ['Food & Catering', 'Festival sweets/prasad order', '', 0, '', 0, 'Festival food'],
        ['Food & Catering', 'Cake & bakery order', '', 0, '', 0, 'Baked goods'],
        ['Food & Catering', 'Bartender/mocktail counter', '', 0, '', 0, 'Beverage service'],
        ['Food & Catering', 'Waiters/service staff on hire', '', 0, '', 0, 'Event staff'],

        // Health & Care
        ['Health & Care', 'Nursing care at home', '', 0, '', 0, 'Healthcare at home'],
        ['Health & Care', 'Elderly care/attendant', '', 0, '', 0, 'Senior care'],
        ['Health & Care', 'Baby care/nanny services', '', 0, '', 0, 'Childcare'],
        ['Health & Care', 'Physiotherapy at home', '', 0, '', 0, 'Therapy sessions'],
        ['Health & Care', 'Post-surgery/diabetic care', '', 0, '', 0, 'Medical care'],
        ['Health & Care', 'Doctor on call', '', 0, '', 0, 'Medical consultation'],
        ['Health & Care', 'Lab sample collection', '', 0, '', 0, 'Blood collection'],
        ['Health & Care', 'Medical equipment rental', '', 0, '', 0, 'Wheelchair, oxygen concentrator, hospital bed'],
        ['Health & Care', 'Vaccination at home', '', 0, '', 0, 'Home vaccination'],
        ['Health & Care', 'Counselling/mental health sessions', '', 0, '', 0, 'Mental health support'],

        // Pooja Services
        ['Pooja Services', 'Pandit booking - Satyanarayn Puja', '', 0, '', 0, 'Religious ceremony'],
        ['Pooja Services', 'Pandit booking - Griha Pravesh', '', 0, '', 0, 'House inauguration'],
        ['Pooja Services', 'Pandit booking - Namkaran/Mundan', '', 0, '', 0, 'Birth ceremonies'],
        ['Pooja Services', 'Pooja samagri kit delivery', '', 0, '', 0, 'Ritual supplies'],
        ['Pooja Services', 'Havan arrangement', '', 0, '', 0, 'Fire ceremony'],
        ['Pooja Services', 'Wedding rituals purohi', '', 0, '', 0, 'Wedding priest'],
        ['Pooja Services', 'Shradh/Pitri Paksha rituals', '', 0, '', 0, 'Ancestor rituals'],
        ['Pooja Services', 'Astrology consultation', '', 0, '', 0, 'Astrological advice'],
        ['Pooja Services', 'Vastu consultation', '', 0, '', 0, 'Vastu guidance'],
        ['Pooja Services', 'Online/virtual pooja', '', 0, '', 0, 'Remote ceremonies'],
        ['Pooja Services', 'Ganpati decoration & setup', '', 0, '', 0, 'Ganesh Chaturthi setup'],

        // Festival Services
        ['Festival Services', 'Diwali home decoration/lighting', '', 0, '', 0, 'Diwali setup'],
        ['Festival Services', 'Navratri/Dandiya event setup', '', 0, '', 0, 'Event arrangement'],
        ['Festival Services', 'Rangoli artist booking', '', 0, '', 0, 'Rangoli design'],
        ['Festival Services', 'Balloon/theme decoration', '', 0, '', 0, 'Party decoration'],
        ['Festival Services', 'Visarjan (immersion) arrangement', '', 0, '', 0, 'Immersion service'],
        ['Festival Services', 'Festival photography/videography', '', 0, '', 0, 'Event coverage'],
        ['Festival Services', 'Festival catering tie-in', '', 0, '', 0, 'Cross-sell with Food & Catering'],

        // Pest Control
        ['Pest Control', 'General pest control', '', 0, '', 0, 'Bug treatment'],
        ['Pest Control', 'Cockroach control', '', 0, '', 0, 'Pest elimination'],
        ['Pest Control', 'Termite control', '', 0, '', 0, 'Termite treatment'],
        ['Pest Control', 'Bed bug treatment', '', 0, '', 0, 'Bed pest removal'],
        ['Pest Control', 'Rodent control', '', 0, '', 0, 'Rodent elimination'],
        ['Pest Control', 'Mosquito fogging', '', 0, '', 0, 'Mosquito control'],
        ['Pest Control', 'Wood borer treatment', '', 0, '', 0, 'Wood pest treatment'],
        ['Pest Control', 'Herbal/eco-friendly pest control', '', 0, '', 0, 'Eco treatment'],
        ['Pest Control', 'AMC - annual pest control contract', '', 0, '', 0, 'Annual contract'],

        // Smart Society Management
        ['Smart Society Management', 'Visitor management', '', 0, '', 0, 'Gate app, pre-approval'],
        ['Smart Society Management', 'Maintenance billing & accounting', '', 0, '', 0, 'Receipts, penalty/interest calc'],
        ['Smart Society Management', 'Complaint/helpdesk management', '', 0, '', 0, 'Issue tracking'],
        ['Smart Society Management', 'Facility/clubhouse booking', '', 0, '', 0, 'Venue reservation'],
        ['Smart Society Management', 'Notice board & communication', '', 0, '', 0, 'Announcements'],
        ['Smart Society Management', 'Security guard management', '', 0, '', 0, 'Shift, patrolling logs'],
        ['Smart Society Management', 'Parking management', '', 0, '', 0, 'Lot management'],
        ['Smart Society Management', 'Vendor & staff management', '', 0, '', 0, 'Staff coordination'],
        ['Smart Society Management', 'Resident society mobile app', '', 0, '', 0, 'App deployment'],
        ['Smart Society Management', 'Property buy/sell assistance', '', 0, '', 0, 'Real estate help'],
        ['Smart Society Management', 'Rental/leasing assistance', '', 0, '', 0, 'Lease services'],
        ['Smart Society Management', 'Property listing', '', 0, '', 0, 'Property ads'],
        ['Smart Society Management', 'Site visit coordination', '', 0, '', 0, 'Site visit setup'],
        ['Smart Society Management', 'Home loan/documentation assistance', '', 0, '', 0, 'Loan help'],
        ['Smart Society Management', 'Property valuation', '', 0, '', 0, 'Valuation service'],
        ['Smart Society Management', 'Rental agreement drafting/registration', '', 0, '', 0, 'Agreement prep'],
        ['Smart Society Management', 'Society NOC/transfer assistance', '', 0, '', 0, 'Transfer help'],

        // Real Estate
        ['Real Estate', 'Property buy/sell assistance', '', 0, '', 0, 'Real estate transaction'],
        ['Real Estate', 'Rental/leasing assistance', '', 0, '', 0, 'Rental services'],
        ['Real Estate', 'Property listing', '', 0, '', 0, 'Property ads'],
        ['Real Estate', 'Site visit coordination', '', 0, '', 0, 'Site visit setup'],
        ['Real Estate', 'Home loan/documentation assistance', '', 0, '', 0, 'Loan documentation'],
        ['Real Estate', 'Property valuation', '', 0, '', 0, 'Valuation service'],
        ['Real Estate', 'Rental agreement drafting/registration', '', 0, '', 0, 'Agreement service'],
        ['Real Estate', 'Society NOC/transfer assistance', '', 0, '', 0, 'Transfer assistance'],

        // Interior Designer
        ['Interior Designer', 'Full home interior design', '', 0, '', 0, 'Complete design'],
        ['Interior Designer', 'Modular kitchen design', '', 0, '', 0, 'Kitchen design'],
        ['Interior Designer', 'Wardrobe design', '', 0, '', 0, 'Closet design'],
        ['Interior Designer', 'False ceiling design', '', 0, '', 0, 'Ceiling service'],
        ['Interior Designer', '3D visualization/space planning', '', 0, '', 0, '3D planning'],
        ['Interior Designer', 'Furniture selection & sourcing', '', 0, '', 0, 'Furniture procurement'],
        ['Interior Designer', 'Turnkey execution', '', 0, '', 0, 'Full execution'],
        ['Interior Designer', 'Office/commercial interior design', '', 0, '', 0, 'Commercial design'],
        ['Interior Designer', 'Renovation consultation', '', 0, '', 0, 'Renovation advice'],

        // Hologram Services
        ['Hologram Services', 'Event hologram display', '', 0, '', 0, 'Holographic projection'],
        ['Hologram Services', '3D holographic projection', '', 0, '', 0, '3D projection'],
        ['Hologram Services', 'Product launch hologram', '', 0, '', 0, 'Product showcase'],
        ['Hologram Services', 'Wedding/tribute hologram', '', 0, '', 0, 'Special event'],
        ['Hologram Services', 'Corporate presentation hologram', '', 0, '', 0, 'Business hologram'],
        ['Hologram Services', 'Hologram fan/kiosk rental', '', 0, '', 0, 'Equipment rental'],

        // Fire Safety
        ['Fire Safety', 'Fire extinguisher supply & installation', '', 0, '', 0, 'ABC/CO2/water type, per society requirement'],
        ['Fire Safety', 'Fire extinguisher AMC', '', 0, '', 0, 'Quarterly refill, inspection, tagging'],
        ['Fire Safety', 'Fire hydrant system installation', '', 0, '', 0, 'Hydrant setup'],
        ['Fire Safety', 'Fire sprinkler system installation', '', 0, '', 0, 'Sprinkler installation'],
        ['Fire Safety', 'Smoke detector & fire alarm installation', '', 0, '', 0, 'Alarm setup'],
        ['Fire Safety', 'Fire hose reel installation & maintenance', '', 0, '', 0, 'Hose installation'],
        ['Fire Safety', 'Emergency lighting & exit signage installation', '', 0, '', 0, 'Safety lighting'],
        ['Fire Safety', 'Fire NOC documentation assistance', '', 0, '', 0, 'Liaison for fire dept. NOC/renewal'],
        ['Fire Safety', 'Fire safety audit & compliance certificate', '', 0, '', 0, 'Annual statutory requirement'],
        ['Fire Safety', 'Fire safety mock drill & staff training', '', 0, '', 0, 'Training session'],

        // Water Proofing
        ['Water Proofing', 'Terrace/roof waterproofing', '', 0, '', 0, 'Roof protection'],
        ['Water Proofing', 'Bathroom waterproofing', '', 0, '', 0, 'Bathroom protection'],
        ['Water Proofing', 'Basement waterproofing', '', 0, '', 0, 'Basement protection'],
        ['Water Proofing', 'External wall waterproofing', '', 0, '', 0, 'Wall protection'],
        ['Water Proofing', 'Wall dampness treatment', '', 0, '', 0, 'Dampness cure'],
        ['Water Proofing', 'Water tank waterproofing', '', 0, '', 0, 'Tank protection'],
        ['Water Proofing', 'Expansion joint treatment', '', 0, '', 0, 'Joint sealing'],
        ['Water Proofing', 'Chemical injection grouting', '', 0, '', 0, 'Leak/crack treatment'],
        ['Water Proofing', 'Waterproofing AMC/warranty service', '', 0, '', 0, 'Annual check-up under warranty period'],

        // Water Testing
        ['Water Testing', 'Water quality testing', '', 0, '', 0, 'Water analysis'],
        ['Water Testing', 'Contamination detection', '', 0, '', 0, 'Quality check'],

        // Blood Testing
        ['Blood Testing', 'Blood test & sampling', '', 0, '', 0, 'Lab test collection'],
        ['Blood Testing', 'Health checkup packages', '', 0, '', 0, 'Wellness packages'],

        // Weekly Bazar
        ['Weekly Bazar', 'Weekly grocery delivery', '', 0, '', 0, 'Grocery shopping'],
        ['Weekly Bazar', 'Bulk produce ordering', '', 0, '', 0, 'Produce orders'],

        // Tours & Travels
        ['Tours & Travels', 'Holiday packages', '', 0, '', 0, 'Travel packages'],
        ['Tours & Travels', 'Corporate trips', '', 0, '', 0, 'Business travel'],
        ['Tours & Travels', 'Visa assistance', '', 0, '', 0, 'Visa services'],
    ];

    foreach ($services as $svc) {
        $categoryName = $svc[0];
        $categoryId = $categoryIds[$categoryName];
        $serviceName = $svc[1];
        $emoji = $svc[2];
        $price = $svc[3];
        $duration = $svc[4];
        $rating = $svc[5];
        $notes = $svc[6];

        $stmt = $conn->prepare("INSERT INTO services (category_id, name, emoji, price, duration, rating, notes) VALUES (?, ?, ?, ?, ?, ?, ?)");
        $stmt->bind_param("isisiss", $categoryId, $serviceName, $emoji, $price, $duration, $rating, $notes);
        if (!$stmt->execute()) {
            throw new Exception("Error inserting service: " . $stmt->error);
        }
        $stmt->close();
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Database setup completed successfully',
        'categories_inserted' => count($categories),
        'services_inserted' => count($services),
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
