-- ============================================================
-- EventEase Event Management Database
-- Database Foundations (BUAN 6320) — UT Dallas | Aug 2024 – Dec 2024
-- ============================================================
-- Run Order:
--   1. Schema creation (this file)
--   2. All tables created with correct FK dependencies
--   3. Sample data inserted
--   4. Triggers, Stored Procedures, Functions defined
--   5. Sample complex queries at the bottom
-- ============================================================

SET SQL_SAFE_UPDATES = 0;

DROP DATABASE IF EXISTS EventEase;
CREATE DATABASE EventEase;
USE EventEase;

-- ============================================================
-- SECTION 1: CORE TABLES
-- ============================================================

CREATE TABLE Locations (
    loc_id       INT PRIMARY KEY AUTO_INCREMENT,
    location_name VARCHAR(255) NOT NULL,
    address       VARCHAR(255) NOT NULL
);

CREATE TABLE EventRecord (
    event_id        INT PRIMARY KEY AUTO_INCREMENT,
    event_name      VARCHAR(255) NOT NULL,
    event_organizer VARCHAR(255) NOT NULL,
    start_datetime  DATETIME NOT NULL,
    end_datetime    DATETIME NOT NULL,
    loc_id          INT NOT NULL,
    description     TEXT,
    CHECK (start_datetime < end_datetime),
    FOREIGN KEY (loc_id) REFERENCES Locations(loc_id) ON DELETE CASCADE
);

CREATE TABLE Person (
    person_id    INT PRIMARY KEY AUTO_INCREMENT,
    person_name  VARCHAR(255) NOT NULL,
    phone_number VARCHAR(10),
    email        VARCHAR(255) UNIQUE,
    CONSTRAINT chk_phone CHECK (phone_number REGEXP '^[0-9]{10}$')
);

CREATE TABLE Venue (
    venue_id   INT PRIMARY KEY AUTO_INCREMENT,
    loc_id     INT NOT NULL,
    venue_name VARCHAR(255) NOT NULL,
    capacity   INT,
    FOREIGN KEY (loc_id) REFERENCES Locations(loc_id) ON DELETE CASCADE
);

CREATE TABLE EventProgram (
    program_id     INT PRIMARY KEY AUTO_INCREMENT,
    event_id       INT,
    program_name   VARCHAR(255) NOT NULL,
    start_datetime DATETIME NOT NULL,
    end_datetime   DATETIME NOT NULL,
    venue_id       INT,
    FOREIGN KEY (event_id)  REFERENCES EventRecord(event_id)  ON DELETE CASCADE,
    FOREIGN KEY (venue_id)  REFERENCES Venue(venue_id)  ON DELETE CASCADE,
    CHECK (start_datetime < end_datetime)
);

-- ============================================================
-- SECTION 2: ROLE-SPECIFIC LINKING TABLES
-- ============================================================

CREATE TABLE Person_Staff (
    person_id  INT,
    event_id   INT,
    staff_type VARCHAR(255) NOT NULL,
    PRIMARY KEY (person_id, event_id),
    FOREIGN KEY (person_id) REFERENCES Person(person_id) ON DELETE CASCADE,
    FOREIGN KEY (event_id)  REFERENCES EventRecord(event_id)   ON DELETE CASCADE
);

CREATE TABLE Person_Attendee (
    person_id   INT,
    event_id    INT,
    ticket_type VARCHAR(100),
    checked_in  BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (person_id, event_id),
    FOREIGN KEY (person_id) REFERENCES Person(person_id) ON DELETE CASCADE,
    FOREIGN KEY (event_id)  REFERENCES EventRecord(event_id)   ON DELETE CASCADE
);

CREATE TABLE Person_Sponsor (
    person_id           INT,
    event_id            INT,
    contribution_amount DECIMAL(10,2),
    tier_name           VARCHAR(50),
    sponsored_date      DATETIME DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (person_id, event_id),
    FOREIGN KEY (person_id) REFERENCES Person(person_id) ON DELETE CASCADE,
    FOREIGN KEY (event_id)  REFERENCES EventRecord(event_id)   ON DELETE CASCADE
);

CREATE TABLE Person_Vendor (
    person_id    INT,
    event_id     INT,
    vendor_type  VARCHAR(255),
    company_name VARCHAR(255),
    PRIMARY KEY (person_id, event_id),
    FOREIGN KEY (person_id) REFERENCES Person(person_id) ON DELETE CASCADE,
    FOREIGN KEY (event_id)  REFERENCES EventRecord(event_id)   ON DELETE CASCADE
);

-- ============================================================
-- SECTION 3: VENDOR & FOOD TRUCK TABLES
-- ============================================================

CREATE TABLE Booths (
    booth_id             INT PRIMARY KEY AUTO_INCREMENT,
    person_vendor_id     INT,
    event_id             INT,
    booth_size           VARCHAR(50) COMMENT 'e.g., Small, Medium, Large',
    location_description TEXT,
    setup_time           TIME,
    teardown_time        TIME,
    FOREIGN KEY (person_vendor_id, event_id) REFERENCES Person_Vendor(person_id, event_id) ON DELETE CASCADE
);

CREATE TABLE Food_Truck (
    truck_id             INT PRIMARY KEY AUTO_INCREMENT,
    event_id             INT,
    truck_name           VARCHAR(255) NOT NULL,
    cuisine_type         VARCHAR(255),
    location_description TEXT,
    FOREIGN KEY (event_id) REFERENCES EventRecord(event_id) ON DELETE CASCADE
);

CREATE TABLE Food_Menu (
    menu_id      INT PRIMARY KEY AUTO_INCREMENT,
    truck_id     INT,
    item_name    VARCHAR(255) NOT NULL,
    price        DECIMAL(10,2),
    description  TEXT,
    is_available BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (truck_id) REFERENCES Food_Truck(truck_id) ON DELETE CASCADE
);

CREATE TABLE Food_Truck_Orders (
    orders_id          INT PRIMARY KEY AUTO_INCREMENT,
    truck_id           INT,
    customer_person_id INT,
    amount             DECIMAL(10,2) NOT NULL,
    payment_date       DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (truck_id)           REFERENCES Food_Truck(truck_id) ON DELETE CASCADE,
    FOREIGN KEY (customer_person_id) REFERENCES Person(person_id)    ON DELETE SET NULL
);

CREATE TABLE Food_Truck_Orders_Details (
    orders_details_id INT PRIMARY KEY AUTO_INCREMENT,
    quantity          INT,
    orders_id         INT,
    menu_id           INT,
    FOREIGN KEY (orders_id) REFERENCES Food_Truck_Orders(orders_id) ON DELETE CASCADE,
    FOREIGN KEY (menu_id)   REFERENCES Food_Menu(menu_id)           ON DELETE SET NULL
);

-- ============================================================
-- SECTION 4: PERFORMANCES & COMPETITIONS
-- ============================================================

CREATE TABLE Performances (
    performance_id   INT PRIMARY KEY AUTO_INCREMENT,
    program_id       INT NOT NULL,
    performance_name VARCHAR(255) NOT NULL,
    performance_type VARCHAR(255) NOT NULL,
    start_datetime   DATETIME NOT NULL,
    end_datetime     DATETIME NOT NULL,
    FOREIGN KEY (program_id) REFERENCES EventProgram(program_id) ON DELETE CASCADE,
    CHECK (start_datetime < end_datetime)
);

CREATE TABLE Performances_Superstar (
    performance_id INT NOT NULL,
    person_id      INT NOT NULL,
    PRIMARY KEY (performance_id, person_id),
    FOREIGN KEY (performance_id) REFERENCES Performances(performance_id) ON DELETE CASCADE,
    FOREIGN KEY (person_id)      REFERENCES Person(person_id)            ON DELETE CASCADE
);

CREATE TABLE Competition (
    competition_id   INT PRIMARY KEY AUTO_INCREMENT,
    program_id       INT NOT NULL,
    Competition_name VARCHAR(255) NOT NULL,
    performance_type VARCHAR(255) NOT NULL,
    start_datetime   DATETIME NOT NULL,
    end_datetime     DATETIME NOT NULL,
    FOREIGN KEY (program_id) REFERENCES EventProgram(program_id) ON DELETE CASCADE,
    CHECK (start_datetime < end_datetime)
);

CREATE TABLE Competition_Participants (
    competition_id    INT NOT NULL,
    person_id         INT NOT NULL,
    participants_role ENUM('Singer','Keyboardist','Guitarist','Drummer','Violinist','Choreographer','Magician','Painter'),
    PRIMARY KEY (competition_id, person_id),
    FOREIGN KEY (competition_id) REFERENCES Competition(competition_id) ON DELETE CASCADE,
    FOREIGN KEY (person_id)      REFERENCES Person(person_id)           ON DELETE CASCADE
);

CREATE TABLE Prizes (
    prize_id         INT PRIMARY KEY AUTO_INCREMENT,
    competition_id   INT,
    winner_person_id INT,
    prize_name       VARCHAR(255) NOT NULL,
    award_year       INT NOT NULL,
    award_category   VARCHAR(255),
    FOREIGN KEY (competition_id)   REFERENCES Competition(competition_id) ON DELETE CASCADE,
    FOREIGN KEY (winner_person_id) REFERENCES Person(person_id)           ON DELETE SET NULL
);

-- ============================================================
-- SECTION 5: PAYMENTS & FINANCIAL TABLES
-- ============================================================

CREATE TABLE Vendor_Payments (
    vendor_payment_id  INT PRIMARY KEY AUTO_INCREMENT,
    vendor_person_id   INT,
    event_id           INT,
    customer_person_id INT,
    amount             DECIMAL(10,2) NOT NULL,
    payment_date       DATETIME DEFAULT CURRENT_TIMESTAMP,
    description        TEXT,
    FOREIGN KEY (vendor_person_id)   REFERENCES Person(person_id)                           ON DELETE CASCADE,
    FOREIGN KEY (customer_person_id) REFERENCES Person(person_id)                           ON DELETE SET NULL,
    FOREIGN KEY (vendor_person_id, event_id) REFERENCES Person_Vendor(person_id, event_id) ON DELETE CASCADE
);

CREATE TABLE Salary (
    salary_id       INT PRIMARY KEY AUTO_INCREMENT,
    staff_person_id INT,
    event_id        INT,
    salary_amount   DECIMAL(10,2) NOT NULL,
    payment_date    DATETIME DEFAULT CURRENT_TIMESTAMP,
    description     TEXT,
    FOREIGN KEY (staff_person_id) REFERENCES Person(person_id) ON DELETE SET NULL,
    FOREIGN KEY (staff_person_id, event_id) REFERENCES Person_Staff(person_id, event_id) ON DELETE CASCADE
);

CREATE TABLE Performer_Remuneration (
    remuneration_id INT PRIMARY KEY AUTO_INCREMENT,
    person_id       INT,
    performance_id  INT,
    salary_amount   DECIMAL(10,2) NOT NULL,
    payment_date    DATETIME DEFAULT CURRENT_TIMESTAMP,
    description     TEXT,
    FOREIGN KEY (person_id)     REFERENCES Person(person_id) ON DELETE SET NULL,
    FOREIGN KEY (performance_id, person_id) REFERENCES Performances_Superstar(performance_id, person_id) ON DELETE CASCADE
);

CREATE TABLE Sponsorships (
    sponsorship_id INT PRIMARY KEY AUTO_INCREMENT,
    sponsor_id     INT,
    event_id       INT,
    amount         DECIMAL(10,2) NOT NULL,
    payment_date   DATETIME DEFAULT CURRENT_TIMESTAMP,
    description    TEXT,
    FOREIGN KEY (sponsor_id) REFERENCES Person(person_id) ON DELETE SET NULL,
    FOREIGN KEY (sponsor_id, event_id) REFERENCES Person_Sponsor(person_id, event_id) ON DELETE CASCADE
);

CREATE TABLE Payments (
    payment_id      INT PRIMARY KEY AUTO_INCREMENT,
    amount          DECIMAL(10,2) NOT NULL,
    payment_date    DATETIME DEFAULT CURRENT_TIMESTAMP,
    payment_status  ENUM('DEBIT','CREDIT','REFUND','PENDING'),
    payment_type    ENUM('VENDOR','FOOD_TRUCK','SPONSOR','REMUNERATION','SALARY'),
    vendor_payment_id INT,
    orders_id         INT,
    salary_id         INT,
    remuneration_id   INT,
    sponsorship_id    INT,
    CONSTRAINT CHK_Amount CHECK (amount > 0),
    FOREIGN KEY (vendor_payment_id) REFERENCES Vendor_Payments(vendor_payment_id),
    FOREIGN KEY (orders_id)         REFERENCES Food_Truck_Orders(orders_id),
    FOREIGN KEY (salary_id)         REFERENCES Salary(salary_id),
    FOREIGN KEY (remuneration_id)   REFERENCES Performer_Remuneration(remuneration_id),
    FOREIGN KEY (sponsorship_id)    REFERENCES Sponsorships(sponsorship_id)
);

-- ============================================================
-- SECTION 6: MISCELLANEOUS TABLES
-- ============================================================

CREATE TABLE Lost_And_Found (
    item_id            INT PRIMARY KEY AUTO_INCREMENT,
    event_id           INT,
    item_description   VARCHAR(255) NOT NULL,
    claimed            BOOLEAN DEFAULT FALSE,
    reported_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    claimed_timestamp  DATETIME,
    claimer_person_id  INT,
    FOREIGN KEY (event_id)          REFERENCES EventRecord(event_id)  ON DELETE CASCADE,
    FOREIGN KEY (claimer_person_id) REFERENCES Person(person_id) ON DELETE SET NULL
);

-- ============================================================
-- SECTION 7: SAMPLE DATA
-- ============================================================

INSERT INTO Locations (location_name, address) VALUES
('UTD Main Campus',              '800 W Campbell Rd, Richardson, TX 75080'),
('UTD Research Center',          '17878 Plano Rd, Richardson, TX 75081'),
('UTD Callier Center',           '1966 Inwood Rd, Dallas, TX 75235'),
('UTD at Cityline',              '3000 Waterview Pkwy, Richardson, TX 75080'),
('UTD Synergy Park North',       '3020 Waterview Pkwy, Richardson, TX 75080'),
('UTD Venture Development Center','17217 Waterview Pkwy, Dallas, TX 75252'),
('UTD Center for BrainHealth',   '2200 W Mockingbird Ln, Dallas, TX 75235'),
('UTD Center for Vital Longevity','1600 Viceroy Dr, Dallas, TX 75235');

INSERT INTO Venue (loc_id, venue_name, capacity) VALUES
(1,'Edith O\'Donnell Arts and Technology Building',1200),
(1,'Naveen Jindal School of Management',1500),
(1,'Erik Jonsson School of Engineering',1300),
(1,'School of Natural Sciences and Mathematics',1000),
(1,'School of Behavioral and Brain Sciences',800),
(1,'School of Economic, Political and Policy Sciences',700),
(1,'School of Interdisciplinary Studies',600),
(1,'UTD Activity Center',2000),
(1,'Eugene McDermott Library',1000),
(1,'Student Union',1500),
(2,'UTD Research Auditorium',500),
(3,'Callier Center Auditorium',300),
(4,'Cityline Conference Center',400),
(5,'Synergy Park Lecture Hall',250),
(6,'Venture Development Center',200),
(7,'BrainHealth Auditorium',350);

INSERT INTO EventRecord (event_name, event_organizer, start_datetime, end_datetime, loc_id, description) VALUES
('UTD Comets Hackathon','Computer Science Department','2024-11-15 09:00:00','2024-11-16 18:00:00',1,'Annual 24-hour coding competition for UTD students'),
('Business Leadership Symposium','Naveen Jindal School of Management','2024-12-05 10:00:00','2024-12-05 17:00:00',1,'A day of insights from industry leaders'),
('Engineering Innovation Expo','Erik Jonsson School of Engineering','2025-02-20 09:00:00','2025-02-21 16:00:00',1,'Showcase of cutting-edge engineering projects'),
('Science Fair Extravaganza','School of Natural Sciences and Mathematics','2025-03-10 10:00:00','2025-03-12 16:00:00',1,'Annual science fair for K-12 students'),
('Brain and Behavior Conference','School of Behavioral and Brain Sciences','2025-04-05 09:00:00','2025-04-07 17:00:00',7,'International conference on neuroscience and psychology'),
('Policy and Politics Debate','School of Economic, Political and Policy Sciences','2025-05-15 13:00:00','2025-05-15 20:00:00',1,'Debate on current political issues'),
('Interdisciplinary Research Symposium','School of Interdisciplinary Studies','2025-06-10 09:00:00','2025-06-11 17:00:00',2,'Showcasing cross-disciplinary research projects'),
('UTD Arts Festival','Edith O\'Donnell Arts and Technology Building','2025-07-01 10:00:00','2025-07-03 22:00:00',1,'Annual arts and technology showcase'),
('Comet Sports Invitational','UTD Athletics Department','2025-08-20 08:00:00','2025-08-22 18:00:00',1,'Multi-sport tournament for college athletes'),
('UTD Career Expo','Career Center','2025-09-15 10:00:00','2025-09-16 16:00:00',1,'Annual job fair for UTD students and alumni'),
('Research at UTD Showcase','Office of Research','2025-10-05 09:00:00','2025-10-06 17:00:00',2,'Highlighting groundbreaking research from all schools'),
('Callier Center Symposium','Callier Center for Communication Disorders','2025-11-10 09:00:00','2025-11-11 16:00:00',3,'Latest advancements in communication disorders'),
('Cityline Tech Conference','School of Engineering and Computer Science','2026-01-20 09:00:00','2026-01-22 17:00:00',4,'Conference on emerging technologies'),
('Synergy Park Startup Pitch','Institute for Innovation and Entrepreneurship','2026-02-15 10:00:00','2026-02-15 18:00:00',5,'Pitch competition for student startups'),
('Venture Development Expo','UTD Venture Development Center','2026-03-05 09:00:00','2026-03-06 17:00:00',6,'Showcase of UTD-affiliated startups and innovations'),
('BrainHealth Lecture Series','Center for BrainHealth','2026-04-10 14:00:00','2026-04-10 20:00:00',7,'Public lectures on brain health and cognitive enhancement');

INSERT INTO Person (person_name, phone_number, email) VALUES
('John Smith','2141234567','john.smith@utdallas.edu'),('Emma Johnson','9725551234','emma.johnson@utdallas.edu'),
('Michael Brown','4693339999','michael.brown@utdallas.edu'),('Sarah Davis','2145556789','sarah.davis@utdallas.edu'),
('David Wilson','9724445678','david.wilson@utdallas.edu'),('Jennifer Lee','4692223333','jennifer.lee@utdallas.edu'),
('Robert Taylor','2147778888','robert.taylor@utdallas.edu'),('Lisa Anderson','9723334444','lisa.anderson@utdallas.edu'),
('William Martinez','4695556666','william.martinez@utdallas.edu'),('Emily White','2148889999','emily.white@utdallas.edu'),
('James Harris','9726667777','james.harris@utdallas.edu'),('Jessica Clark','4691112222','jessica.clark@utdallas.edu'),
('Daniel Lewis','2142223333','daniel.lewis@utdallas.edu'),('Michelle Robinson','9727778888','michelle.robinson@utdallas.edu'),
('Christopher Walker','4694445555','christopher.walker@utdallas.edu'),('Amanda Hall','2143334444','amanda.hall@utdallas.edu'),
('Matthew Allen','9728889999','matthew.allen@utdallas.edu'),('Ashley Young','4697778888','ashley.young@utdallas.edu'),
('Andrew Scott','2146667777','andrew.scott@utdallas.edu'),('Nicole King','9721112222','nicole.king@utdallas.edu'),
('Joseph Wright','4692223334','joseph.wright@utdallas.edu'),('Stephanie Green','2145556667','stephanie.green@utdallas.edu'),
('Ryan Baker','9724447778','ryan.baker@utdallas.edu'),('Rachel Adams','4693338889','rachel.adams@utdallas.edu'),
('Kevin Nelson','2147779990','kevin.nelson@utdallas.edu'),('Laura Hill','9722223334','laura.hill@utdallas.edu'),
('Timothy Campbell','4695554445','timothy.campbell@utdallas.edu'),('Rebecca Mitchell','2148881112','rebecca.mitchell@utdallas.edu'),
('Jason Roberts','9723337778','jason.roberts@utdallas.edu'),('Karen Carter','4696662223','karen.carter@utdallas.edu'),
('Steven Phillips','2141114445','steven.phillips@utdallas.edu'),('Melissa Evans','9725558889','melissa.evans@utdallas.edu'),
('Mark Turner','4697773334','mark.turner@utdallas.edu'),('Angela Torres','2142226667','angela.torres@utdallas.edu'),
('Jeffrey Collins','9727771112','jeffrey.collins@utdallas.edu'),('Heather Murphy','4698885556','heather.murphy@utdallas.edu'),
('Brian Rivera','2143339990','brian.rivera@utdallas.edu'),('Amy Cook','9724442223','amy.cook@utdallas.edu'),
('Gregory Rogers','4691116667','gregory.rogers@utdallas.edu'),('Christine Reed','2146665556','christine.reed@utdallas.edu'),
('Kenneth Morgan','9728884445','kenneth.morgan@utdallas.edu'),('Deborah Bell','4693337778','deborah.bell@utdallas.edu'),
('Patrick Cooper','2147772223','patrick.cooper@utdallas.edu'),('Cynthia Richardson','9721115556','cynthia.richardson@utdallas.edu'),
('George Cox','4695559990','george.cox@utdallas.edu'),('Kathleen Howard','2148883334','kathleen.howard@utdallas.edu'),
('Larry Ward','9723336667','larry.ward@utdallas.edu'),('Diane Torres','4696661112','diane.torres@utdallas.edu'),
('Dennis Gray','2141114446','dennis.gray@utdallas.edu'),('Carol Watson','9725557778','carol.watson@utdallas.edu'),
('Jerry Brooks','4697772223','jerry.brooks@utdallas.edu'),('Ruth Long','2142225556','ruth.long@utdallas.edu'),
('Frank Kelly','9727778889','frank.kelly@utdallas.edu'),('Janet Sanders','4698883334','janet.sanders@utdallas.edu'),
('Scott Bennett','2143336667','scott.bennett@utdallas.edu'),('Cheryl Wood','9724441112','cheryl.wood@utdallas.edu'),
('Wayne Price','4691114445','wayne.price@utdallas.edu'),('Martha Barnes','2146667778','martha.barnes@utdallas.edu'),
('Arthur Ross','9728882223','arthur.ross@utdallas.edu'),('Frances Henderson','4693335556','frances.henderson@utdallas.edu'),
('Lawrence Jenkins','2147778889','lawrence.jenkins@utdallas.edu'),('Ann Perry','9721113334','ann.perry@utdallas.edu'),
('Eugene Hughes','4695556667','eugene.hughes@utdallas.edu'),('Dorothy Foster','2148881112','dorothy.foster@utdallas.edu'),
('Roy Washington','9723334445','roy.washington@utdallas.edu'),('Jean Butler','4696667778','jean.butler@utdallas.edu'),
('Bruce Simmons','2141112223','bruce.simmons@utdallas.edu'),('Lois Patterson','9725555556','lois.patterson@utdallas.edu'),
('Philip Flores','4697778889','philip.flores@utdallas.edu'),('Joyce Gonzales','2142223334','joyce.gonzales@utdallas.edu'),
('Roger Bryant','9727776667','roger.bryant@utdallas.edu'),('Tina Alexander','4698881112','tina.alexander@utdallas.edu'),
('Victor Russell','2143334445','victor.russell@utdallas.edu'),('Paula Griffin','9724447778','paula.griffin@utdallas.edu'),
('Todd West','4691112223','todd.west@utdallas.edu'),('Evelyn Cole','2146665556','evelyn.cole@utdallas.edu'),
('Craig Hawkins','9728888889','craig.hawkins@utdallas.edu'),('Phyllis Henry','4693333334','phyllis.henry@utdallas.edu'),
('Randy Ellis','2147776667','randy.ellis@utdallas.edu'),('Kathy Harrison','9721111112','kathy.harrison@utdallas.edu'),
('Alan Gibson','4695554445','alan.gibson@utdallas.edu'),('Jacqueline Mcdonald','2148887778','jacqueline.mcdonald@utdallas.edu'),
('Terry Cruz','9723332223','terry.cruz@utdallas.edu'),('Wanda Marshall','4696665556','wanda.marshall@utdallas.edu'),
('Gerald Owens','2141118889','gerald.owens@utdallas.edu'),('Pamela Kennedy','9725553334','pamela.kennedy@utdallas.edu'),
('Keith Wells','4697776667','keith.wells@utdallas.edu'),('Theresa Black','2142221112','theresa.black@utdallas.edu'),
('Harold Dunn','9727774445','harold.dunn@utdallas.edu'),('Maria Daniels','4698887778','maria.daniels@utdallas.edu'),
('Carl Stephens','2143332223','carl.stephens@utdallas.edu'),('Gloria Obrien','9724445556','gloria.obrien@utdallas.edu'),
('Jeremy Holt','4691118889','jeremy.holt@utdallas.edu'),('Kathryn Perkins','2146663334','kathryn.perkins@utdallas.edu'),
('Ralph Morrison','9728886667','ralph.morrison@utdallas.edu'),('Joan Caldwell','4693331112','joan.caldwell@utdallas.edu'),
('Johnny Walters','2147774445','johnny.walters@utdallas.edu'),('Louise Barker','9721117778','louise.barker@utdallas.edu'),
('Russell Boone','4695552223','russell.boone@utdallas.edu'),('Kelly Goodwin','2148885556','kelly.goodwin@utdallas.edu');

INSERT INTO Person_Staff (person_id, event_id, staff_type) VALUES
(1,1,'Event Manager'),(2,1,'Security'),(3,1,'Volunteer'),(4,1,'Janitorial Staff'),(5,1,'First Aid'),
(6,2,'Event Manager'),(7,2,'Security'),(8,2,'Volunteer'),
(9,3,'Event Manager'),(10,3,'Security'),(11,3,'Janitorial Staff'),
(12,4,'Event Manager'),(13,4,'First Aid'),(14,4,'Volunteer'),
(15,5,'Event Manager'),(16,5,'Security'),
(17,6,'Event Manager'),(18,6,'Janitorial Staff'),
(19,7,'Event Manager'),(20,7,'Volunteer'),
(21,8,'Event Manager'),(22,8,'Security'),
(23,9,'Event Manager'),(24,9,'First Aid'),
(25,10,'Event Manager');

INSERT INTO Person_Attendee (person_id, event_id, ticket_type, checked_in) VALUES
(26,1,'General Admission',TRUE),(27,1,'VIP',FALSE),(28,2,'General Admission',TRUE),(29,2,'VIP',TRUE),
(30,3,'General Admission',FALSE),(31,3,'General Admission',TRUE),(32,4,'VIP',TRUE),(33,4,'General Admission',FALSE),
(34,5,'General Admission',TRUE),(35,5,'VIP',TRUE),(36,6,'General Admission',FALSE),(37,6,'General Admission',TRUE),
(38,7,'VIP',FALSE),(39,7,'General Admission',TRUE),(40,8,'General Admission',TRUE),(41,8,'VIP',TRUE),
(42,9,'General Admission',FALSE),(43,9,'General Admission',TRUE),(44,10,'VIP',TRUE),(45,10,'General Admission',FALSE),
(46,11,'General Admission',TRUE),(47,11,'VIP',FALSE),(48,12,'General Admission',TRUE),(49,12,'General Admission',FALSE),
(50,13,'VIP',TRUE),(51,13,'General Admission',TRUE),(52,14,'General Admission',FALSE),(53,14,'VIP',TRUE),
(54,15,'General Admission',TRUE),(55,15,'General Admission',FALSE),(56,16,'VIP',TRUE),(57,1,'General Admission',TRUE),
(58,2,'General Admission',FALSE),(59,3,'VIP',TRUE),(60,4,'General Admission',TRUE),(61,5,'General Admission',FALSE),
(62,6,'VIP',TRUE),(63,7,'General Admission',TRUE),(64,8,'General Admission',FALSE),(65,9,'VIP',TRUE);

INSERT INTO Person_Sponsor (person_id, event_id, contribution_amount, tier_name) VALUES
(66,1,0.00,'Platinum'),(67,2,0.00,'Gold'),(68,3,0.00,'Silver'),(69,4,0.00,'Diamond'),
(70,5,0.00,'Gold'),(71,6,0.00,'Silver'),(72,7,0.00,'Platinum'),(73,8,0.00,'Gold'),
(74,9,5500.00,'Silver'),(75,10,20000.00,'Diamond');

INSERT INTO Person_Vendor (person_id, event_id, vendor_type, company_name) VALUES
(76,1,'Technology','TechCorp Solutions'),(77,2,'Catering','Gourmet Delights'),
(78,3,'Merchandise','Comet Swag Co.'),(79,4,'Photography','Capture Moments Studios'),
(80,5,'Audio/Visual','Sound & Vision Pro'),(81,6,'Decor','Elegant Events Decor'),
(82,7,'Security','SafeGuard Services'),(83,8,'Transportation','Shuttle Express'),
(84,9,'Printing','Quick Print Solutions'),(85,10,'Staffing','Event Staffing Pros'),
(86,11,'Technology','Innovate Tech Systems'),(87,12,'Catering','Flavor Fusion Catering'),
(88,13,'Merchandise','Brand It Custom Gear'),(89,14,'Photography','Lens Masters'),
(90,15,'Audio/Visual','Crystal Clear AV'),(91,16,'Decor','Festive Designs'),
(92,1,'Security','Eagle Eye Protection'),(93,2,'Transportation','Smooth Ride Services'),
(94,3,'Printing','Ink & Paper Experts'),(95,4,'Staffing','Reliable Event Personnel'),
(96,5,'Technology','Digital Solutions Inc.'),(97,6,'Catering','Tasty Bites Catering'),
(98,7,'Merchandise','Promo Gear Unlimited'),(99,8,'Photography','Shutter Speed Photos'),
(100,9,'Audio/Visual','Audiovisual Wizards');

INSERT INTO Booths (person_vendor_id, event_id, booth_size, location_description, setup_time, teardown_time) VALUES
(76,1,'Large','Near main entrance','08:00:00','19:00:00'),(77,2,'Medium','Central hall','07:30:00','18:30:00'),
(78,3,'Small','Corner booth','09:00:00','17:00:00'),(79,4,'Medium','Exhibition area','07:00:00','20:00:00'),
(80,5,'Large','Main auditorium','06:30:00','21:00:00'),(81,6,'Small','Foyer','08:30:00','18:00:00'),
(82,7,'Medium','Conference room A','07:45:00','19:30:00'),(83,8,'Large','Outdoor pavilion','06:00:00','22:00:00'),
(84,9,'Small','Information desk area','08:15:00','17:45:00'),(85,10,'Medium','Networking lounge','07:15:00','20:30:00'),
(86,11,'Large','Technology showcase area','06:45:00','21:30:00'),(87,12,'Small','Food court','09:30:00','16:30:00'),
(88,13,'Medium','Product demo zone','08:45:00','19:15:00'),(89,14,'Large','Main stage area','06:15:00','22:30:00'),
(90,15,'Small','Workshop room','09:15:00','17:30:00'),(91,16,'Medium','VIP lounge','07:45:00','20:45:00');

INSERT INTO Food_Truck (event_id, truck_name, cuisine_type, location_description) VALUES
(1,'Taco Fiesta','Mexican','Parking Lot A'),(1,'Burger Bliss','American','Parking Lot B'),
(2,'Sushi Roll','Japanese','Near Student Union'),(2,'Pizza Paradise','Italian','Main Quad'),
(3,'Curry in a Hurry','Indian','Engineering Building'),(3,'Wok This Way','Chinese','Science Complex'),
(4,'Falafel King','Middle Eastern','Library Plaza'),(4,'BBQ Pit Stop','American','Sports Field'),
(5,'Crepe Expectations','French','Arts Center'),(5,'Greek Eats','Greek','Business School'),
(6,'Smoothie Oasis','Health Food','Gym Entrance'),(6,'Pho Real','Vietnamese','International Center'),
(7,'Bratwurst Bros','German','Student Center'),(7,'Southern Comfort','Soul Food','Humanities Building'),
(8,'Taco Bout It','Mexican','Computer Science Building'),(8,'Waffle Wonderland','Breakfast','Dormitory Area'),
(9,'Veggie Voyage','Vegetarian','Green Space'),(9,'Mac Attack','American','Engineering Quad'),
(10,'Sushi-Go-Round','Japanese','Business School Courtyard'),(10,'Empanada Express','Latin American','Language Building');

INSERT INTO Food_Menu (truck_id, item_name, price, description) VALUES
(1,'Beef Taco',3.99,'Classic beef taco with fresh toppings'),(1,'Chicken Quesadilla',5.99,'Grilled chicken with melted cheese'),
(1,'Bottled Water',1.50,'Refreshing spring water'),(1,'Churros',2.99,'Traditional Mexican dessert'),
(2,'Classic Cheeseburger',6.99,'Juicy beef patty with cheese'),(2,'Veggie Burger',5.99,'Plant-based patty with fresh veggies'),
(2,'Soda',1.99,'Assorted soft drinks'),(2,'Apple Pie',3.50,'Homemade American classic'),
(3,'California Roll',7.99,'Crab, avocado, and cucumber roll'),(3,'Spicy Tuna Roll',8.99,'Tuna and spicy mayo roll'),
(3,'Green Tea',2.50,'Traditional Japanese green tea'),(3,'Mochi Ice Cream',3.99,'Assorted flavors'),
(4,'Margherita Pizza Slice',4.99,'Classic tomato and mozzarella'),(4,'Pepperoni Pizza Slice',5.49,'Pepperoni and cheese'),
(4,'Bottled Water',1.50,'Refreshing spring water'),(4,'Tiramisu',4.99,'Classic Italian coffee-flavored dessert'),
(5,'Chicken Tikka Masala',9.99,'Creamy tomato curry with chicken'),(5,'Vegetable Samosas',4.99,'Crispy pastry with spiced vegetables'),
(5,'Mango Lassi',3.99,'Yogurt-based mango drink'),(5,'Gulab Jamun',3.50,'Sweet milk solid balls in syrup'),
(6,'Beef and Broccoli',8.99,'Stir-fried beef with broccoli'),(6,'Vegetable Spring Rolls',4.99,'Crispy rolls with mixed vegetables'),
(6,'Jasmine Tea',2.50,'Fragrant Chinese tea'),(6,'Fortune Cookies',1.99,'Crisp cookies with fortunes'),
(7,'Falafel Wrap',7.99,'Falafel balls with tahini sauce'),(7,'Hummus Plate',5.99,'Creamy hummus with pita bread'),
(7,'Mint Lemonade',2.99,'Refreshing mint-infused lemonade'),(7,'Baklava',3.99,'Sweet pastry with nuts and honey'),
(8,'Pulled Pork Sandwich',8.99,'Slow-cooked pork with BBQ sauce'),(8,'Corn on the Cob',3.99,'Grilled corn with butter'),
(8,'Sweet Tea',2.50,'Southern-style sweet iced tea'),(8,'Peach Cobbler',4.99,'Warm peach dessert with crust topping'),
(9,'Nutella Crepe',6.99,'Thin pancake with Nutella spread'),(9,'Ham and Cheese Crepe',7.99,'Savory crepe with ham and cheese'),
(9,'French Press Coffee',3.50,'Strong, rich coffee'),(9,'Macarons',4.99,'Assorted flavors of French cookies'),
(10,'Gyro Wrap',8.99,'Seasoned meat with tzatziki sauce'),(10,'Greek Salad',6.99,'Fresh vegetables with feta cheese'),
(10,'Bottled Water',1.50,'Refreshing spring water'),(10,'Baklava',3.99,'Sweet pastry with nuts and honey'),
(11,'Green Goddess Smoothie',6.99,'Kale, spinach, banana, and almond milk blend'),(11,'Acai Bowl',8.99,'Acai blend topped with granola and fresh fruits'),
(11,'Coconut Water',3.50,'Natural coconut water'),(11,'Energy Balls',4.99,'Dates, nuts, and cocoa protein balls'),
(12,'Beef Pho',9.99,'Traditional Vietnamese noodle soup with beef'),(12,'Spring Rolls',5.99,'Fresh vegetables and shrimp in rice paper'),
(12,'Vietnamese Iced Coffee',3.99,'Strong coffee with sweetened condensed milk'),(12,'Mango Sticky Rice',4.50,'Sweet sticky rice with fresh mango'),
(13,'Classic Bratwurst',7.99,'Grilled sausage on a roll with sauerkraut'),(13,'Currywurst',8.99,'Sliced sausage with curry ketchup'),
(13,'German Beer',5.99,'Imported German beer'),(13,'Apple Strudel',4.99,'Traditional German pastry with apples'),
(14,'Fried Chicken Plate',10.99,'Crispy fried chicken with two sides'),(14,'Mac and Cheese',5.99,'Creamy baked macaroni and cheese'),
(14,'Sweet Tea',2.50,'Classic Southern sweet tea'),(14,'Pecan Pie',4.99,'Rich, sweet pecan filling in a buttery crust'),
(15,'Fish Tacos',8.99,'Battered fish with slaw and chipotle mayo'),(15,'Carne Asada Fries',9.99,'Fries topped with steak, cheese, and salsa'),
(15,'Horchata',3.50,'Sweet rice milk with cinnamon'),(15,'Sopapillas',3.99,'Fried pastry with cinnamon sugar'),
(16,'Belgian Waffle',7.99,'Classic waffle with maple syrup and butter'),(16,'Chicken and Waffles',11.99,'Crispy chicken on a waffle with syrup'),
(16,'Fresh Orange Juice',3.99,'Freshly squeezed orange juice'),(16,'Nutella Waffle',8.99,'Waffle topped with Nutella and strawberries'),
(17,'Quinoa Buddha Bowl',9.99,'Quinoa with roasted veggies and tahini dressing'),(17,'Impossible Burger',10.99,'Plant-based burger with all the fixings'),
(17,'Kombucha',4.50,'Fermented tea drink, assorted flavors'),(17,'Vegan Brownie',3.99,'Rich chocolate brownie, 100% vegan'),
(18,'Classic Mac',7.99,'Creamy cheese sauce with elbow macaroni'),(18,'Lobster Mac',13.99,'Mac and cheese with chunks of lobster meat'),
(18,'Lemonade',2.99,'Fresh-squeezed lemonade'),(18,'Cookie Skillet',5.99,'Warm chocolate chip cookie in a skillet'),
(19,'Dragon Roll',12.99,'Eel and cucumber roll topped with avocado'),(19,'Poke Bowl',11.99,'Sushi rice bowl with raw fish and toppings'),
(19,'Ramune Soda',2.99,'Japanese marble soda, assorted flavors'),(19,'Matcha Ice Cream',4.50,'Green tea flavored ice cream'),
(20,'Beef Empanada',3.99,'Savory pastry filled with seasoned beef'),(20,'Chicken Empanada',3.99,'Flaky pastry with chicken filling'),
(20,'Yerba Mate',3.50,'Traditional South American herbal tea'),(20,'Alfajores',2.99,'Shortbread cookies with dulce de leche filling');

INSERT INTO EventProgram (event_id, program_name, start_datetime, end_datetime, venue_id) VALUES
(1,'Opening Ceremony','2024-11-15 09:00:00','2024-11-15 10:00:00',1),
(1,'Coding Challenge','2024-11-15 10:30:00','2024-11-16 10:30:00',1),
(1,'Closing Ceremony','2024-11-16 17:00:00','2024-11-16 18:00:00',1),
(2,'Keynote Speech','2024-12-05 10:00:00','2024-12-05 11:00:00',2),
(2,'Panel Discussion','2024-12-05 11:30:00','2024-12-05 13:00:00',2),
(2,'Networking Session','2024-12-05 14:00:00','2024-12-05 17:00:00',2),
(3,'AI Research Forum','2025-02-20 09:00:00','2025-02-20 12:00:00',3),
(3,'Robotics Demonstration','2025-02-20 13:00:00','2025-02-20 15:00:00',3),
(3,'Future of Engineering Panel','2025-02-21 10:00:00','2025-02-21 12:00:00',3),
(4,'Science Fair Opening','2025-03-10 10:00:00','2025-03-10 11:00:00',4),
(4,'Project Presentations','2025-03-10 11:30:00','2025-03-12 15:00:00',4),
(4,'Awards Ceremony','2025-03-12 15:30:00','2025-03-12 16:00:00',4),
(5,'Neuroscience Keynote','2025-04-05 09:00:00','2025-04-05 10:30:00',7),
(5,'Research Presentations','2025-04-05 11:00:00','2025-04-07 16:00:00',7),
(5,'Closing Remarks','2025-04-07 16:30:00','2025-04-07 17:00:00',7),
(6,'Opening Statements','2025-05-15 13:00:00','2025-05-15 13:30:00',6),
(6,'Main Debate','2025-05-15 14:00:00','2025-05-15 18:00:00',6),
(6,'Q&A Session','2025-05-15 18:30:00','2025-05-15 20:00:00',6),
(7,'Research Showcase','2025-06-10 09:00:00','2025-06-10 12:00:00',2),
(7,'Interdisciplinary Workshops','2025-06-10 13:00:00','2025-06-11 15:00:00',2),
(7,'Networking Reception','2025-06-11 15:30:00','2025-06-11 17:00:00',2),
(8,'Art Exhibition Opening','2025-07-01 10:00:00','2025-07-01 12:00:00',1),
(8,'Technology Demonstrations','2025-07-01 13:00:00','2025-07-03 18:00:00',1),
(8,'Closing Performance','2025-07-03 19:00:00','2025-07-03 22:00:00',1),
(9,'Opening Ceremony','2025-08-20 08:00:00','2025-08-20 09:00:00',8),
(9,'Sports Competitions','2025-08-20 09:30:00','2025-08-22 17:00:00',8),
(9,'Awards Ceremony','2025-08-22 17:30:00','2025-08-22 18:00:00',8),
(10,'Career Fair Opening','2025-09-15 10:00:00','2025-09-15 10:30:00',10),
(10,'Company Presentations','2025-09-15 11:00:00','2025-09-16 15:00:00',10),
(10,'Networking Mixer','2025-09-16 15:30:00','2025-09-16 16:00:00',10),
(11,'Research Keynote','2025-10-05 09:00:00','2025-10-05 10:00:00',11),
(11,'Poster Sessions','2025-10-05 10:30:00','2025-10-06 16:00:00',11),
(11,'Closing Remarks','2025-10-06 16:30:00','2025-10-06 17:00:00',11),
(12,'Opening Address','2025-11-10 09:00:00','2025-11-10 09:30:00',12),
(12,'Symposium Sessions','2025-11-10 10:00:00','2025-11-11 15:30:00',12),
(12,'Panel Discussion','2025-11-11 15:30:00','2025-11-11 16:00:00',12),
(13,'Tech Conference Opening','2026-01-20 09:00:00','2026-01-20 09:30:00',13),
(13,'Tech Talks and Workshops','2026-01-20 10:00:00','2026-01-22 16:00:00',13),
(13,'Closing Keynote','2026-01-22 16:30:00','2026-01-22 17:00:00',13),
(14,'Pitch Competition Briefing','2026-02-15 10:00:00','2026-02-15 10:30:00',14),
(14,'Startup Pitches','2026-02-15 11:00:00','2026-02-15 16:00:00',14),
(14,'Awards and Networking','2026-02-15 16:30:00','2026-02-15 18:00:00',14),
(15,'Expo Opening','2026-03-05 09:00:00','2026-03-05 09:30:00',15),
(15,'Innovation Showcases','2026-03-05 10:00:00','2026-03-06 16:00:00',15),
(15,'Closing Ceremony','2026-03-06 16:30:00','2026-03-06 17:00:00',15),
(16,'Welcome and Introduction','2026-04-10 14:00:00','2026-04-10 14:30:00',16),
(16,'Brain Health Lectures','2026-04-10 14:30:00','2026-04-10 19:00:00',16),
(16,'Q&A Session','2026-04-10 19:00:00','2026-04-10 20:00:00',16);

INSERT INTO Performances (program_id, performance_name, performance_type, start_datetime, end_datetime) VALUES
(1,'UTD Jazz Band','Music','2024-11-15 09:30:00','2024-11-15 10:00:00'),
(4,'Leadership in Action','Speech','2024-12-05 10:00:00','2024-12-05 11:00:00'),
(7,'AI Demonstration','Technology','2025-02-20 10:00:00','2025-02-20 11:00:00'),
(10,'Science Fair Showcase','Exhibition','2025-03-10 11:00:00','2025-03-10 12:00:00'),
(13,'Neuroscience Keynote','Lecture','2025-04-05 09:30:00','2025-04-05 10:30:00'),
(16,'Political Debate','Debate','2025-05-15 14:30:00','2025-05-15 16:30:00'),
(19,'Interdisciplinary Research Presentation','Presentation','2025-06-10 10:00:00','2025-06-10 11:00:00'),
(22,'Digital Art Exhibition','Art Show','2025-07-01 13:00:00','2025-07-01 15:00:00'),
(25,'Sports Exhibition Match','Sports','2025-08-20 10:00:00','2025-08-20 11:30:00'),
(28,'Career Development Workshop','Workshop','2025-09-15 11:30:00','2025-09-15 13:00:00');

INSERT INTO Performances_Superstar (performance_id, person_id) VALUES
(1,51),(2,52),(3,53),(4,54),(5,55),(6,56),(7,57),(8,58),(9,59),(10,60);

INSERT INTO Competition (program_id, Competition_name, performance_type, start_datetime, end_datetime) VALUES
(2,'Hackathon Main Event','Coding','2024-11-15 10:30:00','2024-11-16 10:30:00'),
(8,'Startup Pitch Competition','Presentation','2025-06-10 13:00:00','2025-06-10 16:00:00'),
(11,'Science Fair Project Competition','Exhibition','2025-03-11 09:00:00','2025-03-11 17:00:00'),
(20,'Sports Tournament Finals','Sports','2025-08-22 09:00:00','2025-08-22 16:00:00'),
(26,'Research Poster Competition','Academic','2025-10-05 13:00:00','2025-10-05 16:00:00'),
(35,'Tech Innovation Challenge','Technology','2026-01-21 10:00:00','2026-01-21 18:00:00');

INSERT INTO Competition_Participants (competition_id, person_id, participants_role) VALUES
(1,26,'Keyboardist'),(1,27,'Keyboardist'),(1,28,'Keyboardist'),(1,29,'Painter'),(1,30,'Keyboardist'),(1,31,'Painter'),(1,32,'Keyboardist'),(1,33,'Painter'),
(2,34,'Magician'),(2,35,'Magician'),(2,36,'Magician'),(2,37,'Magician'),(2,38,'Magician'),(2,39,'Magician'),(2,40,'Magician'),
(3,41,'Singer'),(3,42,'Keyboardist'),(3,43,'Guitarist'),(3,44,'Drummer'),(3,45,'Violinist'),(3,46,'Singer'),(3,47,'Keyboardist'),(3,48,'Guitarist'),
(4,49,'Magician'),(4,50,'Magician'),(4,51,'Magician'),(4,52,'Magician'),(4,53,'Magician'),(4,54,'Magician'),(4,55,'Magician'),
(5,56,'Painter'),(5,57,'Painter'),(5,58,'Painter'),(5,59,'Painter'),(5,60,'Painter'),(5,61,'Painter'),(5,62,'Painter'),
(6,63,'Keyboardist'),(6,64,'Painter'),(6,65,'Keyboardist'),(6,66,'Painter'),(6,67,'Keyboardist'),(6,68,'Painter'),(6,69,'Keyboardist'),(6,70,'Painter');

INSERT INTO Prizes (competition_id, winner_person_id, prize_name, award_year, award_category) VALUES
(1,26,'Hackathon Champion',2024,'Platinum'),(1,27,'Hackathon Runner-up',2024,'Gold'),(1,28,'Hackathon Third Place',2024,'Silver'),(1,29,'Hackathon Fourth Place',2024,'Bronze'),
(2,34,'Best Startup Pitch',2025,'Platinum'),(2,35,'Most Innovative Startup',2025,'Gold'),(2,36,'Best Business Model',2025,'Silver'),(2,37,'Most Promising Startup',2025,'Bronze'),
(3,41,'Best Overall Project',2025,'Platinum'),(3,42,'Most Innovative Project',2025,'Gold'),(3,43,'Best Presentation',2025,'Silver'),(3,44,'Judges Choice Award',2025,'Bronze'),
(4,49,'Tournament Champion',2025,'Platinum'),(4,50,'Tournament Runner-up',2025,'Gold'),(4,51,'Third Place',2025,'Silver'),(4,52,'Fourth Place',2025,'Bronze'),
(5,56,'Best Research Poster',2025,'Platinum'),(5,57,'Most Innovative Research',2025,'Gold'),(5,58,'Best Methodology',2025,'Silver'),(5,59,'Best Presentation',2025,'Bronze'),
(6,63,'Most Innovative Technology',2026,'Platinum'),(6,64,'Best Technical Implementation',2026,'Gold'),(6,65,'Most Impactful Innovation',2026,'Silver'),(6,66,'Best Emerging Technology',2026,'Bronze');

INSERT INTO Lost_And_Found (event_id, item_description, claimed, reported_timestamp, claimed_timestamp, claimer_person_id) VALUES
(1,'Black laptop bag',FALSE,'2024-11-15 14:30:00',NULL,NULL),(1,'Blue water bottle',TRUE,'2024-11-15 16:45:00','2024-11-15 18:20:00',30),
(2,'Red smartphone',FALSE,'2024-12-05 11:15:00',NULL,NULL),(2,'Gray sweater',TRUE,'2024-12-05 13:30:00','2024-12-05 15:45:00',35),
(3,'Silver wristwatch',FALSE,'2025-02-20 10:20:00',NULL,NULL),(3,'Brown leather wallet',TRUE,'2025-02-20 14:10:00','2025-02-20 16:30:00',40),
(4,'Purple umbrella',FALSE,'2025-03-10 11:45:00',NULL,NULL),(4,'Black reading glasses',TRUE,'2025-03-11 09:30:00','2025-03-11 12:15:00',45),
(5,'White AirPods case',FALSE,'2025-04-05 13:20:00',NULL,NULL),(5,'Green notebook',TRUE,'2025-04-06 10:45:00','2025-04-06 14:00:00',50),
(6,'Blue backpack',FALSE,'2025-05-15 15:30:00',NULL,NULL),(6,'Black USB drive',TRUE,'2025-05-15 17:20:00','2025-05-15 18:45:00',55),
(7,'Red tablet',FALSE,'2025-06-10 11:10:00',NULL,NULL),(7,'Gray laptop charger',TRUE,'2025-06-10 14:30:00','2025-06-10 16:15:00',60),
(8,'Yellow raincoat',FALSE,'2025-07-01 12:40:00',NULL,NULL),(8,'Black camera bag',TRUE,'2025-07-02 09:15:00','2025-07-02 11:30:00',65),
(9,'Blue duffel bag',FALSE,'2025-08-20 10:50:00',NULL,NULL),(9,'White baseball cap',TRUE,'2025-08-21 13:25:00','2025-08-21 15:40:00',70),
(10,'Brown briefcase',FALSE,'2025-09-15 11:35:00',NULL,NULL),(10,'Silver pen set',TRUE,'2025-09-15 14:50:00','2025-09-15 16:20:00',75);

INSERT INTO Vendor_Payments (vendor_person_id, event_id, customer_person_id, amount, payment_date, description) VALUES
(76,1,26,50.00,'2024-11-15 13:30:00','Tech gadget purchase'),(77,2,27,75.50,'2024-12-05 12:45:00','Catering service'),
(78,3,28,30.00,'2025-02-20 14:15:00','Event merchandise'),(79,4,29,100.00,'2025-03-10 11:30:00','Photography package'),
(80,5,30,150.00,'2025-04-05 15:00:00','Audio equipment rental'),(81,6,31,80.00,'2025-05-15 16:30:00','Decorations purchase'),
(82,7,32,200.00,'2025-06-10 10:45:00','Security services'),(83,8,33,45.00,'2025-07-01 13:15:00','Transportation fee'),
(84,9,34,25.00,'2025-08-20 11:00:00','Printing services'),(85,10,35,90.00,'2025-09-15 14:30:00','Event staff hire'),
(86,11,36,120.00,'2025-10-05 12:00:00','Tech support services'),(87,12,37,65.00,'2025-11-10 15:45:00','Catering - special dietary meals'),
(88,13,38,40.00,'2026-01-20 11:30:00','Custom event badges'),(89,14,39,110.00,'2026-02-15 13:00:00','Professional headshots'),
(90,15,40,180.00,'2026-03-05 16:15:00','Stage lighting setup'),(91,16,41,70.00,'2026-04-10 10:30:00','Floral arrangements'),
(92,1,42,95.00,'2024-11-15 14:45:00','VIP area security'),(93,2,43,55.00,'2024-12-05 11:15:00','Shuttle service'),
(94,3,44,35.00,'2025-02-20 15:30:00','Event program printing'),(95,4,45,85.00,'2025-03-10 12:45:00','On-site tech support');

INSERT INTO Salary (staff_person_id, event_id, salary_amount, payment_date, description) VALUES
(1,1,500.00,'2024-11-16 19:00:00','Event Manager - UTD Comets Hackathon'),(2,1,200.00,'2024-11-16 19:00:00','Security - UTD Comets Hackathon'),
(3,1,100.00,'2024-11-16 19:00:00','Volunteer - UTD Comets Hackathon'),(4,1,150.00,'2024-11-16 19:00:00','Janitorial - UTD Comets Hackathon'),
(5,1,250.00,'2024-11-16 19:00:00','First Aid - UTD Comets Hackathon'),(6,2,550.00,'2024-12-05 18:00:00','Event Manager - Business Leadership Symposium'),
(7,2,220.00,'2024-12-05 18:00:00','Security - Business Leadership Symposium'),(8,2,110.00,'2024-12-05 18:00:00','Volunteer - Business Leadership Symposium'),
(9,3,600.00,'2025-02-21 17:00:00','Event Manager - Engineering Innovation Expo'),(10,3,240.00,'2025-02-21 17:00:00','Security - Engineering Innovation Expo'),
(11,3,160.00,'2025-02-21 17:00:00','Janitorial - Engineering Innovation Expo'),(12,4,650.00,'2025-03-12 17:00:00','Event Manager - Science Fair Extravaganza'),
(13,4,270.00,'2025-03-12 17:00:00','First Aid - Science Fair Extravaganza'),(14,4,120.00,'2025-03-12 17:00:00','Volunteer - Science Fair Extravaganza'),
(15,5,700.00,'2025-04-07 18:00:00','Event Manager - Brain and Behavior Conference'),(16,5,280.00,'2025-04-07 18:00:00','Security - Brain and Behavior Conference'),
(17,6,550.00,'2025-05-15 21:00:00','Event Manager - Policy and Politics Debate'),(18,6,170.00,'2025-05-15 21:00:00','Janitorial - Policy and Politics Debate'),
(19,7,600.00,'2025-06-11 18:00:00','Event Manager - Interdisciplinary Research Symposium'),(20,7,130.00,'2025-06-11 18:00:00','Volunteer - Interdisciplinary Research Symposium'),
(21,8,750.00,'2025-07-03 23:00:00','Event Manager - UTD Arts Festival'),(22,8,300.00,'2025-07-03 23:00:00','Security - UTD Arts Festival'),
(23,9,800.00,'2025-08-22 19:00:00','Event Manager - Comet Sports Invitational'),(24,9,320.00,'2025-08-22 19:00:00','First Aid - Comet Sports Invitational'),
(25,10,650.00,'2025-09-16 17:00:00','Event Manager - UTD Career Expo');

INSERT INTO Performer_Remuneration (person_id, performance_id, salary_amount, payment_date, description) VALUES
(51,1,1000.00,'2024-11-15 11:00:00','UTD Jazz Band performance'),(52,2,1500.00,'2024-12-05 12:00:00','Leadership in Action speech'),
(53,3,1200.00,'2025-02-20 12:00:00','AI Demonstration'),(54,4,800.00,'2025-03-10 13:00:00','Science Fair Showcase'),
(55,5,2000.00,'2025-04-05 11:30:00','Neuroscience Keynote'),(56,6,1800.00,'2025-05-15 17:30:00','Political Debate moderation'),
(57,7,1300.00,'2025-06-10 12:00:00','Interdisciplinary Research Presentation'),(58,8,1600.00,'2025-07-01 16:00:00','Digital Art Exhibition curation'),
(59,9,1100.00,'2025-08-20 12:30:00','Sports Exhibition Match commentary'),(60,10,900.00,'2025-09-15 14:00:00','Career Development Workshop');

INSERT INTO Sponsorships (sponsor_id, event_id, amount, payment_date, description) VALUES
(66,1,10000.00,'2024-11-01 09:00:00','Sponsorship for UTD Comets Hackathon'),
(67,2,7500.00,'2024-11-15 10:00:00','Sponsorship for Business Leadership Symposium'),
(68,3,5000.00,'2025-01-20 11:00:00','Sponsorship for Engineering Innovation Expo'),
(69,4,15000.00,'2025-02-15 09:30:00','Sponsorship for Science Fair Extravaganza'),
(70,5,8000.00,'2025-03-01 10:30:00','Sponsorship for Brain and Behavior Conference'),
(71,6,6000.00,'2025-04-15 11:30:00','Sponsorship for Policy and Politics Debate'),
(72,7,12000.00,'2025-05-01 09:00:00','Sponsorship for Interdisciplinary Research Symposium'),
(73,8,9000.00,'2025-06-01 10:00:00','Sponsorship for UTD Arts Festival'),
(74,9,5500.00,'2025-07-15 11:00:00','Sponsorship for Comet Sports Invitational'),
(75,10,20000.00,'2025-08-01 09:30:00','Sponsorship for UTD Career Expo');

INSERT INTO Food_Truck_Orders (truck_id, customer_person_id, amount, payment_date) VALUES
(1,26,9.98,'2024-11-15 12:30:00'),(2,27,8.98,'2024-11-15 13:15:00'),(3,28,14.48,'2024-12-05 11:45:00'),
(4,29,11.47,'2024-12-05 12:30:00'),(5,30,18.47,'2025-02-20 13:00:00'),(6,31,15.97,'2025-02-20 14:15:00'),
(7,32,14.97,'2025-03-10 12:00:00'),(8,33,16.48,'2025-03-10 13:30:00'),(9,34,15.47,'2025-04-05 11:15:00'),
(10,35,17.47,'2025-04-05 12:45:00'),(11,36,20.47,'2025-05-15 13:30:00'),(12,37,19.97,'2025-05-15 14:45:00'),
(13,38,18.97,'2025-06-10 12:15:00'),(14,39,21.47,'2025-06-10 13:45:00'),(15,40,16.48,'2025-07-01 11:30:00'),
(16,41,24.97,'2025-07-01 12:45:00'),(17,42,19.47,'2025-08-20 13:00:00'),(18,43,24.97,'2025-08-20 14:15:00'),
(19,44,28.47,'2025-09-15 12:30:00'),(20,45,14.47,'2025-09-15 13:45:00'),(1,46,12.97,'2025-10-05 11:45:00'),
(2,47,14.47,'2025-10-05 13:00:00'),(3,48,20.47,'2025-11-10 12:15:00'),(4,49,12.47,'2025-11-10 13:30:00'),
(5,50,21.47,'2026-01-20 11:30:00'),(6,51,17.47,'2026-01-20 12:45:00'),(7,52,16.97,'2026-02-15 13:15:00'),
(8,53,15.48,'2026-02-15 14:30:00'),(9,54,19.47,'2026-03-05 12:00:00'),(10,55,20.47,'2026-03-05 13:15:00');

INSERT INTO Food_Truck_Orders_Details (quantity, orders_id, menu_id) VALUES
(2,1,1),(1,1,3),(1,2,5),(1,2,7),(1,3,9),(1,3,10),(1,3,11),(2,4,13),(1,4,16),
(1,5,17),(2,5,18),(1,5,19),(1,6,21),(2,6,22),(1,6,23),(1,7,25),(1,7,26),(1,7,27),
(1,8,29),(1,8,30),(1,8,32),(1,9,33),(1,9,34),(1,9,35),(1,10,37),(1,10,38),(1,10,40),
(1,11,41),(1,11,42),(1,11,44),(1,12,45),(1,12,46),(1,12,47),(1,13,49),(1,13,50),(1,13,51),
(1,14,53),(1,14,54),(1,14,55),(1,15,57),(1,15,58),(1,15,60),(2,16,61),(1,16,63),
(1,17,65),(1,17,66),(1,17,67),(1,18,69),(1,18,70),(1,18,71),(1,19,73),(1,19,74),(1,19,76),
(2,20,77),(2,20,78),(1,20,79),(1,21,2),(2,21,4),(1,21,3),(1,22,6),(1,22,8),(1,22,7),
(2,23,11),(1,23,9),(1,23,12),(2,24,14),(1,24,13),(1,25,17),(2,25,18),(1,25,19),(1,25,20),
(1,26,21),(2,26,22),(1,26,23),(1,26,24),(1,27,25),(1,27,26),(1,27,27),(1,27,28),
(1,28,29),(1,28,31),(1,28,32),(1,29,33),(1,29,35),(1,29,36),(1,29,34),(1,30,37),(1,30,38),(1,30,40),(1,30,13);


-- ============================================================
-- SECTION 7B: VERIFY ALL TABLE DATA
-- Run these to confirm every table populated correctly
-- ============================================================

SELECT * FROM Booths;
SELECT * FROM Competition;
SELECT * FROM Competition_Participants;
SELECT * FROM EventProgram;
SELECT * FROM EventRecord;
SELECT * FROM Food_Menu;
SELECT * FROM Food_Truck;
SELECT * FROM Food_Truck_Orders;
SELECT * FROM Food_Truck_Orders_Details;
SELECT * FROM Locations;
SELECT * FROM Lost_And_Found;
SELECT * FROM Payments;
SELECT * FROM Performances;
SELECT * FROM Performances_Superstar;
SELECT * FROM Performer_Remuneration;
SELECT * FROM Person;
SELECT * FROM Person_Attendee;
SELECT * FROM Person_Sponsor;
SELECT * FROM Person_Staff;
SELECT * FROM Person_Vendor;
SELECT * FROM Prizes;
SELECT * FROM Salary;
SELECT * FROM Sponsorships;
SELECT * FROM Vendor_Payments;
SELECT * FROM Venue;

-- ============================================================
-- SECTION 8: TRIGGERS
-- ============================================================

DELIMITER //

-- Trigger 1: Auto-update sponsor contribution amount and tier
CREATE TRIGGER sponsor_update
AFTER INSERT ON Sponsorships
FOR EACH ROW
BEGIN
    DECLARE ca_variable DECIMAL(10,2) DEFAULT 0;
    UPDATE Person_Sponsor P
    SET P.contribution_amount = P.contribution_amount + NEW.amount
    WHERE person_id = NEW.sponsor_id AND event_id = NEW.event_id;

    INSERT INTO Payments (amount, payment_date, payment_status, payment_type, sponsorship_id)
    VALUES (NEW.amount, NEW.payment_date, 'CREDIT', 'SPONSOR', NEW.sponsorship_id);

    SELECT contribution_amount INTO ca_variable
    FROM Person_Sponsor
    WHERE person_id = NEW.sponsor_id AND event_id = NEW.event_id;

    IF (ca_variable >= 20000) THEN
        UPDATE Person_Sponsor SET tier_name = 'Diamond' WHERE person_id = NEW.sponsor_id AND event_id = NEW.event_id;
    ELSEIF (ca_variable >= 15000) THEN
        UPDATE Person_Sponsor SET tier_name = 'Platinum' WHERE person_id = NEW.sponsor_id AND event_id = NEW.event_id;
    ELSEIF (ca_variable >= 10000) THEN
        UPDATE Person_Sponsor SET tier_name = 'Gold' WHERE person_id = NEW.sponsor_id AND event_id = NEW.event_id;
    ELSE
        UPDATE Person_Sponsor SET tier_name = 'Silver' WHERE person_id = NEW.sponsor_id AND event_id = NEW.event_id;
    END IF;
END //

-- Trigger 2: Auto-insert into Payments after Food_Truck_Orders
CREATE TRIGGER Payments_after_order
AFTER INSERT ON Food_Truck_Orders
FOR EACH ROW
BEGIN
    INSERT INTO Payments (amount, payment_date, payment_status, payment_type, orders_id)
    VALUES (NEW.amount, NEW.payment_date, 'CREDIT', 'FOOD_TRUCK', NEW.orders_id);
END //

-- Trigger 3: Auto-insert into Payments after Performer_Remuneration
CREATE TRIGGER after_performer_remuneration_insert
AFTER INSERT ON Performer_Remuneration
FOR EACH ROW
BEGIN
    INSERT INTO Payments (amount, payment_date, payment_status, payment_type, remuneration_id)
    VALUES (NEW.salary_amount, NEW.payment_date, 'DEBIT', 'REMUNERATION', NEW.remuneration_id);
END //

-- Trigger 4: Auto-insert into Payments after Vendor_Payments
CREATE TRIGGER after_vendor_payment_insert
AFTER INSERT ON Vendor_Payments
FOR EACH ROW
BEGIN
    INSERT INTO Payments (amount, payment_date, payment_status, payment_type, vendor_payment_id)
    VALUES (NEW.amount, NEW.payment_date, 'DEBIT', 'VENDOR', NEW.vendor_payment_id);
END //

-- Trigger 5: Auto-insert into Payments after Salary
CREATE TRIGGER after_salary_insert
AFTER INSERT ON Salary
FOR EACH ROW
BEGIN
    INSERT INTO Payments (amount, payment_date, payment_status, payment_type, salary_id)
    VALUES (NEW.salary_amount, NEW.payment_date, 'CREDIT', 'SALARY', NEW.salary_id);
END //

-- Trigger 6: Prevent double-booking at same location and time
CREATE TRIGGER trg_prevent_double_bookings
BEFORE INSERT ON EventRecord
FOR EACH ROW
BEGIN
    DECLARE overlap_count INT DEFAULT 0;
    SELECT COUNT(*) INTO overlap_count
    FROM EventRecord
    WHERE loc_id = NEW.loc_id
      AND ((NEW.start_datetime BETWEEN start_datetime AND end_datetime)
        OR (NEW.end_datetime  BETWEEN start_datetime AND end_datetime)
        OR (start_datetime BETWEEN NEW.start_datetime AND NEW.end_datetime));
    IF overlap_count > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Schedule conflict: Another event is already booked at this location for the specified time.';
    END IF;
END //

DELIMITER ;

-- ============================================================
-- SECTION 9: STORED PROCEDURES
-- ============================================================

DELIMITER //

-- Procedure 1: Register a new attendee for an event
CREATE PROCEDURE RegisterAttendeeForEvent(
    IN attendeeId INT, IN eventId INT, IN ticketType VARCHAR(100),
    IN firstName VARCHAR(255), IN lastName VARCHAR(255),
    IN phoneNumber VARCHAR(10), IN email VARCHAR(255)
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Person WHERE person_id = attendeeId) THEN
        INSERT INTO Person (person_id, person_name, phone_number, email)
        VALUES (attendeeId, CONCAT(firstName,' ',lastName), phoneNumber, email);
    END IF;
    INSERT INTO Person_Attendee (person_id, event_id, ticket_type)
    VALUES (attendeeId, eventId, ticketType);
END //

-- Procedure 2: Update menu item price (max 20% increase)
CREATE PROCEDURE UpdateMenuPrices(IN p_menu_id INT, IN p_new_price DECIMAL(10,2))
BEGIN
    DECLARE v_old_price DECIMAL(10,2);
    DECLARE v_max_price DECIMAL(10,2);
    SELECT price INTO v_old_price FROM Food_Menu WHERE menu_id = p_menu_id;
    SET v_max_price = v_old_price * 1.20;
    IF p_new_price <= v_max_price THEN
        UPDATE Food_Menu SET price = p_new_price WHERE menu_id = p_menu_id;
    ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'New price exceeds the allowed 20% increase limit';
    END IF;
END //

-- Procedure 3: Generate event financial report
CREATE PROCEDURE GenerateEventFinancialReport(IN p_event_id INT)
BEGIN
    DECLARE v_event_name VARCHAR(255);
    DECLARE v_ticket_revenue DECIMAL(10,2);
    DECLARE v_sponsorship_revenue DECIMAL(10,2);
    DECLARE v_vendor_revenue DECIMAL(10,2);
    DECLARE v_total_revenue DECIMAL(10,2);

    SELECT event_name INTO v_event_name FROM EventRecord WHERE event_id = p_event_id;
    SELECT COALESCE(SUM(CASE WHEN ticket_type='VIP' THEN 100 ELSE 50 END),0) INTO v_ticket_revenue
    FROM Person_Attendee WHERE event_id = p_event_id;
    SELECT COALESCE(SUM(contribution_amount),0) INTO v_sponsorship_revenue
    FROM Person_Sponsor WHERE event_id = p_event_id;
    SELECT COUNT(*)*500 INTO v_vendor_revenue FROM Person_Vendor WHERE event_id = p_event_id;
    SET v_total_revenue = v_ticket_revenue + v_sponsorship_revenue + v_vendor_revenue;

    SELECT v_event_name AS 'Event Name', v_ticket_revenue AS 'Ticket Revenue',
           v_sponsorship_revenue AS 'Sponsorship Revenue', v_vendor_revenue AS 'Vendor Revenue',
           v_total_revenue AS 'Total Revenue';

    SELECT p.person_name AS 'Sponsor Name', ps.contribution_amount AS 'Contribution Amount', ps.tier_name AS 'Sponsorship Tier'
    FROM Person_Sponsor ps JOIN Person p ON ps.person_id = p.person_id
    WHERE ps.event_id = p_event_id ORDER BY ps.contribution_amount DESC LIMIT 5;
END //

-- Procedure 4: Generate event performance report
CREATE PROCEDURE GenerateEventPerformanceReport(IN p_event_id INT)
BEGIN
    DECLARE v_event_name VARCHAR(255);
    DECLARE v_total_performances INT;
    DECLARE v_total_competitions INT;
    DECLARE v_total_participants INT;

    SELECT event_name INTO v_event_name FROM EventRecord WHERE event_id = p_event_id;
    SELECT COUNT(*) INTO v_total_performances FROM Performances p JOIN EventProgram pr ON p.program_id = pr.program_id WHERE pr.event_id = p_event_id;
    SELECT COUNT(*) INTO v_total_competitions FROM Competition c JOIN EventProgram pr ON c.program_id = pr.program_id WHERE pr.event_id = p_event_id;
    SELECT COUNT(DISTINCT person_id) INTO v_total_participants FROM (
        SELECT ps.person_id FROM Performances_Superstar ps JOIN Performances p ON ps.performance_id = p.performance_id JOIN EventProgram pr ON p.program_id = pr.program_id WHERE pr.event_id = p_event_id
        UNION
        SELECT cp.person_id FROM Competition_Participants cp JOIN Competition c ON cp.competition_id = c.competition_id JOIN EventProgram pr ON c.program_id = pr.program_id WHERE pr.event_id = p_event_id
    ) AS all_participants;

    -- Summary output
    SELECT
        v_event_name AS 'Event Name',
        v_total_performances AS 'Total Performances',
        v_total_competitions AS 'Total Competitions',
        v_total_participants AS 'Total Participants';

    -- List details of each performance
    SELECT
        p.performance_name AS 'Performance Name',
        p.performance_type AS 'Performance Type',
        p.start_datetime   AS 'Start Time',
        p.end_datetime     AS 'End Time',
        COUNT(ps.person_id) AS 'Number of Performers'
    FROM Performances p
    JOIN EventProgram pr ON p.program_id = pr.program_id
    LEFT JOIN Performances_Superstar ps ON p.performance_id = ps.performance_id
    WHERE pr.event_id = p_event_id
    GROUP BY p.performance_id
    ORDER BY p.start_datetime;

    -- List details of each competition
    SELECT
        c.Competition_name AS 'Competition Name',
        c.performance_type AS 'Competition Type',
        c.start_datetime   AS 'Start Time',
        c.end_datetime     AS 'End Time',
        COUNT(cp.person_id) AS 'Number of Participants'
    FROM Competition c
    JOIN EventProgram pr ON c.program_id = pr.program_id
    LEFT JOIN Competition_Participants cp ON c.competition_id = cp.competition_id
    WHERE pr.event_id = p_event_id
    GROUP BY c.competition_id
    ORDER BY c.start_datetime;
END //

-- Procedure 5: Mark a lost item as claimed
-- Fix: use unambiguous column reference to avoid shadowing with parameter name
CREATE PROCEDURE claim_lost_item(IN p_item_id INT, IN p_claimer_person_id INT)
BEGIN
    UPDATE Lost_And_Found laf
    SET laf.claimed = TRUE,
        laf.claimed_timestamp = NOW(),
        laf.claimer_person_id = p_claimer_person_id
    WHERE laf.item_id = p_item_id AND laf.claimed = FALSE;
    SELECT * FROM Lost_And_Found WHERE Lost_And_Found.item_id = p_item_id;
END //

DELIMITER ;

-- ============================================================
-- SECTION 10: FUNCTIONS
-- ============================================================

DELIMITER //

-- Function 1: Check ticket availability (AreTicketsAvailableorNot)
-- Fix applied: NOT DETERMINISTIC READS SQL DATA (was incorrectly DETERMINISTIC)
-- Fix applied: uses actual Venue.capacity via JOIN instead of hardcoded value
CREATE FUNCTION AreTicketsAvailableorNot(eventId INT, requestedTickets INT)
RETURNS BOOLEAN NOT DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE available    BOOLEAN;
    DECLARE maxCapacity  INT;
    DECLARE attendeeCount INT;
    SELECT MAX(v.capacity) INTO maxCapacity
    FROM Venue v
    JOIN EventRecord e ON v.loc_id = e.loc_id
    WHERE e.event_id = eventId;
    SELECT COUNT(*) INTO attendeeCount
    FROM Person_Attendee WHERE event_id = eventId;
    SET available = ((maxCapacity - attendeeCount) >= requestedTickets);
    RETURN available;
END //

-- Function 2: Check venue availability
CREATE FUNCTION IsVenueAvailable(venueId INT, startDateTime DATETIME, endDateTime DATETIME)
RETURNS BOOLEAN DETERMINISTIC
BEGIN
    DECLARE isAvailable BOOLEAN;
    SET isAvailable = NOT EXISTS (
        SELECT 1 FROM EventProgram
        WHERE venue_id = venueId
          AND ((start_datetime <= startDateTime AND end_datetime > startDateTime)
            OR (start_datetime < endDateTime AND end_datetime >= endDateTime)
            OR (start_datetime >= startDateTime AND end_datetime <= endDateTime))
    );
    RETURN isAvailable;
END //

-- Function 3: Calculate total food truck revenue for an event
CREATE FUNCTION CalculateFoodTruckRevenue(p_event_id INT)
RETURNS DECIMAL(10,2) NOT DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE v_total_revenue DECIMAL(10,2);
    SELECT COALESCE(SUM(fto.amount),0) INTO v_total_revenue
    FROM Food_Truck_Orders fto JOIN Food_Truck ft ON fto.truck_id = ft.truck_id
    WHERE ft.event_id = p_event_id;
    RETURN v_total_revenue;
END //

-- Function 4: Calculate total program duration in minutes for an event
CREATE FUNCTION CalculateEventTotalProgramDuration(p_event_id INT)
RETURNS INT NOT DETERMINISTIC READS SQL DATA
BEGIN
    DECLARE total_duration INT;
    SELECT SUM(TIMESTAMPDIFF(MINUTE, start_datetime, end_datetime)) INTO total_duration
    FROM EventProgram WHERE event_id = p_event_id;
    RETURN COALESCE(total_duration, 0);
END //

-- Function 5: Check food menu item availability at a truck
CREATE FUNCTION check_menu_item_availability(input_truck_id INT, input_item_name VARCHAR(255))
RETURNS VARCHAR(50) DETERMINISTIC
BEGIN
    DECLARE availability_status VARCHAR(50);
    SELECT CASE WHEN is_available = TRUE THEN 'Available' ELSE 'Unavailable' END INTO availability_status
    FROM Food_Menu fm JOIN Food_Truck ft ON fm.truck_id = ft.truck_id
    WHERE ft.truck_id = input_truck_id AND fm.item_name = input_item_name LIMIT 1;
    IF availability_status IS NULL THEN SET availability_status = 'Item Not Found'; END IF;
    RETURN availability_status;
END //

DELIMITER ;

-- ============================================================
-- SECTION 11: SAMPLE COMPLEX QUERIES
-- ============================================================

-- Q1: Venue and location for each program
SELECT p.program_name, v.venue_name, l.location_name, l.address
FROM EventProgram p
JOIN Venue v ON v.venue_id = p.venue_id
JOIN Locations l ON v.loc_id = l.loc_id;

-- Q2: Food menu items with truck and location details
SELECT fm.item_name, fm.price, fm.description, ft.truck_name, ft.cuisine_type, ft.location_description, l.address
FROM Food_Menu fm
JOIN Food_Truck ft ON fm.truck_id = ft.truck_id
JOIN EventRecord e ON ft.event_id = e.event_id
JOIN Locations l ON l.loc_id = e.loc_id;

-- Q3: Top 5 events by attendee count with event manager names
SELECT e.event_name, COUNT(pa.person_id) AS attendee_count, p.person_name AS event_manager
FROM EventRecord e
LEFT JOIN Person_Attendee pa ON e.event_id = pa.event_id
LEFT JOIN Person_Staff ps ON e.event_id = ps.event_id AND ps.staff_type = 'Event Manager'
LEFT JOIN Person p ON ps.person_id = p.person_id
GROUP BY e.event_id, e.event_name, p.person_name
ORDER BY attendee_count DESC LIMIT 5;

-- Q4: All performances with programs, events, and performers
SELECT e.event_name, p.program_name, perf.performance_name, perf.performance_type,
       perf.start_datetime, perf.end_datetime,
       GROUP_CONCAT(pers.person_name SEPARATOR ', ') AS performers
FROM Performances perf
JOIN EventProgram p ON perf.program_id = p.program_id
JOIN EventRecord e ON p.event_id = e.event_id
LEFT JOIN Performances_Superstar ps ON perf.performance_id = ps.performance_id
LEFT JOIN Person pers ON ps.person_id = pers.person_id
GROUP BY perf.performance_id, e.event_name, p.program_name, perf.performance_name,
         perf.performance_type, perf.start_datetime, perf.end_datetime
ORDER BY e.event_name, p.program_name, perf.start_datetime;

-- Q5: Unclaimed lost items
SELECT laf.item_id, laf.item_description, laf.reported_timestamp, e.event_name
FROM Lost_And_Found laf
JOIN EventRecord e ON laf.event_id = e.event_id
WHERE laf.claimed = FALSE;

-- Q6: Vendors with booth details
SELECT e.event_name, pv.company_name, pv.vendor_type, b.booth_size, b.location_description, b.setup_time, b.teardown_time
FROM EventRecord e
JOIN Person_Vendor pv ON e.event_id = pv.event_id
JOIN Booths b ON pv.person_id = b.person_vendor_id AND pv.event_id = b.event_id
ORDER BY e.event_name, pv.company_name;

-- Q7: Full event analytics report
SELECT
    e.event_id, e.event_name, e.event_organizer,
    l.location_name AS Location,
    e.start_datetime AS Event_Start, e.end_datetime AS Event_End,
    TIMEDIFF(e.end_datetime, e.start_datetime) AS Event_Duration,
    SEC_TO_TIME(SUM(TIMESTAMPDIFF(SECOND, p.start_datetime, p.end_datetime))) AS Total_Program_Duration,
    COUNT(DISTINCT p.program_id) AS Program_Count,
    v.venue_name, MAX(v.capacity) AS Venue_Capacity,
    COUNT(DISTINCT ps.person_id) AS Staff_Count,
    GROUP_CONCAT(DISTINCT p.program_name ORDER BY p.start_datetime SEPARATOR ', ') AS Program_List,
    GROUP_CONCAT(DISTINCT CONCAT(pr.person_name, ' (', ps.staff_type, ')') SEPARATOR ', ') AS Staff_List,
    ROUND((COUNT(ps.person_id) / MAX(v.capacity)) * 100, 2) AS Venue_Utilization_Percentage,
    MIN(p.start_datetime) AS First_Program_Start,
    MAX(p.end_datetime) AS Last_Program_End
FROM EventRecord e
JOIN Locations l ON e.loc_id = l.loc_id
LEFT JOIN EventProgram p ON e.event_id = p.event_id
LEFT JOIN Venue v ON p.venue_id = v.venue_id
LEFT JOIN Person_Staff ps ON e.event_id = ps.event_id
LEFT JOIN Person pr ON ps.person_id = pr.person_id
GROUP BY e.event_id, e.event_name, e.event_organizer, l.location_name, v.venue_name
ORDER BY e.start_datetime
LIMIT 0, 1000;

-- Q8: Competition winners and participation summary
SELECT
    P.person_name        AS Winner_Name,
    Pr.prize_name        AS Prize_Name,
    Pr.award_year        AS Award_Year,
    E.event_name         AS Event_Name,
    E.event_organizer    AS Organizer,
    Prog.program_name    AS Program_Name,
    C.Competition_name   AS Competition_Name,
    COUNT(CP.person_id)  AS Total_Participants
FROM Prizes Pr
JOIN Person P ON Pr.winner_person_id = P.person_id
JOIN Competition C ON Pr.competition_id = C.competition_id
JOIN EventProgram Prog ON C.program_id = Prog.program_id
JOIN EventRecord E ON Prog.event_id = E.event_id
JOIN Competition_Participants CP ON C.competition_id = CP.competition_id
GROUP BY Pr.prize_id, P.person_name, Pr.prize_name, Pr.award_year,
         E.event_name, E.event_organizer, Prog.program_name, C.Competition_name
ORDER BY Pr.award_year DESC, E.event_name, Prog.program_name, C.Competition_name;

-- Q9: Lost and found status with claimer details
SELECT E.event_name, L.item_description, L.claimed, P.person_name AS claimer_name,
       L.reported_timestamp, L.claimed_timestamp
FROM Lost_And_Found L
JOIN EventRecord E ON L.event_id = E.event_id
LEFT JOIN Person P ON L.claimer_person_id = P.person_id
ORDER BY E.event_name, L.reported_timestamp;

-- Q10: Sponsor contributions and tiers
SELECT P.person_name AS sponsor_name, E.event_name, PS.contribution_amount, PS.tier_name
FROM Person_Sponsor PS
JOIN Person P ON PS.person_id = P.person_id
JOIN EventRecord E ON PS.event_id = E.event_id
ORDER BY E.event_name, P.person_name;

-- Q11: Competition participants with roles and prize details
SELECT C.Competition_name, P.person_name AS participant_name, CP.participants_role,
       PR.prize_name, PR.award_year, PR.award_category
FROM Competition C
JOIN Competition_Participants CP ON C.competition_id = CP.competition_id
JOIN Person P ON CP.person_id = P.person_id
LEFT JOIN Prizes PR ON C.competition_id = PR.competition_id AND P.person_id = PR.winner_person_id
ORDER BY C.Competition_name, CP.participants_role;

-- ============================================================
-- SECTION 12: SAMPLE PROCEDURE & FUNCTION CALLS
-- ============================================================

CALL RegisterAttendeeForEvent(10007, 4, 'VIP', 'John', 'Doe', '1234567890', 'john.doe@example.com');
CALL UpdateMenuPrices(1, 3.50);
CALL GenerateEventFinancialReport(2);
CALL GenerateEventPerformanceReport(1);

SELECT AreTicketsAvailableorNot(1, 5) AS tickets_available;
SELECT IsVenueAvailable(3, '2024-12-01 09:00:00', '2024-12-01 12:00:00') AS venue_available;
SELECT event_name, CalculateFoodTruckRevenue(event_id) AS food_truck_revenue FROM EventRecord WHERE event_id = 3;
SELECT event_name, CalculateEventTotalProgramDuration(event_id) AS total_program_duration_minutes FROM EventRecord;
SELECT check_menu_item_availability(2, 'Apple Pie') AS item_status;

SET SQL_SAFE_UPDATES = 1;