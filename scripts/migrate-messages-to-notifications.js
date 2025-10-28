// Script to migrate data from 'messages' collection to 'notifications' collection
// Run this in Firebase Console > Firestore > Data tab > Click "..." > Run Query

const admin = require('firebase-admin');
const serviceAccount = require('./path-to-your-service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function migrateMessagesToNotifications() {
  try {
    console.log('Starting migration from messages to notifications...');
    
    // Get all documents from messages collection
    const messagesSnapshot = await db.collection('messages').get();
    
    if (messagesSnapshot.empty) {
      console.log('No messages found to migrate.');
      return;
    }
    
    console.log(`Found ${messagesSnapshot.size} messages to migrate.`);
    
    let successCount = 0;
    let errorCount = 0;
    
    // Copy each message to notifications collection
    for (const doc of messagesSnapshot.docs) {
      try {
        const data = doc.data();
        
        // Add to notifications collection
        await db.collection('notifications').add(data);
        
        successCount++;
        console.log(`✓ Migrated message ${doc.id}`);
      } catch (error) {
        errorCount++;
        console.error(`✗ Error migrating message ${doc.id}:`, error);
      }
    }
    
    console.log('\n=== Migration Summary ===');
    console.log(`Total messages: ${messagesSnapshot.size}`);
    console.log(`Successfully migrated: ${successCount}`);
    console.log(`Errors: ${errorCount}`);
    console.log('\nNote: Original messages collection was not deleted.');
    console.log('You can manually delete it after verifying the migration.');
    
  } catch (error) {
    console.error('Migration failed:', error);
  }
}

// Run the migration
migrateMessagesToNotifications()
  .then(() => {
    console.log('\nMigration complete!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('Migration failed:', error);
    process.exit(1);
  });
