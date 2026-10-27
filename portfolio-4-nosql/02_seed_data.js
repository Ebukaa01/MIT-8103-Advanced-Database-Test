// =====================================================================
// Portfolio 4 - Step 2: seed MongoDB for the same 5,000 EquityPay customers
// Usage: mongosh "$MONGODB_URI" --file portfolio-4-nosql/02_seed_data.js
// =====================================================================

const nosql = db.getSiblingDB('equitypay_nosql');
const CUSTOMERS = 5000;
const EVENTS = 100000;

print('Starting data seeding for equitypay_nosql...');

// Clean existing records before reseeding
print('Clearing existing data...');
nosql.kyc_profiles.deleteMany({});
nosql.audit_events.deleteMany({});

// ---------------------------------------------------------------------
// 1. Seed kyc_profiles (5,000 Customers matching PostgreSQL customers)
// ---------------------------------------------------------------------
print('Seeding 5,000 kyc_profiles in batches...');

const docTypes = ['BVN', 'NIN', 'PASSPORT', 'DRIVERS_LICENCE', 'UTILITY_BILL'];
const statuses = ['VERIFIED', 'VERIFIED', 'VERIFIED', 'PENDING', 'REJECTED'];

const kycBatch = [];
const now = new Date();

for (let id = 1; id <= CUSTOMERS; id++) {
  // Deterministic tier distribution: Tier 1 (~50%), Tier 2 (~30%), Tier 3 (~20%)
  const tier = (id % 10 < 5) ? 1 : (id % 10 < 8) ? 2 : 3;
  const status = statuses[id % statuses.length];

  const docs = [
    { type: 'BVN', number: '22' + String(100000000 + id) }
  ];

  if (tier >= 2) {
    docs.push({ type: 'NIN', number: '11' + String(100000000 + id) });
  }

  if (tier === 3) {
    docs.push({ 
      type: (id % 2 === 0) ? 'UTILITY_BILL' : 'PASSPORT', 
      number: 'DOC-' + String(900000 + id) 
    });
  }

  const createdAt = new Date(now.getTime() - (id * 15 * 60 * 1000)); // Staggered creation times

  kycBatch.push({
    customer_id: id,
    tier: tier,
    status: status,
    documents: docs,
    created_at: createdAt
  });

  // Batch insert every 1,000 records
  if (kycBatch.length === 1000 || id === CUSTOMERS) {
    nosql.kyc_profiles.insertMany(kycBatch);
    kycBatch.length = 0;
  }
}

print('-> kyc_profiles insertion complete.');

// ---------------------------------------------------------------------
// 2. Seed audit_events (100,000 High-Volume Time-Series Events)
// ---------------------------------------------------------------------
print('Seeding 100,000 audit_events in batches of 5,000...');

const eventTypes = [
  'LOGIN_SUCCESS', 
  'LOGIN_SUCCESS', 
  'LOGIN_FAILED', 
  'TRANSFER_INITIATED', 
  'TRANSFER_INITIATED', 
  'PIN_CHANGED', 
  'KYC_UPGRADED', 
  'FRAUD_FLAG'
];

const devices = ['iOS', 'Android', 'Web Browser'];
const ips = ['102.89.23.', '197.210.45.', '41.203.11.', '105.112.78.'];

const EVENT_BATCH_SIZE = 5000;
let eventBatch = [];

// Spread 100,000 events over the past 90 days
const ninetyDaysAgoMs = now.getTime() - (90 * 24 * 60 * 60 * 1000);

for (let i = 1; i <= EVENTS; i++) {
  const customerId = (i % CUSTOMERS) + 1;
  const eventType = eventTypes[i % eventTypes.length];
  const eventTs = new Date(ninetyDaysAgoMs + Math.floor(Math.random() * (90 * 24 * 60 * 60 * 1000)));

  let details = {};

  if (eventType === 'LOGIN_SUCCESS') {
    details = {
      device: devices[i % devices.length],
      ip: ips[i % ips.length] + String((i % 250) + 1),
      app_version: '3.1.' + String(i % 5)
    };
  } else if (eventType === 'LOGIN_FAILED') {
    details = {
      ip: ips[i % ips.length] + String((i % 250) + 1),
      reason: (i % 2 === 0) ? 'INVALID_PASSWORD' : 'USER_LOCKED',
      attempt_count: (i % 3) + 1
    };
  } else if (eventType === 'TRANSFER_INITIATED') {
    details = {
      amount: ((i % 50) + 1) * 500,
      currency: 'NGN',
      channel: 'MOBILE_APP',
      reference: 'TXN-REF-' + String(1000000 + i)
    };
  } else if (eventType === 'PIN_CHANGED') {
    details = {
      channel: 'MOBILE_APP',
      auth_method: 'SMS_OTP',
      status: 'SUCCESS'
    };
  } else if (eventType === 'KYC_UPGRADED') {
    details = {
      previous_tier: 1,
      promoted_tier: 2,
      decision: 'AUTOMATED_CLEARANCE'
    };
  } else if (eventType === 'FRAUD_FLAG') {
    details = {
      risk_score: 75 + (i % 25),
      rule_triggered: 'RAPID_FIRE_TRANSFERS',
      action_taken: 'HOLD_FOR_REVIEW'
    };
  }

  eventBatch.push({
    customer_id: customerId,
    event_type: eventType,
    ts: eventTs,
    details: details
  });

  if (eventBatch.length === EVENT_BATCH_SIZE || i === EVENTS) {
    nosql.audit_events.insertMany(eventBatch);
    eventBatch.length = 0;
  }
}

print('-> audit_events insertion complete.');
print('');

// ---------------------------------------------------------------------
// 3. Final Count Verification
// ---------------------------------------------------------------------
print('====================================================');
print('kyc_profiles inserted: ' + nosql.kyc_profiles.countDocuments({}));
print('audit_events inserted: ' + nosql.audit_events.countDocuments({}));
print('====================================================');
