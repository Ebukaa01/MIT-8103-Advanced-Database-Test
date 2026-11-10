// =====================================================================
// Portfolio 5: Distributed & Cloud Database Architectures
// 04_atlas_cloud_check.js: MongoDB Atlas Cloud Infrastructure Audit
// Case Study: EquityPay Financial Services Ltd.
//
// Usage:
//   mongosh "$ATLAS_URI" --file portfolio-5-distributed-cloud/04_atlas_cloud_check.js | tee portfolio-5-distributed-cloud/output/04_atlas_cloud_check.txt
// =====================================================================

print('\n=====================================================================');
print('EQUITYPAY DISTRIBUTED ARCHITECTURE: MONGODB ATLAS CLOUD AUDIT');
print('Case Study: EquityPay Financial Services Ltd. (NoSQL Cloud Perimeter)');
print('=====================================================================\n');

// 1. Connection & Engine Identification
const pingResult = db.runCommand({ ping: 1 });
print('1. CLOUD CONNECTION & ENGINE STATUS');
print('--------------------------------------------------');
print('Ping Status       : ' + (pingResult.ok === 1 ? 'ONLINE (Success)' : 'FAILED'));
print('Database Name     : ' + db.getName());
print('MongoDB Version   : ' + db.version());

// 2. Topology & Replica Set Configuration
print('\n2. ATLAS CLUSTER REPLICA SET TOPOLOGY');
print('--------------------------------------------------');

try {
    const hello = db.runCommand({ hello: 1 });
    print('Replica Set Name  : ' + (hello.setName || 'Standalone / Sharded Proxy'));
    print('Current Node Role : ' + (hello.isWritablePrimary ? 'PRIMARY (Writable Master)' : (hello.secondary ? 'SECONDARY (Read Replica)' : 'ARBITER / OTHER')));
    print('Active Primary    : ' + (hello.primary || 'N/A'));
    print('Connected Host    : ' + hello.me);
    print('Topology Members  :');
    if (hello.hosts && hello.hosts.length > 0) {
        hello.hosts.forEach((h, idx) => {
            const role = (h === hello.primary) ? '[PRIMARY]' : '[SECONDARY]';
            print('  Node ' + (idx + 1) + ': ' + h + ' ' + role);
        });
    } else {
        print('  (Managed Atlas proxy cluster)');
    }
    print('Read Only Mode    : ' + (hello.readOnly ? 'true' : 'false'));
    print('Max Wire Version  : ' + hello.maxWireVersion);
} catch (e) {
    print('Hello command error: ' + e.message);
}

// 3. Database Storage & Footprint
print('\n3. CLOUD DATABASE STORAGE STATISTICS');
print('--------------------------------------------------');
try {
    const stats = db.stats();
    print('Collections Count : ' + stats.collections);
    print('Total Documents   : ' + stats.objects);
    print('Data Size         : ' + (stats.dataSize / 1024 / 1024).toFixed(3) + ' MB');
    print('Storage Allocated : ' + (stats.storageSize / 1024 / 1024).toFixed(3) + ' MB');
    print('Total Indexes     : ' + stats.indexes);
    print('Total Index Size  : ' + (stats.indexSize / 1024 / 1024).toFixed(3) + ' MB');
} catch (e) {
    print('Stats error: ' + e.message);
}

// 4. Collection Inventory & Document Audits
print('\n4. PERIMETER DATASET INVENTORY');
print('--------------------------------------------------');
const targetCollections = ['kyc_profiles', 'audit_events', 'login_sessions'];

targetCollections.forEach(colName => {
    try {
        const col = db.getCollection(colName);
        const count = col.estimatedDocumentCount();
        const indexes = col.getIndexes().map(idx => idx.name).join(', ');
        print('Collection: ' + colName);
        print('  Document Count : ' + count);
        print('  Indexes        : ' + indexes);
    } catch (err) {
        print('Collection: ' + colName + ' (Not Found / Uninitialized)');
    }
});

// 5. Distributed Majority Write Concern Verification
print('\n5. DISTRIBUTED WRITE CONCERN & ACKNOWLEDGMENT TEST');
print('--------------------------------------------------');
try {
    const testDoc = {
        customer_id: 1,
        event_type: 'LOGIN_SUCCESS',
        ts: new Date(),
        details: {
            service: 'EquityPay-Distributed-Cloud-Auditor',
            cloud_provider: 'MongoDB Atlas Managed Cloud',
            replication_consensus: 'w:majority'
        }
    };

    const insertResult = db.getCollection('audit_events').insertOne(testDoc, {
        writeConcern: { w: 'majority', wtimeout: 5000 }
    });

    if (insertResult.acknowledged) {
        print('Write Acknowledged : SUCCESS');
        print('Inserted Heartbeat ID: ' + insertResult.insertedId);
        print('Write Concern Model: w: "majority" (Validated across quorum)');
    } else {
        print('Write Acknowledged : FAILED (Timeout or Quorum Not Reached)');
    }
} catch (e) {
    print('Majority write test note: ' + e.message);
}

print('\n=====================================================================');
print('ATLAS CLOUD INFRASTRUCTURE AUDIT COMPLETE');
print('=====================================================================\n');

