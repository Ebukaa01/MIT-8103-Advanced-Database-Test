// =====================================================================
// Portfolio 4 - Step 1: create the collections with schema validation.
// Usage: mongosh "$MONGODB_URI" --file portfolio-4-nosql/01_schema_validation.js
// =====================================================================

const nosql = db.getSiblingDB('equitypay_nosql');

// Drop existing collections to ensure a clean slate
['kyc_profiles', 'audit_events', 'login_sessions'].forEach(function (name) {
  nosql.getCollection(name).drop();
});

// kyc_profiles: one document per customer.
nosql.createCollection('kyc_profiles', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['customer_id', 'tier', 'status', 'documents', 'created_at'],
      properties: {
        customer_id: { 
          bsonType: 'number', 
          minimum: 1, 
          description: 'must match customers.customer_id in PostgreSQL' 
        },
        tier: { 
          bsonType: 'number', 
          minimum: 1, 
          maximum: 3 
        },
        status: { 
          enum: ['PENDING', 'VERIFIED', 'REJECTED'] 
        },
        documents: {
          bsonType: 'array',
          minItems: 1,
          items: {
            bsonType: 'object',
            required: ['type', 'number'],
            properties: {
              type: { 
                enum: ['BVN', 'NIN', 'PASSPORT', 'DRIVERS_LICENCE', 'UTILITY_BILL'] 
              },
              number: { 
                bsonType: 'string' 
              }
            }
          }
        },
        created_at: { 
          bsonType: 'date' 
        }
      }
    }
  },
  validationAction: 'error'
});

// audit_events: an append-only log of system activity.
nosql.createCollection('audit_events', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['customer_id', 'event_type', 'ts', 'details'],
      properties: {
        customer_id: { 
          bsonType: 'number', 
          minimum: 1 
        },
        event_type: { 
          enum: [
            'LOGIN_SUCCESS', 
            'LOGIN_FAILED', 
            'PIN_CHANGED', 
            'TRANSFER_INITIATED', 
            'KYC_UPGRADED', 
            'FRAUD_FLAG'
          ] 
        },
        ts: { 
          bsonType: 'date' 
        },
        details: { 
          bsonType: 'object' 
        }
      }
    }
  },
  validationAction: 'error'
});

// login_sessions: short-lived session data (TTL index applied in next step).
nosql.createCollection('login_sessions');

print('Collections now in equitypay_nosql:');
nosql.getCollectionNames().forEach(function (n) { 
  print('- ' + n); 
});

// Negative Test: Attempt inserting invalid document to test schema validator
try {
  nosql.kyc_profiles.insertOne({ customer_id: 1, status: 'MAYBE' });
  print('FAIL: the invalid document was accepted');
} catch (e) {
  print('PASS: invalid KYC document rejected -> ' + e.codeName + ' (code ' + e.code + ')');
}
