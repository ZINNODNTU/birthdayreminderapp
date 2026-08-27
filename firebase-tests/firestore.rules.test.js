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

function validBirthday(ownerId, id, schemaVersion = 2) {
  return {
    id,
    ownerId,
    name: 'Test User',
    schemaVersion,
    solarBirthday: '2000-01-01T00:00:00.000',
  };
}

async function seedBirthday(ownerId, id = 'one') {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(context.firestore(), `users/${ownerId}/birthdays/${id}`),
      validBirthday(ownerId, id),
    );
  });
}

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => testEnv.cleanup());
beforeEach(async () => testEnv.clearFirestore());

test('unauthenticated users cannot read or write birthdays', async () => {
  await seedBirthday('a');
  const db = testEnv.unauthenticatedContext().firestore();
  const ref = doc(db, 'users/a/birthdays/one');

  await assertFails(getDoc(ref));
  await assertFails(setDoc(ref, validBirthday('a', 'one')));
  await assertFails(updateDoc(ref, {name: 'Blocked'}));
  await assertFails(deleteDoc(ref));
});

test('user can create, read, update, and delete own birthday', async () => {
  const db = testEnv.authenticatedContext('a').firestore();
  const ref = doc(db, 'users/a/birthdays/one');

  await assertSucceeds(setDoc(ref, validBirthday('a', 'one')));
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(updateDoc(ref, {name: 'Updated'}));
  await assertSucceeds(deleteDoc(ref));
});

test('user cannot access another user birthday', async () => {
  await seedBirthday('b');
  const db = testEnv.authenticatedContext('a').firestore();
  const existing = doc(db, 'users/b/birthdays/one');
  const newBirthday = doc(db, 'users/b/birthdays/two');

  await assertFails(getDoc(existing));
  await assertFails(setDoc(newBirthday, validBirthday('b', 'two')));
  await assertFails(updateDoc(existing, {name: 'Blocked'}));
  await assertFails(deleteDoc(existing));
});

test('ownerId and document id must match authenticated path', async () => {
  const db = testEnv.authenticatedContext('a').firestore();

  await assertFails(
    setDoc(doc(db, 'users/a/birthdays/one'), validBirthday('b', 'one')),
  );
  await assertFails(
    setDoc(doc(db, 'users/a/birthdays/one'), validBirthday('a', 'wrong')),
  );
});

test('schemaVersion 1 is still accepted (backward compat)', async () => {
  const db = testEnv.authenticatedContext('a').firestore();
  const ref = doc(db, 'users/a/birthdays/legacy');

  await assertSucceeds(setDoc(ref, validBirthday('a', 'legacy', 1)));
});

test('legacy birthdays path is denied', async () => {
  const db = testEnv.authenticatedContext('a').firestore();
  const ref = doc(db, 'birthdays/one');

  await assertFails(getDoc(ref));
  await assertFails(setDoc(ref, validBirthday('a', 'one')));
});

test('unknown paths are denied', async () => {
  const db = testEnv.authenticatedContext('a').firestore();
  const ref = doc(db, 'unknown/one');

  await assertFails(getDoc(ref));
  await assertFails(setDoc(ref, {ownerId: 'a'}));
});
