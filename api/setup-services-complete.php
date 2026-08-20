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

    // Complete services data with pricing from PriceList_MahaMaintainPro.xlsx
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
        ['Women\'s Salon & Spa', 'Hair Cut & Styling (Women)', '', 599, '45-60 min', 4.9, 'Professional styling'],
        ['Women\'s Salon & Spa', 'Facial (Glow / D-Tan)', '', 899, '60 min', 4.8, 'Facial service'],
        ['Women\'s Salon & Spa', 'Full Body Waxing (Honey)', '', 1099, '60-90 min', 4.7, 'Waxing service'],
        ['Women\'s Salon & Spa', 'Bridal Package (Basic)', '', 5999, 'Half Day', 4.9, 'Bridal service'],
        ['Women\'s Salon & Spa', 'Pedicure & Manicure (Combo)', '', 799, '60 min', 4.8, 'Nail service'],
        ['Women\'s Salon & Spa', 'Head Massage & Spa', '', 699, '60 min', 4.9, 'Massage service'],
        ['Women\'s Salon & Spa', 'Eyebrow Threading & Shaping', '', 99, '20 min', 4.8, 'Threading'],
        ['Women\'s Salon & Spa', 'Hair Colour & Highlights', '', 1999, '2-3 hrs', 4.7, 'Hair coloring'],
        ['Women\'s Salon & Spa', 'Keratin / Smoothening Treatment', '', 3999, '3-4 hrs', 4.8, 'Hair treatment'],
        ['Women\'s Salon & Spa', 'Bleach & Detan (Face)', '', 449, '30 min', 4.7, 'Facial treatment'],
        ['Women\'s Salon & Spa', 'Cleanup', '', 349, '30 min', 4.8, 'Cleanup service'],
        ['Women\'s Salon & Spa', 'Nail Art & Extension', '', 1299, '60-90 min', 4.8, 'Nail art'],
        ['Women\'s Salon & Spa', 'Mehendi / Henna Application', '', 799, '60 min', 4.8, 'Mehendi service'],

        // Men's Salon & Massage
        ['Men\'s Salon & Massage', 'Hair Cut (Men)', '', 249, '30 min', 4.8, 'Haircut service'],
        ['Men\'s Salon & Massage', 'Hair Cut (Kids Under 12)', '', 199, '20 min', 4.8, 'Kids haircut'],
        ['Men\'s Salon & Massage', 'Shave & Beard Styling', '', 199, '20-30 min', 4.8, 'Beard grooming'],
        ['Men\'s Salon & Massage', 'Swedish Massage (60 min)', '', 1299, '60 min', 4.9, 'Swedish massage'],
        ['Men\'s Salon & Massage', 'Hair Colour (Men)', '', 699, '45 min', 4.7, 'Hair coloring'],
        ['Men\'s Salon & Massage', 'Tan & Clean-Up (Men)', '', 499, '45 min', 4.8, 'Tan removal'],
        ['Men\'s Salon & Massage', 'Hair Spa Treatment', '', 799, '45-60 min', 4.8, 'Hair spa'],
        ['Men\'s Salon & Massage', 'Beard Colour & Styling', '', 399, '30 min', 4.7, 'Beard service'],
        ['Men\'s Salon & Massage', 'Head Massage (45 min)', '', 549, '45 min', 4.8, 'Head massage'],
        ['Men\'s Salon & Massage', 'Pedicure & Foot Care (Men)', '', 599, '45 min', 4.7, 'Foot care'],
        ['Men\'s Salon & Massage', 'Dandruff Treatment', '', 499, '30 min', 4.7, 'Dandruff care'],

        // Cleaning
        ['Cleaning', 'Professional Home Deep Clean (1BHK)', '', 3499, '3-4 hrs', 4.9, 'Full home cleaning'],
        ['Cleaning', 'Professional Home Deep Clean (2BHK)', '', 3999, '4-5 hrs', 4.9, 'Full home cleaning'],
        ['Cleaning', 'Professional Home Deep Clean (3BHK)', '', 4499, '5-6 hrs', 4.9, 'Full home cleaning'],
        ['Cleaning', 'Professional Bathroom Deep Clean', '', 599, '1.5-2 hrs', 4.9, 'Bathroom cleaning'],
        ['Cleaning', 'Professional Kitchen Deep Clean', '', 999, '2 hrs', 4.8, 'Kitchen cleaning'],
        ['Cleaning', 'Professional Sofa Cleaning (3-Seater)', '', 899, '2 hrs', 4.8, 'Sofa cleaning'],
        ['Cleaning', 'Professional Carpet / Rug Dry Cleaning', '', 699, '2-3 hrs', 4.8, 'Carpet cleaning'],
        ['Cleaning', 'Professional Water Tank Cleaning (500L)', '', 999, '2 hrs', 4.9, 'Tank cleaning'],
        ['Cleaning', 'Professional Mattress Cleaning & Sanitise', '', 699, '1-2 hrs', 4.8, 'Mattress cleaning'],
        ['Cleaning', 'Professional Office / Commercial Cleaning', '', 3999, '3-5 hrs', 4.7, 'Commercial cleaning'],
        ['Cleaning', 'Professional Post-Construction Cleaning', '', 5499, 'Full Day', 4.7, 'Post construction'],
        ['Cleaning', 'Professional Balcony & Window Cleaning', '', 449, '1 hr', 4.8, 'Window cleaning'],
        ['Cleaning', 'Professional Refrigerator Deep Clean', '', 399, '1 hr', 4.7, 'Fridge cleaning'],
        ['Cleaning', 'Professional Overhead / Sump Tank Cleaning', '', 1999, '3-4 hrs', 4.9, 'Tank cleaning'],

        // Home Painting
        ['Home Painting', 'Wall Painting (Per sq.ft)', '', 18, 'Per sq.ft', 4.6, 'Wall painting'],
        ['Home Painting', 'Full Home Painting (1BHK)', '', 12999, '2-3 days', 4.8, 'Full home'],
        ['Home Painting', 'Full Home Painting (2BHK)', '', 18999, '3-4 days', 4.8, 'Full home'],
        ['Home Painting', 'Full Home Painting (3BHK)', '', 26999, '4-5 days', 4.8, 'Full home'],
        ['Home Painting', 'Waterproofing (Bathroom)', '', 3499, '1 day', 4.8, 'Waterproofing'],
        ['Home Painting', 'Waterproofing (Terrace / Roof)', '', 6999, '1-2 days', 4.9, 'Waterproofing'],
        ['Home Painting', 'Texture / Designer Painting', '', 75, 'Per sq.ft', 4.7, 'Texture painting'],
        ['Home Painting', 'Wood Polish & Varnish', '', 2999, '1-2 days', 4.7, 'Wood polish'],
        ['Home Painting', 'Gate & Grill Painting', '', 1999, '1 day', 4.7, 'Gate painting'],
        ['Home Painting', 'Ceiling Painting Only', '', 4999, '1-2 days', 4.7, 'Ceiling painting'],
        ['Home Painting', 'Enamel / Oil Paint (Wood & Metal)', '', 2999, '1 day', 4.7, 'Enamel painting'],

        // AC & Appliance Repair
        ['AC & Appliance Repair', 'AC Jet Service', '', 599, '1.5-2 hrs', 4.8, 'AC service'],
        ['AC & Appliance Repair', 'AC Gas Refill (R32 / R410)', '', 2499, '1-1.5 hrs', 4.7, 'Gas refill'],
        ['AC & Appliance Repair', 'AC Installation (Split)', '', 1499, '3-4 hrs', 4.9, 'AC installation'],
        ['AC & Appliance Repair', 'AC Installation (Window)', '', 799, '3-4 hrs', 4.9, 'AC installation'],
        ['AC & Appliance Repair', 'AC Uninstallation', '', 499, '1-2 hrs', 4.8, 'AC removal'],
        ['AC & Appliance Repair', 'Washing Machine Repair', '', 499, '1 hr', 4.7, 'Washer repair'],
        ['AC & Appliance Repair', 'Washing Machine Installation', '', 399, '45 min', 4.8, 'Washer installation'],
        ['AC & Appliance Repair', 'Refrigerator / Fridge Service', '', 499, '1 hr', 4.8, 'Fridge repair'],
        ['AC & Appliance Repair', 'Microwave / OTG Repair', '', 399, '45 min', 4.6, 'Microwave repair'],
        ['AC & Appliance Repair', 'Chimney / Exhaust Cleaning', '', 899, '1 hr', 4.7, 'Chimney cleaning'],
        ['AC & Appliance Repair', 'Geyser / Water Heater Repair', '', 499, '1 hr', 4.8, 'Heater repair'],
        ['AC & Appliance Repair', 'TV / LED Repair', '', 599, '1-2 hrs', 4.7, 'TV repair'],
        ['AC & Appliance Repair', 'Air Cooler Service & Repair', '', 399, '1 hr', 4.7, 'Cooler repair'],
        ['AC & Appliance Repair', 'Air Purifier Repair (Non-Ionic)', '', 599, '1 hr', 4.7, 'Air purifier repair'],
        ['AC & Appliance Repair', 'Dishwasher Repair', '', 599, '1-1.5 hrs', 4.7, 'Dishwasher repair'],

        // Electrician, Plumber & Carpenter
        ['Electrician, Plumber & Carpenter', 'Electrician (General Visit)', '', 199, '45 min', 4.8, 'Electrician visit'],
        ['Electrician, Plumber & Carpenter', 'Fan Installation / Repair', '', 299, '30-45 min', 4.8, 'Fan service'],
        ['Electrician, Plumber & Carpenter', 'Light / Fixture Installation', '', 249, '30 min', 4.8, 'Light installation'],
        ['Electrician, Plumber & Carpenter', 'IMCB / DB Box Work', '', 499, '1 hr', 4.7, 'Electrical box'],
        ['Electrician, Plumber & Carpenter', 'Inverter / Battery Installation', '', 799, '1-2 hrs', 4.7, 'Inverter setup'],
        ['Electrician, Plumber & Carpenter', 'Earthing & Wiring Check', '', 499, '1 hr', 4.8, 'Wiring check'],
        ['Electrician, Plumber & Carpenter', 'Plumber (General Visit)', '', 199, '45 min', 4.8, 'Plumber visit'],
        ['Electrician, Plumber & Carpenter', 'Tap / Mixer Replacement', '', 549, '45 min', 4.8, 'Tap replacement'],
        ['Electrician, Plumber & Carpenter', 'Toilet Flush Repair', '', 349, '45-60 min', 4.7, 'Flush repair'],
        ['Electrician, Plumber & Carpenter', 'Drainage Pipe Unclogging', '', 449, '45 min', 4.7, 'Drainage fix'],
        ['Electrician, Plumber & Carpenter', 'Basin / Sink Fitting', '', 599, '1 hr', 4.8, 'Sink installation'],
        ['Electrician, Plumber & Carpenter', 'Carpenter (General Visit)', '', 249, '1 hr', 4.7, 'Carpenter visit'],
        ['Electrician, Plumber & Carpenter', 'Door / Window Repair', '', 449, '1-2 hrs', 4.8, 'Door repair'],
        ['Electrician, Plumber & Carpenter', 'Lock / Handle Replacement', '', 349, '45 min', 4.8, 'Lock replacement'],
        ['Electrician, Plumber & Carpenter', 'Wall Drilling & TV Mounting', '', 399, '45 min', 4.8, 'Wall drilling'],
        ['Electrician, Plumber & Carpenter', 'Lock / Handle Replacement', '', 449, '45 min', 4.8, 'Lock replacement'],
        ['Electrician, Plumber & Carpenter', 'Wooden Shelf / Wardrobe Repair', '', 599, '1-2 hrs', 4.7, 'Wardrobe repair'],

        // Vehicle Care
        ['Vehicle Care', 'Car Wash (Exterior + Interior)', '', 499, '45 min', 4.7, 'Car washing'],
        ['Vehicle Care', 'Car Interior Deep Clean', '', 1499, '2-3 hrs', 4.8, 'Interior cleaning'],
        ['Vehicle Care', 'Bike Wash & Polish', '', 299, '30-45 min', 4.7, 'Bike washing'],
        ['Vehicle Care', 'Car Detailing (Premium)', '', 4999, 'Half Day', 4.9, 'Premium detailing'],
        ['Vehicle Care', 'Car AC Gas Refill', '', 1999, '1-2 hrs', 4.8, 'AC refill'],
        ['Vehicle Care', 'Dent & Paint Touch-up', '', 2499, 'Site Visit', 4.7, 'Paint repair'],
        ['Vehicle Care', 'Tyre Puncture (Home Service)', '', 249, '30 min', 4.8, 'Tire repair'],
        ['Vehicle Care', 'Car Engine Oil Change', '', 899, '1 hr', 4.7, 'Oil change'],
        ['Vehicle Care', 'Bike Engine Oil Change', '', 399, '45 min', 4.7, 'Bike oil change'],
        ['Vehicle Care', 'Battery Jump-start / Replacement', '', 599, '30-45 min', 4.8, 'Battery service'],
        ['Vehicle Care', 'Windshield / Glass Cleaning', '', 249, '30 min', 4.7, 'Glass cleaning'],
        ['Vehicle Care', 'Car Polish & Wax', '', 1299, '2 hrs', 4.8, 'Polishing'],
        ['Vehicle Care', 'Ceramic Coating (Car)', '', 7999, 'Full Day', 4.9, 'Ceramic coating'],

        // Food & Catering
        ['Food & Catering', 'Home Cook (Per Visit)', '', 599, '2-3 hrs', 4.8, 'Home chef'],
        ['Food & Catering', 'Tiffin Service (Monthly)', '', 4499, 'Monthly', 4.7, 'Meal service'],
        ['Food & Catering', 'Party Catering (25 pax)', '', 12499, 'Site Visit', 4.9, 'Catering service'],
        ['Food & Catering', 'Party Catering (50 pax)', '', 21999, 'Site Visit', 4.9, 'Catering service'],
        ['Food & Catering', 'Pooja Prasad Preparation', '', 999, '2-3 hrs', 4.8, 'Prasad prep'],
        ['Food & Catering', 'Birthday Cake & Snacks Setup', '', 1999, '2 hrs', 4.8, 'Party setup'],
        ['Food & Catering', 'Diet / Health Meal Prep', '', 899, '2-3 hrs', 4.7, 'Health meal'],
        ['Food & Catering', 'Daily Maid-Cook (Part-time)', '', 6999, 'Monthly', 4.8, 'Part-time cook'],
        ['Food & Catering', 'Sweets & Farsan Preparation', '', 1299, '3-4 hrs', 4.7, 'Sweets prep'],
        ['Food & Catering', 'Office Lunch Box (Per Day)', '', 199, 'Delivery', 4.6, 'Lunch box'],

        // Health & Care
        ['Health & Care', 'Nurse / Attendant (Day Shift)', '', 1999, '8 hrs', 4.9, 'Nursing care'],
        ['Health & Care', 'Nurse / Attendant (Night Shift)', '', 2499, '10 hrs', 4.9, 'Night care'],
        ['Health & Care', 'Physiotherapy (Home Visit)', '', 899, '45-60 min', 4.9, 'Therapy'],
        ['Health & Care', 'Blood Test (Home Collection)', '', 399, '30 min', 4.8, 'Blood test'],
        ['Health & Care', 'Elder Care (Full Day)', '', 2499, 'Full Day', 4.9, 'Elder care'],
        ['Health & Care', 'Post-Surgery Home Care', '', 2999, '8 hrs', 4.9, 'Post-surgery care'],
        ['Health & Care', 'Yoga / Fitness (Home Session)', '', 699, '60 min', 4.8, 'Yoga session'],
        ['Health & Care', 'Dietician Consultation (Online)', '', 399, '45 min', 4.7, 'Diet consultation'],
        ['Health & Care', 'Doctor Home Visit (GP)', '', 899, '30-45 min', 4.8, 'Doctor visit'],
        ['Health & Care', 'Vaccination at Home', '', 599, '30 min', 4.7, 'Vaccination'],
        ['Health & Care', 'Baby Care / Nanny', '', 1599, '8 hrs', 4.9, 'Baby care'],
        ['Health & Care', 'Wheelchair / Equipment Rental', '', 699, 'Per day', 4.7, 'Equipment rental'],

        // Pooja Services
        ['Pooja Services', 'Ganesh Pooja Setup & Pandit', '', 3499, '2-3 hrs', 4.9, 'Pooja setup'],
        ['Pooja Services', 'Griha Pravesh Pooja', '', 4999, '3-4 hrs', 4.9, 'House inauguration'],
        ['Pooja Services', 'Satyanarayn Katha', '', 2999, '2-3 hrs', 4.9, 'Religious ceremony'],
        ['Pooja Services', 'Navratri / Devi Pooja', '', 3999, '2-4 hrs', 4.8, 'Festival pooja'],
        ['Pooja Services', 'Vastu Shanti Pooja', '', 4499, '3 hrs', 4.9, 'Vastu ceremony'],
        ['Pooja Services', 'Birthday / Anniversary Pooja', '', 2499, '1-2 hrs', 4.8, 'Birthday ceremony'],
        ['Pooja Services', 'Laxmi / Diwali Pooja', '', 2999, '2 hrs', 4.8, 'Diwali pooja'],
        ['Pooja Services', 'Shiv Pooja / Rudrabhibek', '', 3499, '2-3 hrs', 4.9, 'Shiv pooja'],
        ['Pooja Services', 'Pooja Samagri Delivery', '', 699, 'Same Day', 4.7, 'Samagri delivery'],
        ['Pooja Services', 'Hawan / Yagna Setup', '', 5499, '3-4 hrs', 4.9, 'Hawan ceremony'],

        // Festival Services
        ['Festival Services', 'Ganpati Decoration & Setup', '', 5499, 'Half Day', 4.9, 'Ganesh decoration'],
        ['Festival Services', 'Ganpati Visarjan Arrangements', '', 2999, '2-3 hrs', 4.8, 'Immersion'],
        ['Festival Services', 'Visarjan (Immersion) Delivery', '', 1399, '2-3 hrs', 4.9, 'Immersion service'],
        ['Festival Services', 'Diwali Home Decoration', '', 3999, '3-4 hrs', 4.8, 'Diwali setup'],
        ['Festival Services', 'Diwali Rangoli & Lighting Setup', '', 2499, '2-3 hrs', 4.8, 'Rangoli setup'],
        ['Festival Services', 'Diwali Cleaning Package', '', 2999, '4-5 hrs', 4.9, 'Diwali cleaning'],
        ['Festival Services', 'Navratri Dandiya Night Setup', '', 7999, 'Full Day', 4.9, 'Dandiya setup'],
        ['Festival Services', 'Navratri Decoration & Garba', '', 4999, '4-5 hrs', 4.8, 'Garba setup'],
        ['Festival Services', 'Pooja Decoration (All Festivals)', '', 2999, '2-3 hrs', 4.8, 'Pooja decoration'],
        ['Festival Services', 'Holi Colour & Event Setup', '', 3999, '3-4 hrs', 4.8, 'Holi setup'],
        ['Festival Services', 'Eid / Special Occasion Catering', '', 6999, 'Site Visit', 4.8, 'Catering'],
        ['Festival Services', 'Winter Festival Decoration & Setup', '', 3499, '3-4 hrs', 4.8, 'Festival decoration'],
        ['Festival Services', 'New Year Party Decoration', '', 4999, '4 hrs', 4.8, 'Party decoration'],
    ];

    foreach ($services as $svc) {
        $categoryName = $svc[0];
        $categoryId = $categoryIds[$categoryName] ?? null;
        if (!$categoryId) continue;

        $serviceName = $svc[1];
        $emoji = $svc[2];
        $price = $svc[3];
        $duration = $svc[4];
        $rating = $svc[5];
        $notes = $svc[6];

        $stmt = $conn->prepare("INSERT INTO services (category_id, name, emoji, price, duration, rating, notes) VALUES (?, ?, ?, ?, ?, ?, ?)");
        $stmt->bind_param("isisiss", $categoryId, $serviceName, $emoji, $price, $duration, $rating, $notes);
        if (!$stmt->execute()) {
            error_log("Error inserting service $serviceName: " . $stmt->error);
        }
        $stmt->close();
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Database setup completed with pricing data',
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
