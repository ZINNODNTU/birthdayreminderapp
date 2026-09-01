const {before, after, beforeEach, test} = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  Timestamp,
} = require('firebase/firestore');

const birthdayId = '550e8400-e29b-41d4-a716-446655440000';

const projectId = 'demo-birthday-reminder-rules-test';
let testEnv;

function validProfile(uid) {
  const timestamp = Timestamp.fromDate(new Date('2024-01-01T00:00:00.000Z'));
  return {
    uid,
    provider: 'google.com',
    displayName: 'Alice',
    email: 'alice@example.com',
    photoUrl: null,
    createdAt: timestamp,
    updatedAt: timestamp,
    lastLoginAt: timestamp,
    schemaVersion: 2,
  };
}

function validBirthday(uid, id) {
  const timestamp = Timestamp.fromDate(new Date('2024-01-01T00:00:00.000Z'));
  return {
    id,
    name: 'Test User',
    birthdayDate: Timestamp.fromDate(new Date('2000-01-01T00:00:00.000Z')),
    calendarType: 'solar',
    relationship: 'Bạn bè',
    gender: 'female',
    note: null,
    remindBeforeDays: 0,
    reminderEnabled: true,
    reminderTime: '09:00',
    repeatYearly: true,
    createdAt: timestamp,
    updatedAt: timestamp,
    schemaVersion: 2,
  };
}

async function seedProfile(uid) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `users/${uid}`), validProfile(uid));
  });
}

async function seedBirthday(uid, id = birthdayId) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), `users/${uid}/birthdays/${id}`),
      validBirthday(uid, id),
    );
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(
        path.join(__dirname, '..', 'firestore.rules'),
        'utf8',
      ),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => testEnv.cleanup());
beforeEach(async () => testEnv.clearFirestore());

// ===========================================================================
// USER PROFILE
// ===========================================================================

test('1. unauthenticated cannot read /users/{uid}', async () => {
  await seedProfile('alice');
  const db = testEnv.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(db, 'users/alice')));
});

test('2. unauthenticated cannot write /users/{uid}', async () => {
  const db = testEnv.unauthenticatedContext().firestore();
  await assertFails(setDoc(doc(db, 'users/alice'), validProfile('alice')));
});

test('3. Google user can create own profile', async () => {
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  await assertSucceeds(setDoc(doc(db, 'users/alice'), validProfile('alice')));
});

test('4. Google user can read own profile', async () => {
  await seedProfile('alice');
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  await assertSucceeds(getDoc(doc(db, 'users/alice')));
});

test('5. Google user can update own profile lastLoginAt', async () => {
  await seedProfile('alice');
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  await assertSucceeds(
    updateDoc(doc(db, 'users/alice'), {lastLoginAt: '2025-01-01T00:00:00.000Z'}),
  );
});

test('6. cross-user profile read denied', async () => {
  await seedProfile('alice');
  const db = testEnv
    .authenticatedContext('bob', {provider: 'google.com'})
    .firestore();
  await assertFails(getDoc(doc(db, 'users/alice')));
});

test('7. wrong profile uid in document body denied', async () => {
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  // uid in document doesn't match path
  await assertFails(setDoc(doc(db, 'users/alice'), validProfile('mallory')));
});

test('8. non-google provider denied', async () => {
  const db = testEnv
    .authenticatedContext('alice', {provider: 'password'})
    .firestore();
  await assertFails(setDoc(doc(db, 'users/alice'), validProfile('alice')));
});

test('9. createdAt mutation denied', async () => {
  await seedProfile('alice');
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  await assertFails(
    updateDoc(doc(db, 'users/alice'), {
      createdAt: Timestamp.fromDate(new Date('2099-01-01T00:00:00.000Z')),
    }),
  );
});

// ===========================================================================
// BIRTHDAYS
// ===========================================================================

test('10. Google user can create birthday under own UID', async () => {
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  await assertSucceeds(
    setDoc(doc(db, `users/alice/birthdays/${birthdayId}`), validBirthday('alice', birthdayId)),
  );
});

test('11. Google user can read own birthday', async () => {
  await seedBirthday('alice', birthdayId);
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  await assertSucceeds(getDoc(doc(db, `users/alice/birthdays/${birthdayId}`)));
});

test('12. Google user can update own birthday', async () => {
  await seedBirthday('alice', birthdayId);
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  await assertSucceeds(updateDoc(doc(db, `users/alice/birthdays/${birthdayId}`), {name: 'Renamed'}));
});

test('13. Google user can delete own birthday', async () => {
  await seedBirthday('alice', birthdayId);
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  await assertSucceeds(deleteDoc(doc(db, `users/alice/birthdays/${birthdayId}`)));
});

test('14. cross-user birthday read denied', async () => {
  await seedBirthday('alice', birthdayId);
  const db = testEnv
    .authenticatedContext('bob', {provider: 'google.com'})
    .firestore();
  await assertFails(getDoc(doc(db, `users/alice/birthdays/${birthdayId}`)));
});

test('15. cross-user birthday write denied', async () => {
  const db = testEnv
    .authenticatedContext('bob', {provider: 'google.com'})
    .firestore();
  await assertFails(
    setDoc(doc(db, `users/alice/birthdays/${birthdayId}`), validBirthday('alice', birthdayId)),
  );
  await assertFails(
    updateDoc(doc(db, `users/alice/birthdays/${birthdayId}`), {name: 'Hijack'}),
  );
});

// ===========================================================================
// LEGACY PATH
// ===========================================================================

test('16. legacy /birthdays read denied', async () => {
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  await assertFails(getDoc(doc(db, 'birthdays/one')));
});

test('17. legacy /birthdays write denied', async () => {
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  await assertFails(setDoc(doc(db, 'birthdays/one'), validBirthday('alice', 'one')));
});

// ===========================================================================
// VALIDATION
// ===========================================================================

test('18. document id mismatch denied', async () => {
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  // body.id is "wrong" while path id is "one"
  await assertFails(
    setDoc(doc(db, 'users/alice/birthdays/one'), validBirthday('alice', 'wrong')),
  );
});

test('19. invalid schemaVersion denied', async () => {
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  const bad = {...validBirthday('alice', birthdayId), schemaVersion: 99};
  await assertFails(setDoc(doc(db, `users/alice/birthdays/${birthdayId}`), bad));
});

test('20. invalid reminder hour denied', async () => {
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  const bad = {...validBirthday('alice', birthdayId), reminderTime: '24:00'};
  await assertFails(
    setDoc(doc(db, `users/alice/birthdays/${birthdayId}`), bad),
  );
});

test('21. invalid reminder minute denied', async () => {
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  const bad = {...validBirthday('alice', birthdayId), reminderTime: '09:60'};
  await assertFails(
    setDoc(doc(db, `users/alice/birthdays/${birthdayId}`), bad),
  );
});

test('22. malformed birthday (missing name) denied', async () => {
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  const bad = validBirthday('alice', birthdayId);
  delete bad.name;
  await assertFails(setDoc(doc(db, `users/alice/birthdays/${birthdayId}`), bad));
});


