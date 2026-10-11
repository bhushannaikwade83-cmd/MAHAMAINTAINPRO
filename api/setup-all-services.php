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

    // Categories data
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

    // All services with complete pricing from PriceList_MahaMaintainPro.xlsx
    $services = [
        // Insta Help (3491 total)
        ['Insta Help', 'Pipe Leakage Emergency', '⚡', 449, '30-45 min', 4.9, ''],
        ['Insta Help', 'Tap / Mixer Repair (Urgent)', '', 299, '30-45 min', 4.8, ''],
        ['Insta Help', 'Fan / Light Fitting (Urgent)', '', 299, '30 min', 4.8, ''],
        ['Insta Help', 'Door Lock Repair (Emergency)', '', 499, '45 min', 4.7, ''],
        ['Insta Help', 'Electrical Short / Trip', '', 299, '45 min', 4.8, ''],
        ['Insta Help', 'Gas Stove Repair (Emergency)', '', 399, '45 min', 4.7, ''],
        ['Insta Help', 'Drainage / Clog Clearance', '', 499, '45 min', 4.8, ''],
        ['Insta Help', 'Water Heater Not Working', '', 449, '45 min', 4.7, ''],
        ['Insta Help', 'MCB / Power Tripping (Urgent)', '', 349, '30 min', 4.8, ''],

        // Women's Salon & Spa (18817 total)
        ['Women\'s Salon & Spa', 'Hair Cut & Styling (Women)', '', 599, '45-60 min', 4.9, ''],
        ['Women\'s Salon & Spa', 'Facial (Glow / D-Tan)', '', 899, '60 min', 4.8, ''],
        ['Women\'s Salon & Spa', 'Full Body Waxing (Honey)', '', 1099, '60-90 min', 4.7, ''],
        ['Women\'s Salon & Spa', 'Bridal Package (Basic)', '', 5999, 'Half Day', 4.9, ''],
        ['Women\'s Salon & Spa', 'Pedicure & Manicure (Combo)', '', 799, '60 min', 4.8, ''],
        ['Women\'s Salon & Spa', 'Head Massage & Spa', '', 699, '60 min', 4.9, ''],
        ['Women\'s Salon & Spa', 'Eyebrow Threading & Shaping', '', 99, '20 min', 4.8, ''],
        ['Women\'s Salon & Spa', 'Hair Colour & Highlights', '', 1999, '2-3 hrs', 4.7, ''],
        ['Women\'s Salon & Spa', 'Keratin / Smoothening Treatment', '', 3999, '3-4 hrs', 4.8, ''],
        ['Women\'s Salon & Spa', 'Bleach & Detan (Face)', '', 449, '30 min', 4.7, ''],
        ['Women\'s Salon & Spa', 'Cleanup', '', 349, '30 min', 4.8, ''],
        ['Women\'s Salon & Spa', 'Nail Art & Extension', '', 1299, '60-90 min', 4.8, ''],
        ['Women\'s Salon & Spa', 'Mehendi / Henna Application', '', 799, '60 min', 4.8, ''],

        // Men's Salon & Massage (5989 total)
        ['Men\'s Salon & Massage', 'Hair Cut (Men)', '', 249, '30 min', 4.8, ''],
        ['Men\'s Salon & Massage', 'Hair Cut (Kids Under 12)', '', 199, '20 min', 4.8, ''],
        ['Men\'s Salon & Massage', 'Shave & Beard Styling', '', 199, '20-30 min', 4.8, ''],
        ['Men\'s Salon & Massage', 'Swedish Massage (60 min)', '', 1299, '60 min', 4.9, ''],
        ['Men\'s Salon & Massage', 'Hair Colour (Men)', '', 699, '45 min', 4.7, ''],
        ['Men\'s Salon & Massage', 'Tan & Clean-Up (Men)', '', 499, '45 min', 4.8, ''],
        ['Men\'s Salon & Massage', 'Hair Spa Treatment', '', 799, '45-60 min', 4.8, ''],
        ['Men\'s Salon & Massage', 'Beard Colour & Styling', '', 399, '30 min', 4.7, ''],
        ['Men\'s Salon & Massage', 'Head Massage (45 min)', '', 549, '45 min', 4.8, ''],
        ['Men\'s Salon & Massage', 'Pedicure & Foot Care (Men)', '', 599, '45 min', 4.7, ''],
        ['Men\'s Salon & Massage', 'Dandruff Treatment', '', 499, '30 min', 4.7, ''],

        // Professional Cleaning (27736 total)
        ['Cleaning', 'Professional Home Deep Clean (1BHK)', '', 3499, '3-4 hrs', 4.9, ''],
        ['Cleaning', 'Professional Home Deep Clean (2BHK)', '', 3999, '4-5 hrs', 4.9, ''],
        ['Cleaning', 'Professional Home Deep Clean (3BHK)', '', 4499, '5-6 hrs', 4.9, ''],
        ['Cleaning', 'Professional Bathroom Deep Clean', '', 599, '1.5-2 hrs', 4.9, ''],
        ['Cleaning', 'Professional Kitchen Deep Clean', '', 999, '2 hrs', 4.8, ''],
        ['Cleaning', 'Professional Sofa Cleaning (3-Seater)', '', 899, '2 hrs', 4.8, ''],
        ['Cleaning', 'Professional Carpet / Rug Dry Cleaning', '', 699, '2-3 hrs', 4.8, ''],
        ['Cleaning', 'Professional Water Tank Cleaning (500L)', '', 999, '2 hrs', 4.9, ''],
        ['Cleaning', 'Professional Mattress Cleaning & Sanitise', '', 699, '1-2 hrs', 4.8, ''],
        ['Cleaning', 'Professional Office / Commercial Cleaning', '', 3999, '3-5 hrs', 4.7, ''],
        ['Cleaning', 'Professional Post-Construction Cleaning', '', 5499, 'Full Day', 4.7, ''],
        ['Cleaning', 'Professional Balcony & Window Cleaning', '', 449, '1 hr', 4.8, ''],
        ['Cleaning', 'Professional Refrigerator Deep Clean', '', 399, '1 hr', 4.7, ''],
        ['Cleaning', 'Professional Overhead / Sump Tank Cleaning', '', 1999, '3-4 hrs', 4.9, ''],

        // Home Painting (82584 total)
        ['Home Painting', 'Wall Painting (Per sq.ft)', '', 18, 'Per sq.ft', 4.6, ''],
        ['Home Painting', 'Full Home Painting (1BHK)', '', 12999, '2-3 days', 4.8, ''],
        ['Home Painting', 'Full Home Painting (2BHK)', '', 18999, '3-4 days', 4.8, ''],
        ['Home Painting', 'Full Home Painting (3BHK)', '', 26999, '4-5 days', 4.8, ''],
        ['Home Painting', 'Waterproofing (Bathroom)', '', 3499, '1 day', 4.8, ''],
        ['Home Painting', 'Waterproofing (Terrace / Roof)', '', 6999, '1-2 days', 4.9, ''],
        ['Home Painting', 'Texture / Designer Painting', '', 75, 'Per sq.ft', 4.7, ''],
        ['Home Painting', 'Wood Polish & Varnish', '', 2999, '1-2 days', 4.7, ''],
        ['Home Painting', 'Gate & Grill Painting', '', 1999, '1 day', 4.7, ''],
        ['Home Painting', 'Ceiling Painting Only', '', 4999, '1-2 days', 4.7, ''],
        ['Home Painting', 'Enamel / Oil Paint (Wood & Metal)', '', 2999, '1 day', 4.7, ''],

        // AC & Appliance (11235 total)
        ['AC & Appliance Repair', 'AC Jet Service', '', 599, '1.5-2 hrs', 4.8, ''],
        ['AC & Appliance Repair', 'AC Gas Refill (R32 / R410)', '', 2499, '1-1.5 hrs', 4.7, ''],
        ['AC & Appliance Repair', 'AC Installation (Split)', '', 1499, '3-4 hrs', 4.9, ''],
        ['AC & Appliance Repair', 'AC Installation (Window)', '', 799, '3-4 hrs', 4.9, ''],
        ['AC & Appliance Repair', 'AC Uninstallation', '', 499, '1-2 hrs', 4.8, ''],
        ['AC & Appliance Repair', 'Washing Machine Repair', '', 499, '1 hr', 4.7, ''],
        ['AC & Appliance Repair', 'Washing Machine Installation', '', 399, '45 min', 4.8, ''],
        ['AC & Appliance Repair', 'Refrigerator / Fridge Service', '', 499, '1 hr', 4.8, ''],
        ['AC & Appliance Repair', 'Microwave / OTG Repair', '', 399, '45 min', 4.6, ''],
        ['AC & Appliance Repair', 'Chimney / Exhaust Cleaning', '', 899, '1 hr', 4.7, ''],
        ['AC & Appliance Repair', 'Geyser / Water Heater Repair', '', 499, '1 hr', 4.8, ''],
        ['AC & Appliance Repair', 'TV / LED Repair', '', 599, '1-2 hrs', 4.7, ''],
        ['AC & Appliance Repair', 'Air Cooler Service & Repair', '', 399, '1 hr', 4.7, ''],
        ['AC & Appliance Repair', 'Air Purifier Repair', '', 599, '1 hr', 4.7, ''],
        ['AC & Appliance Repair', 'Dishwasher Repair', '', 599, '1-1.5 hrs', 4.7, ''],

        // Electrician, Plumber & Carpenter (7433 total)
        ['Electrician, Plumber & Carpenter', 'Electrician (General Visit)', '', 199, '45 min', 4.8, ''],
        ['Electrician, Plumber & Carpenter', 'Fan Installation / Repair', '', 299, '30-45 min', 4.8, ''],
        ['Electrician, Plumber & Carpenter', 'Light / Fixture Installation', '', 249, '30 min', 4.8, ''],
        ['Electrician, Plumber & Carpenter', 'IMCB / DB Box Work', '', 499, '1 hr', 4.7, ''],
        ['Electrician, Plumber & Carpenter', 'Inverter / Battery Installation', '', 799, '1-2 hrs', 4.7, ''],
        ['Electrician, Plumber & Carpenter', 'Earthing & Wiring Check', '', 499, '1 hr', 4.8, ''],
        ['Electrician, Plumber & Carpenter', 'Plumber (General Visit)', '', 199, '45 min', 4.8, ''],
        ['Electrician, Plumber & Carpenter', 'Tap / Mixer Replacement', '', 549, '45 min', 4.8, ''],
        ['Electrician, Plumber & Carpenter', 'Toilet Flush Repair', '', 349, '45-60 min', 4.7, ''],
        ['Electrician, Plumber & Carpenter', 'Drainage Pipe Unclogging', '', 449, '45 min', 4.7, ''],
        ['Electrician, Plumber & Carpenter', 'Basin / Sink Fitting', '', 599, '1 hr', 4.8, ''],
        ['Electrician, Plumber & Carpenter', 'Carpenter (General Visit)', '', 249, '1 hr', 4.7, ''],
        ['Electrician, Plumber & Carpenter', 'Door / Window Repair', '', 449, '1-2 hrs', 4.8, ''],
        ['Electrician, Plumber & Carpenter', 'Lock / Handle Replacement', '', 349, '45 min', 4.8, ''],
        ['Electrician, Plumber & Carpenter', 'Wall Drilling & TV Mounting', '', 399, '45 min', 4.8, ''],
        ['Electrician, Plumber & Carpenter', 'Wooden Shelf / Wardrobe Repair', '', 599, '1-2 hrs', 4.7, ''],

        // Vehicle Care (22887 total)
        ['Vehicle Care', 'Car Wash (Exterior + Interior)', '', 499, '45 min', 4.7, ''],
        ['Vehicle Care', 'Car Interior Deep Clean', '', 1499, '2-3 hrs', 4.8, ''],
        ['Vehicle Care', 'Bike Wash & Polish', '', 299, '30-45 min', 4.7, ''],
        ['Vehicle Care', 'Car Detailing (Premium)', '', 4999, 'Half Day', 4.9, ''],
        ['Vehicle Care', 'Car AC Gas Refill', '', 1999, '1-2 hrs', 4.8, ''],
        ['Vehicle Care', 'Dent & Paint Touch-up', '', 2499, 'Site Visit', 4.7, ''],
        ['Vehicle Care', 'Tyre Puncture (Home Service)', '', 249, '30 min', 4.8, ''],
        ['Vehicle Care', 'Car Engine Oil Change', '', 899, '1 hr', 4.7, ''],
        ['Vehicle Care', 'Bike Engine Oil Change', '', 399, '45 min', 4.7, ''],
        ['Vehicle Care', 'Battery Jump-start / Replacement', '', 599, '30-45 min', 4.8, ''],
        ['Vehicle Care', 'Windshield / Glass Cleaning', '', 249, '30 min', 4.7, ''],
        ['Vehicle Care', 'Car Polish & Wax', '', 1299, '2 hrs', 4.8, ''],
        ['Vehicle Care', 'Ceramic Coating (Car)', '', 7999, 'Full Day', 4.9, ''],
        ['Vehicle Care', 'Foam / Pressure Car Wash', '', 699, '1 hr', 4.9, ''],

        // Food & Catering (51990 total)
        ['Food & Catering', 'Home Cook (Per Visit)', '', 599, '2-3 hrs', 4.8, ''],
        ['Food & Catering', 'Tiffin Service (Monthly)', '', 4499, 'Monthly', 4.7, ''],
        ['Food & Catering', 'Party Catering (25 pax)', '', 12499, 'Site Visit', 4.9, ''],
        ['Food & Catering', 'Party Catering (50 pax)', '', 21999, 'Site Visit', 4.9, ''],
        ['Food & Catering', 'Pooja Prasad Preparation', '', 999, '2-3 hrs', 4.8, ''],
        ['Food & Catering', 'Birthday Cake & Snacks Setup', '', 1999, '2 hrs', 4.8, ''],
        ['Food & Catering', 'Diet / Health Meal Prep', '', 899, '2-3 hrs', 4.7, ''],
        ['Food & Catering', 'Daily Maid-Cook (Part-time)', '', 6999, 'Monthly', 4.8, ''],
        ['Food & Catering', 'Sweets & Farsan Preparation', '', 1299, '3-4 hrs', 4.7, ''],
        ['Food & Catering', 'Office Lunch Box (Per Day)', '', 199, 'Delivery', 4.6, ''],

        // Health & Care (16985 total)
        ['Health & Care', 'Nurse / Attendant (Day Shift)', '', 1999, '8 hrs', 4.9, ''],
        ['Health & Care', 'Nurse / Attendant (Night Shift)', '', 2499, '10 hrs', 4.9, ''],
        ['Health & Care', 'Physiotherapy (Home Visit)', '', 899, '45-60 min', 4.9, ''],
        ['Health & Care', 'Blood Test (Home Collection)', '', 399, '30 min', 4.8, ''],
        ['Health & Care', 'Elder Care (Full Day)', '', 2499, 'Full Day', 4.9, ''],
        ['Health & Care', 'Post-Surgery Home Care', '', 2999, '8 hrs', 4.9, ''],
        ['Health & Care', 'Yoga / Fitness (Home Session)', '', 699, '60 min', 4.8, ''],
        ['Health & Care', 'Dietician Consultation (Online)', '', 399, '45 min', 4.7, ''],
        ['Health & Care', 'Doctor Home Visit (GP)', '', 899, '30-45 min', 4.8, ''],
        ['Health & Care', 'Vaccination at Home', '', 599, '30 min', 4.7, ''],
        ['Health & Care', 'Baby Care / Nanny', '', 1599, '8 hrs', 4.9, ''],
        ['Health & Care', 'Wheelchair / Equipment Rental', '', 699, 'Per day', 4.7, ''],

        // Pooja Services (35190 total)
        ['Pooja Services', 'Ganesh Pooja Setup & Pandit', '', 3499, '2-3 hrs', 4.9, ''],
        ['Pooja Services', 'Griha Pravesh Pooja', '', 4999, '3-4 hrs', 4.9, ''],
        ['Pooja Services', 'Satyanarayn Katha', '', 2999, '2-3 hrs', 4.9, ''],
        ['Pooja Services', 'Navratri / Devi Pooja', '', 3999, '2-4 hrs', 4.8, ''],
        ['Pooja Services', 'Vastu Shanti Pooja', '', 4499, '3 hrs', 4.9, ''],
        ['Pooja Services', 'Birthday / Anniversary Pooja', '', 2499, '1-2 hrs', 4.8, ''],
        ['Pooja Services', 'Laxmi / Diwali Pooja', '', 2999, '2 hrs', 4.8, ''],
        ['Pooja Services', 'Shiv Pooja / Rudrabhibek', '', 3499, '2-3 hrs', 4.9, ''],
        ['Pooja Services', 'Pooja Samagri Delivery', '', 699, 'Same Day', 4.7, ''],
        ['Pooja Services', 'Hawan / Yagna Setup', '', 5499, '3-4 hrs', 4.9, ''],

        // Festival Services (55987 total)
        ['Festival Services', 'Ganpati Decoration & Setup', '', 5499, 'Half Day', 4.9, ''],
        ['Festival Services', 'Ganpati Visarjan Arrangements', '', 2999, '2-3 hrs', 4.8, ''],
        ['Festival Services', 'Visarjan (Immersion) Delivery', '', 1399, '2-3 hrs', 4.9, ''],
        ['Festival Services', 'Diwali Home Decoration', '', 3999, '3-4 hrs', 4.8, ''],
        ['Festival Services', 'Diwali Rangoli & Lighting Setup', '', 2499, '2-3 hrs', 4.8, ''],
        ['Festival Services', 'Diwali Cleaning Package', '', 2999, '4-5 hrs', 4.9, ''],
        ['Festival Services', 'Navratri Dandiya Night Setup', '', 7999, 'Full Day', 4.9, ''],
        ['Festival Services', 'Navratri Decoration & Garba', '', 4999, '4-5 hrs', 4.8, ''],
        ['Festival Services', 'Pooja Decoration (All Festivals)', '', 2999, '2-3 hrs', 4.8, ''],
        ['Festival Services', 'Holi Colour & Event Setup', '', 3999, '3-4 hrs', 4.8, ''],
        ['Festival Services', 'Eid / Special Occasion Catering', '', 6999, 'Site Visit', 4.8, ''],
        ['Festival Services', 'Winter Festival Decoration & Setup', '', 3499, '3-4 hrs', 4.8, ''],
        ['Festival Services', 'New Year Party Decoration', '', 4999, '4 hrs', 4.8, ''],

        // Pest Control (28737 total)
        ['Pest Control', 'General Pest Control (1BHK)', '', 1099, '1-2 hrs', 4.7, ''],
        ['Pest Control', 'General Pest Control (2BHK)', '', 1499, '1.5-2 hrs', 4.7, ''],
        ['Pest Control', 'General Pest Control (3BHK)', '', 1899, '2-3 hrs', 4.7, ''],
        ['Pest Control', 'Cockroach Gel Treatment', '', 599, '45 min', 4.9, ''],
        ['Pest Control', 'Cockroach Control (Quarterly)', '', 1199, '2 hrs', 4.8, ''],
        ['Pest Control', 'Termite Control', '', 1499, '1-2 hrs', 4.8, ''],
        ['Pest Control', 'Bed Bug Treatment', '', 1999, '2 hrs', 4.8, ''],
        ['Pest Control', 'Rodent Control', '', 899, '1 hr', 4.7, ''],
        ['Pest Control', 'Mosquito / Dengue Fogging Spray', '', 899, '1 hr', 4.7, ''],
        ['Pest Control', 'Rat / Rodent Control', '', 1299, '1-2 hrs', 4.7, ''],
        ['Pest Control', 'Society / Common Area Pest', '', 4999, 'Half Day', 4.8, ''],
        ['Pest Control', 'Ant Control Treatment', '', 749, '1 hr', 4.7, ''],
        ['Pest Control', 'Lizard & Spider Repellent', '', 699, '1 hr', 4.6, ''],
        ['Pest Control', 'Annual Pest Control Contract', '', 5999, '12 months', 4.8, ''],
        ['Pest Control', 'Kitchen / Restaurant Pest Control', '', 3499, '2-3 hrs', 4.8, ''],

        // Smart Society (138702 total)
        ['Smart Society Management', 'Society Gate Motor Repair', '', 1899, '2-3 hrs', 4.8, ''],
        ['Smart Society Management', 'Lift Maintenance / Repair', '', 3499, 'Site Visit', 4.9, ''],
        ['Smart Society Management', 'Common Area Deep Clean', '', 4999, 'Half Day', 4.7, ''],
        ['Smart Society Management', 'Water Pump Repair', '', 1299, '1-2 hrs', 4.8, ''],
        ['Smart Society Management', 'Society Electrician Visit', '', 499, '1 hr', 4.8, ''],
        ['Smart Society Management', 'CCTV Installation (per camera)', '', 3999, '2-3 hrs', 4.9, ''],
        ['Smart Society Management', 'Intercom / Video Door Bell', '', 2499, '2 hrs', 4.8, ''],
        ['Smart Society Management', 'Society Painting (Common Area)', '', 18, 'Per sq.ft', 4.7, ''],
        ['Smart Society Management', 'Garden / Landscape Maintenance', '', 2499, '3-4 hrs', 4.8, ''],
        ['Smart Society Management', 'Society Management Software', '', 6999, 'Monthly', 4.9, ''],
        ['Smart Society Management', 'AMC Contract (Annual)', '', 49999, '12 months', 4.9, ''],
        ['Smart Society Management', 'Member / Flat-wise Billing', '', 6999, 'Setup', 4.9, ''],
        ['Smart Society Management', 'Interest & Penalty Calculation', '', 2499, 'Monthly', 4.8, ''],
        ['Smart Society Management', 'Society Accounts & Audit', '', 9999, 'Annual', 4.9, ''],
        ['Smart Society Management', 'Plumbing AMC (Society)', '', 14999, '12 months', 4.8, ''],
        ['Smart Society Management', 'Security Guard Deployment', '', 18999, 'Monthly', 4.8, ''],
        ['Smart Society Management', 'Parking Management Setup', '', 6999, 'Setup', 4.7, ''],

        // Real Estate (29688 total)
        ['Real Estate', 'Property Site Visit & Inspection', '', 699, '2-3 hrs', 4.8, ''],
        ['Real Estate', 'Flat / Home for Rent (Listing)', '', 1499, '7-14 days', 4.7, ''],
        ['Real Estate', 'Flat / Home for Sale (Listing)', '', 2999, 'Site Visit', 4.8, ''],
        ['Real Estate', 'Property Documentation Help', '', 3499, '1-2 days', 4.8, ''],
        ['Real Estate', 'Society NOC & Paperwork', '', 1999, '3-5 days', 4.7, ''],
        ['Real Estate', 'Interior Design Consultation', '', 1499, '2 hrs', 4.9, ''],
        ['Real Estate', 'Vastu Consultation (Property)', '', 1999, '2-3 hrs', 4.8, ''],
        ['Real Estate', 'Rental Agreement Drafting', '', 1999, '1-2 days', 4.8, ''],
        ['Real Estate', 'Property Legal Verification', '', 4999, '3-5 days', 4.9, ''],
        ['Real Estate', 'Pre-Move-In Home Inspection', '', 999, '2 hrs', 4.8, ''],
        ['Real Estate', 'Commercial Space Listing', '', 3999, 'Site Visit', 4.7, ''],
        ['Real Estate', 'Plot / Land Listing', '', 3499, 'Site Visit', 4.7, ''],

        // Interior Designer (14999 total)
        ['Interior Designer', 'Full Home Interior Design', '', 1499, '2 hrs', 4.9, ''],
        ['Interior Designer', 'Modular Kitchen Design', '', 1999, '1-2 days', 4.9, ''],
        ['Interior Designer', 'Wardrobe Design', '', 1699, '2 hrs', 4.8, ''],
        ['Interior Designer', 'False Ceiling Design', '', 1799, '2-3 hrs', 4.8, ''],
        ['Interior Designer', '3D Visualization / Space Planning', '', 999, '1-2 days', 4.8, ''],
        ['Interior Designer', 'Furniture Selection & Sourcing', '', 2499, '3-4 hrs', 4.8, ''],
        ['Interior Designer', 'Turnkey Execution', '', 2999, '3-5 days', 4.7, ''],
        ['Interior Designer', 'Office / Commercial Interior Design', '', 2499, '2-3 hrs', 4.8, ''],
        ['Interior Designer', 'Renovation Consultation', '', 1499, '2 hrs', 4.8, ''],

        // Hologram Services (106990 total)
        ['Hologram Services', '3D Hologram Fun Display (Rental)', '', 3999, 'Per day', 4.9, ''],
        ['Hologram Services', 'Hologram Fan Purchase & Setup', '', 19999, '1-2 days', 4.9, ''],
        ['Hologram Services', 'Hologram for Wedding Event', '', 14999, 'Full Day', 4.9, ''],
        ['Hologram Services', 'Hologram for Society Events', '', 9999, 'Full Day', 4.8, ''],
        ['Hologram Services', 'Hologram Brand Promo Display', '', 6999, 'Per day', 4.8, ''],
        ['Hologram Services', 'Product Launch Hologram Setup', '', 15999, 'Full Day', 4.9, ''],
        ['Hologram Services', 'Hologram Content Design (3D)', '', 4999, '3-5 days', 4.8, ''],
        ['Hologram Services', 'Hologram Stage Backdrop', '', 12999, 'Full Day', 4.9, ''],
        ['Hologram Services', 'Ganpati / Festival Hologram', '', 7999, 'Per event', 4.9, ''],
        ['Hologram Services', 'Hologram for Retail / Shop', '', 8999, 'Setup', 4.8, ''],

        // Fire Safety
        ['Fire Safety', 'Fire Extinguisher Supply & Installation', '', 1899, '2-3 hrs', 4.8, ''],
        ['Fire Safety', 'Fire Extinguisher AMC', '', 499, '1.5-2 hrs', 4.9, ''],
        ['Fire Safety', 'Fire Hydrant System Installation', '', 3999, '3-5 days', 4.7, ''],
        ['Fire Safety', 'Fire Sprinkler System Installation', '', 4499, '3-5 days', 4.8, ''],
        ['Fire Safety', 'Smoke Detector & Fire Alarm Installation', '', 1899, '2-3 hrs', 4.8, ''],
        ['Fire Safety', 'Fire Hose Reel Installation & Maintenance', '', 2499, '2-3 hrs', 4.7, ''],
        ['Fire Safety', 'Emergency Lighting & Exit Signage Installation', '', 2199, '2-3 hrs', 4.8, ''],
        ['Fire Safety', 'Fire NOC Documentation Assistance', '', 1999, '3-5 days', 4.7, ''],
        ['Fire Safety', 'Fire Safety Audit & Compliance Certificate', '', 3999, '2-3 hrs', 4.8, ''],
        ['Fire Safety', 'Fire Safety Mock Drill & Staff Training', '', 4999, '2-3 hrs', 4.8, ''],

        // Water Proofing
        ['Water Proofing', 'Terrace / Roof Waterproofing', '', 4499, '2-3 days', 4.8, ''],
        ['Water Proofing', 'Bathroom Waterproofing', '', 2999, '1-2 days', 4.8, ''],
        ['Water Proofing', 'Basement Waterproofing', '', 5499, '2-3 days', 4.9, ''],
        ['Water Proofing', 'External Wall Waterproofing', '', 3999, '2-3 days', 4.8, ''],
        ['Water Proofing', 'Wall Dampness Treatment', '', 1999, '1-2 days', 4.8, ''],
        ['Water Proofing', 'Water Tank Waterproofing', '', 2499, '1-2 days', 4.8, ''],
        ['Water Proofing', 'Expansion Joint Treatment', '', 1299, '1-2 days', 4.8, ''],
        ['Water Proofing', 'Chemical Injection Grouting', '', 1499, '1-2 days', 4.7, ''],
        ['Water Proofing', 'Waterproofing AMC / Warranty Service', '', 2499, '12 months', 4.8, ''],

        // Water Testing
        ['Water Testing', 'Potability Test (Basic)', '', 699, '2-3 days', 4.8, ''],
        ['Water Testing', 'Detailed Chemical Analysis', '', 1999, '4-5 days', 4.9, ''],
        ['Water Testing', 'Microbiological Test', '', 1299, '3-4 days', 4.7, ''],
        ['Water Testing', 'RO Water Purity Check', '', 399, '30 min', 4.8, ''],

        // Blood Testing
        ['Blood Testing', 'Full Body Checkup (Basic)', '', 1499, '24 hrs', 4.9, ''],
        ['Blood Testing', 'Diabetes Screening', '', 499, '12 hrs', 4.8, ''],
        ['Blood Testing', 'Thyroid Profile', '', 799, '24 hrs', 4.7, ''],
        ['Blood Testing', 'Vitamin D & B12 Test', '', 1699, '24 hrs', 4.8, ''],

        // Weekly Bazar
        ['Weekly Bazar', 'Fresh Veggie Combo (Small)', '', 349, 'Delivery', 4.8, ''],
        ['Weekly Bazar', 'Fresh Veggie Combo (Large)', '', 599, 'Delivery', 4.8, ''],
        ['Weekly Bazar', 'Fruit Basket (Seasonal)', '', 799, 'Delivery', 4.7, ''],
        ['Weekly Bazar', 'Organic Leafy Greens Set', '', 299, 'Delivery', 4.9, ''],

        // Tours & Travels
        ['Tours & Travels', 'Hire Driver (Local - 4 hrs)', '', 599, '4 hrs', 4.8, ''],
        ['Tours & Travels', 'Hire Driver (Local - 8 hrs)', '', 999, '8 hrs', 4.9, ''],
        ['Tours & Travels', 'Outstation Driver (Per Day)', '', 1999, '24 hrs', 4.9, ''],
        ['Tours & Travels', 'Airport Drop/Pick-up (Sedan)', '', 1499, 'Booking', 4.7, ''],
        ['Tours & Travels', 'Airport Drop/Pick-up (SUV)', '', 2199, 'Booking', 4.8, ''],
        ['Tours & Travels', 'Full Day Sightseeing (Mumbai)', '', 2999, '8-10 hrs', 4.8, ''],
        ['Tours & Travels', 'Outstation Car Rental (SUV)', '', 4499, 'Per day', 4.7, ''],
        ['Tours & Travels', 'Passport / Visa Assistance', '', 1499, 'Service', 4.6, ''],
        ['Tours & Travels', 'Bus / Train Ticket Booking', '', 150, 'Booking', 4.5, ''],
    ];

    $inserted = 0;
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
        if ($stmt->execute()) {
            $inserted++;
        }
        $stmt->close();
    }

    http_response_code(200);
    echo json_encode([
        'success' => true,
        'message' => 'Complete database setup with ALL pricing',
        'categories_inserted' => count($categories),
        'services_inserted' => $inserted,
    ]);

} catch (Exception $e) {
    http_response_code(500);
    error_log($e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}

$conn->close();
?>
