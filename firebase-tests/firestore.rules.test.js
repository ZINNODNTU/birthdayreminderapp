const {before, after, beforeEach, test} = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const {doc, getDoc, setDoc, updateDoc, deleteDoc} = require('firebase/firestore');

const projectId = 'demo-birthday-reminder-rules-test';
let testEnv;

function validProfile(uid) {
  return {
    uid,
    provider: 'google.com',
    createdAt: '2024-01-01T00:00:00.000Z',
    updatedAt: '2024-01-01T00:00:00.000Z',
    lastLoginAt: '2024-01-01T00:00:00.000Z',
    schemaVersion: 1,
  };
}

function validBirthday(uid, id) {
  return {
    id,
    name: 'Test User',
    calendarType: 'solar',
    solarBirthday: '2000-01-01T00:00:00.000Z',
    lunar: null,
    note: null,
    reminder: {
      enabled: false,
      daysBefore: 0,
      hour: 9,
      minute: 0,
      repeatAnnually: true,
    },
    createdAt: '2024-01-01T00:00:00.000Z',
    updatedAt: '2024-01-01T00:00:00.000Z',
    deletedAt: null,
    schemaVersion: 1,
  };
}

async function seedProfile(uid) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `users/${uid}`), validProfile(uid));
  });
}

async function seedBirthday(uid, id = 'one') {
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
    updateDoc(doc(db, 'users/alice'), {createdAt: '2099-01-01T00:00:00.000Z'}),
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
    setDoc(doc(db, 'users/alice/birthdays/b1'), validBirthday('alice', 'b1')),
  );
});

test('11. Google user can read own birthday', async () => {
  await seedBirthday('alice', 'b1');
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  await assertSucceeds(getDoc(doc(db, 'users/alice/birthdays/b1')));
});

test('12. Google user can update own birthday', async () => {
  await seedBirthday('alice', 'b1');
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  await assertSucceeds(updateDoc(doc(db, 'users/alice/birthdays/b1'), {name: 'Renamed'}));
});

test('13. Google user can delete own birthday', async () => {
  await seedBirthday('alice', 'b1');
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  await assertSucceeds(deleteDoc(doc(db, 'users/alice/birthdays/b1')));
});

test('14. cross-user birthday read denied', async () => {
  await seedBirthday('alice', 'b1');
  const db = testEnv
    .authenticatedContext('bob', {provider: 'google.com'})
    .firestore();
  await assertFails(getDoc(doc(db, 'users/alice/birthdays/b1')));
});

test('15. cross-user birthday write denied', async () => {
  const db = testEnv
    .authenticatedContext('bob', {provider: 'google.com'})
    .firestore();
  await assertFails(
    setDoc(doc(db, 'users/alice/birthdays/b1'), validBirthday('alice', 'b1')),
  );
  await assertFails(
    updateDoc(doc(db, 'users/alice/birthdays/b1'), {name: 'Hijack'}),
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
  const bad = {...validBirthday('alice', 'b1'), schemaVersion: 99};
  await assertFails(setDoc(doc(db, 'users/alice/birthdays/b1'), bad));
});

test('20. invalid reminder hour denied', async () => {
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  const bad = {
    ...validBirthday('alice', 'b1'),
    reminder: {
      ...validBirthday('alice', 'b1').reminder,
      hour: 24,
    },
  };
  await assertFails(setDoc(doc(db, 'users/alice/birthdays/b1'), bad));
});

test('21. invalid reminder minute denied', async () => {
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  const bad = {
    ...validBirthday('alice', 'b1'),
    reminder: {
      ...validBirthday('alice', 'b1').reminder,
      minute: 60,
    },
  };
  await assertFails(setDoc(doc(db, 'users/alice/birthdays/b1'), bad));
});

test('22. malformed birthday (missing name) denied', async () => {
  const db = testEnv
    .authenticatedContext('alice', {provider: 'google.com'})
    .firestore();
  const bad = validBirthday('alice', 'b1');
  delete bad.name;
  await assertFails(setDoc(doc(db, 'users/alice/birthdays/b1'), bad));
});
